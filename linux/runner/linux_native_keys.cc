#include "linux_native_keys.h"

#include <glib/gstdio.h>

#include <algorithm>
#include <array>
#include <cerrno>
#include <csignal>
#include <cstdint>
#include <cstring>
#include <cstdio>
#include <stdexcept>
#include <string>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>
#include <vector>

namespace {
constexpr char kDevicePrefix[] = "gorape-linux-";
constexpr char kDpopPrefix[] = "gfapp_dpop_";
constexpr char kAlphabet[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
constexpr std::array<uint8_t, 26> kSpkiPrefix = {
    0x30,0x59,0x30,0x13,0x06,0x07,0x2A,0x86,0x48,0xCE,0x3D,0x02,0x01,
    0x06,0x08,0x2A,0x86,0x48,0xCE,0x3D,0x03,0x01,0x07,0x03,0x42,0x00};

struct NativeContext { bool dpop; };

// GF-01481 — Locate an approved root-owned TPM2 executable in trusted directories.
std::string FindTrustedTpmTool(const std::string& executable) {
  static const char* directories[] = {"/usr/bin", "/usr/sbin", "/usr/local/bin", "/bin", "/sbin"};
  for (const char* directory : directories) {
    gchar* candidate = g_build_filename(directory, executable.c_str(), nullptr);
    struct stat metadata {};
    const bool trusted = stat(candidate, &metadata) == 0 && S_ISREG(metadata.st_mode) &&
        metadata.st_uid == 0 && (metadata.st_mode & (S_IWGRP | S_IWOTH)) == 0 &&
        access(candidate, X_OK) == 0;
    if (trusted) {
      const std::string result(candidate);
      g_free(candidate);
      return result;
    }
    g_free(candidate);
  }
  throw std::runtime_error("A root-owned TPM2 tool is unavailable");
}

// GF-01482 — RFC 4648 §5: encode bytes as unpadded Base64url.
std::string EncodeBase64Url(const uint8_t* bytes, size_t length) {
  std::string result;
  uint32_t accumulator = 0;
  int bits = -6;
  for (size_t index = 0; index < length; ++index) {
    accumulator = (accumulator << 8) | bytes[index];
    bits += 8;
    while (bits >= 0) {
      result.push_back(kAlphabet[(accumulator >> bits) & 0x3f]);
      bits -= 6;
    }
  }
  if (bits > -6) result.push_back(kAlphabet[((accumulator << 8) >> (bits + 8)) & 0x3f]);
  return result;
}

// GF-01483 — RFC 4648 §5: decode unpadded Base64url bytes.
std::vector<uint8_t> DecodeBase64Url(const std::string& text) {
  std::vector<uint8_t> result;
  uint32_t accumulator = 0;
  int bits = -8;
  for (char character : text) {
    const char* location = strchr(kAlphabet, character);
    if (location == nullptr || character == '\0') throw std::runtime_error("invalid base64url");
    accumulator = (accumulator << 6) | static_cast<uint32_t>(location - kAlphabet);
    bits += 6;
    if (bits >= 0) {
      result.push_back(static_cast<uint8_t>((accumulator >> bits) & 0xff));
      bits -= 8;
    }
  }
  if (result.empty()) throw std::runtime_error("empty base64url");
  return result;
}

// GF-01484 — Read a required non-empty string from a Flutter method map.
std::string Argument(FlValue* arguments, const char* name) {
  if (arguments == nullptr || fl_value_get_type(arguments) != FL_VALUE_TYPE_MAP) {
    throw std::runtime_error("missing method arguments");
  }
  FlValue* value = fl_value_lookup_string(arguments, name);
  if (value == nullptr || fl_value_get_type(value) != FL_VALUE_TYPE_STRING) {
    throw std::runtime_error("invalid method argument");
  }
  const char* text = fl_value_get_string(value);
  if (text == nullptr || text[0] == '\0') throw std::runtime_error("empty method argument");
  return text;
}

// GF-01485 — Validate a key identifier against its namespace and allowed characters.
void ValidateIdentifier(const std::string& identifier, bool dpop) {
  const std::string prefix = dpop ? kDpopPrefix : kDevicePrefix;
  if (identifier.size() > 128 || identifier.rfind(prefix, 0) != 0) {
    throw std::runtime_error("invalid native key namespace");
  }
  for (char character : identifier) {
    if (!((character >= 'a' && character <= 'z') ||
          (character >= 'A' && character <= 'Z') ||
          (character >= '0' && character <= '9') || character == '-' || character == '_')) {
      throw std::runtime_error("invalid native key identifier");
    }
  }
}

// GF-01486 — Create and secure the per-user TPM2 key-blob directory.
std::string KeyDirectory() {
  gchar* path = g_build_filename(g_get_user_data_dir(), "gf_app", "tpm2_keys", nullptr);
  const std::string result(path);
  g_free(path);
  if (g_mkdir_with_parents(result.c_str(), 0700) != 0 || g_chmod(result.c_str(), 0700) != 0) {
    throw std::runtime_error("TPM2 key directory is unavailable");
  }
  return result;
}

// GF-01487 — Derive a non-reversible file path for one TPM2 key blob.
std::string KeyBlobPath(const std::string& identifier, const char* suffix) {
  gchar* digest = g_compute_checksum_for_string(G_CHECKSUM_SHA256, identifier.c_str(), -1);
  const std::string filename = std::string(digest) + suffix;
  g_free(digest);
  gchar* path = g_build_filename(KeyDirectory().c_str(), filename.c_str(), nullptr);
  const std::string result(path);
  g_free(path);
  return result;
}

// GF-01488 — Remove the public and private TPM2 blobs for a key identifier.
void RemoveKeyBlobs(const std::string& identifier) {
  g_remove(KeyBlobPath(identifier, ".pub").c_str());
  g_remove(KeyBlobPath(identifier, ".priv").c_str());
}

// GF-01489 — Run a trusted TPM2 tool with a fixed device TCTI and time limit.
void Run(const std::vector<std::string>& arguments) {
  if (arguments.empty()) throw std::runtime_error("empty TPM2 command");
  std::vector<std::string> safe_arguments = arguments;
  safe_arguments[0] = FindTrustedTpmTool(arguments[0]);
  std::vector<gchar*> argv;
  argv.reserve(safe_arguments.size() + 1);
  for (const auto& value : safe_arguments) argv.push_back(const_cast<gchar*>(value.c_str()));
  argv.push_back(nullptr);
  gchar** environment = g_get_environ();
  environment = g_environ_setenv(environment, "TPM2TOOLS_TCTI",
                                "device:/dev/tpmrm0", TRUE);
  environment = g_environ_setenv(environment, "TSS2_TCTI",
                                "device:/dev/tpmrm0", TRUE);
  GError* error = nullptr;
  GPid child = 0;
  const gboolean started = g_spawn_async(nullptr, argv.data(), nullptr,
      static_cast<GSpawnFlags>(G_SPAWN_DO_NOT_REAP_CHILD |
                               G_SPAWN_STDOUT_TO_DEV_NULL | G_SPAWN_STDERR_TO_DEV_NULL),
      nullptr, environment, &child, &error);
  g_strfreev(environment);
  if (error != nullptr) g_error_free(error);
  if (!started) {
    throw std::runtime_error("TPM2 operation failed or tpm2-tools is unavailable");
  }
  const gint64 deadline = g_get_monotonic_time() + 10 * G_USEC_PER_SEC;
  gint status = 0;
  while (g_get_monotonic_time() < deadline) {
    const pid_t waited = waitpid(child, &status, WNOHANG);
    if (waited == child) {
      g_spawn_close_pid(child);
      if (WIFEXITED(status) && WEXITSTATUS(status) == 0) return;
      throw std::runtime_error("TPM2 operation failed or tpm2-tools is unavailable");
    }
    if (waited < 0 && errno != EINTR) {
      g_spawn_close_pid(child);
      throw std::runtime_error("TPM2 operation status could not be collected");
    }
    g_usleep(10 * 1000);
  }
  kill(child, SIGKILL);
  while (waitpid(child, &status, 0) < 0 && errno == EINTR) {}
  g_spawn_close_pid(child);
  throw std::runtime_error("TPM2 operation exceeded the 10-second limit");
}

// GF-01490 — Probe whether the required TPM2 command-line tools are usable.
bool HasTpmTools() {
  try {
    Run({"tpm2_getcap", "properties-fixed"});
    return true;
  } catch (...) {
    return false;
  }
}

// GF-01491 — Create a private temporary workspace for a TPM2 operation.
std::string CreateTempDirectory() {
  GError* error = nullptr;
  gchar* path = g_dir_make_tmp("gf-app-tpm2-XXXXXX", &error);
  if (path == nullptr) {
    if (error != nullptr) g_error_free(error);
    throw std::runtime_error("TPM2 temporary workspace is unavailable");
  }
  const std::string result(path);
  g_free(path);
  if (g_chmod(result.c_str(), 0700) != 0) throw std::runtime_error("TPM2 temporary workspace permissions failed");
  return result;
}

// GF-01492 — Remove known temporary TPM2 operation files and their directory.
void RemoveTempDirectory(const std::string& directory) {
  static const char* files[] = {"primary.ctx", "key.pub", "key.priv", "key.ctx",
                                "creation.data", "creation.hash", "creation.ticket",
                                "public.pem", "input.bin", "signature.der"};
  for (const char* file : files) {
    gchar* path = g_build_filename(directory.c_str(), file, nullptr);
    g_remove(path);
    g_free(path);
  }
  g_rmdir(directory.c_str());
}

// GF-01493 — Read a bounded non-empty text file produced by TPM2 tools.
std::string ReadTextFile(const std::string& path) {
  gchar* contents = nullptr;
  gsize length = 0;
  if (!g_file_get_contents(path.c_str(), &contents, &length, nullptr) || contents == nullptr || length == 0 || length > 64 * 1024) {
    if (contents != nullptr) g_free(contents);
    throw std::runtime_error("TPM2 output file is unavailable");
  }
  std::string result(contents, length);
  g_free(contents);
  return result;
}

// GF-01494 — Read a bounded non-empty TPM2 public or private blob.
std::vector<uint8_t> ReadBlob(const std::string& path) {
  gchar* contents = nullptr;
  gsize length = 0;
  if (!g_file_get_contents(path.c_str(), &contents, &length, nullptr) || contents == nullptr || length == 0 || length > 64 * 1024) {
    if (contents != nullptr) g_free(contents);
    throw std::runtime_error("TPM2 protected key blob is unavailable");
  }
  std::vector<uint8_t> result(reinterpret_cast<uint8_t*>(contents),
                              reinterpret_cast<uint8_t*>(contents) + length);
  g_free(contents);
  return result;
}

// GF-01495 — Persist a TPM2 key blob with owner-only file permissions.
void WriteBlob(const std::string& path, const std::vector<uint8_t>& value) {
  if (value.empty() || value.size() > 64 * 1024 ||
      !g_file_set_contents(path.c_str(), reinterpret_cast<const gchar*>(value.data()), value.size(), nullptr) ||
      g_chmod(path.c_str(), 0600) != 0) {
    throw std::runtime_error("TPM2 protected key blob could not be stored");
  }
}

// GF-01496 — Decode and validate a P-256 SubjectPublicKeyInfo PEM value.
std::vector<uint8_t> DecodePublicPem(const std::string& pem) {
  const std::string begin = "-----BEGIN PUBLIC KEY-----";
  const std::string end = "-----END PUBLIC KEY-----";
  const size_t start = pem.find(begin);
  const size_t finish = pem.find(end);
  if (start == std::string::npos || finish == std::string::npos || finish <= start) {
    throw std::runtime_error("TPM2 public key is not a PEM SubjectPublicKeyInfo");
  }
  std::string encoded;
  for (size_t i = start + begin.size(); i < finish; ++i) {
    if (g_ascii_isalnum(pem[i]) || pem[i] == '+' || pem[i] == '/' || pem[i] == '=') encoded.push_back(pem[i]);
  }
  gsize decoded_length = 0;
  guchar* decoded = g_base64_decode(encoded.c_str(), &decoded_length);
  if (decoded == nullptr || decoded_length != kSpkiPrefix.size() + 65) {
    if (decoded != nullptr) g_free(decoded);
    throw std::runtime_error("TPM2 public key has an unexpected size");
  }
  std::vector<uint8_t> der(decoded, decoded + decoded_length);
  g_free(decoded);
  if (!std::equal(kSpkiPrefix.begin(), kSpkiPrefix.end(), der.begin()) || der[kSpkiPrefix.size()] != 0x04) {
    throw std::runtime_error("TPM2 public key is not P-256");
  }
  return std::vector<uint8_t>(der.begin() + kSpkiPrefix.size(), der.end());
}

// GF-01497 — Reload TPM-wrapped blobs and recover the corresponding public point.
std::vector<uint8_t> LoadPublicPoint(const std::string& identifier, bool dpop,
                                     const std::string& directory) {
  ValidateIdentifier(identifier, dpop);
  const auto public_blob = ReadBlob(KeyBlobPath(identifier, ".pub"));
  const auto private_blob = ReadBlob(KeyBlobPath(identifier, ".priv"));
  const std::string public_path = directory + "/key.pub";
  const std::string private_path = directory + "/key.priv";
  WriteBlob(public_path, public_blob);
  WriteBlob(private_path, private_blob);
  Run({"tpm2_createprimary", "-Q", "-C", "o", "-g", "sha256", "-G", "ecc", "-c", directory + "/primary.ctx"});
  Run({"tpm2_load", "-Q", "-C", directory + "/primary.ctx", "-u", public_path,
       "-r", private_path, "-c", directory + "/key.ctx"});
  const std::string pem_path = directory + "/public.pem";
  Run({"tpm2_readpublic", "-Q", "-c", directory + "/key.ctx", "-f", "pem", "-o", pem_path});
  return DecodePublicPem(ReadTextFile(pem_path));
}

// GF-01498 — Describe local TPM protection without claiming remote attestation.
FlValue* Evidence() {
  FlValue* evidence = fl_value_new_map();
  fl_value_set_string_take(evidence, "format", fl_value_new_string("linux-tpm2-local"));
  fl_value_set_string_take(evidence, "remote_attestation", fl_value_new_bool(FALSE));
  fl_value_set_string_take(evidence, "challenge_bound", fl_value_new_bool(FALSE));
  fl_value_set_string_take(evidence, "physical_tpm_verified", fl_value_new_bool(FALSE));
  fl_value_set_string_take(evidence, "note", fl_value_new_string("TPM2 protected key; physical TPM provenance and server-verifiable key attestation are not established."));
  return evidence;
}

// GF-01499 — Load public TPM key material and serialize the Flutter response.
FlValue* KeyMaterial(const std::string& identifier, bool dpop) {
  const std::string directory = CreateTempDirectory();
  try {
    const auto point = LoadPublicPoint(identifier, dpop, directory);
    const std::string pem_path = directory + "/public.pem";
    const std::string pem = ReadTextFile(pem_path);
    FlValue* result = fl_value_new_map();
    fl_value_set_string_take(result, "keyIdentifier", fl_value_new_string(identifier.c_str()));
    fl_value_set_string_take(result, "publicKeyPem", fl_value_new_string(pem.c_str()));
    fl_value_set_string_take(result, "securityLevel", fl_value_new_string("linux_tpm2_local"));
    fl_value_set_string_take(result, "algorithm", fl_value_new_string("ES256"));
    FlValue* jwk = fl_value_new_map();
    fl_value_set_string_take(jwk, "kty", fl_value_new_string("EC"));
    fl_value_set_string_take(jwk, "crv", fl_value_new_string("P-256"));
    fl_value_set_string_take(jwk, "x", fl_value_new_string(Base64Url(point.data() + 1, 32).c_str()));
    fl_value_set_string_take(jwk, "y", fl_value_new_string(Base64Url(point.data() + 33, 32).c_str()));
    fl_value_set_string_take(result, "publicJwk", jwk);
    fl_value_set_string_take(result, "certificateChain", fl_value_new_list());
    fl_value_set_string_take(result, "attestationEvidence", Evidence());
    RemoveTempDirectory(directory);
    return result;
  } catch (...) {
    RemoveTempDirectory(directory);
    throw;
  }
}

// GF-01500 — TCG TPM 2.0: create a challenge-bound P-256 key and store TPM-wrapped blobs.
// GF-02183 — Creates a TPM2 P-256 key with challenge in creation data and stores only TPM-wrapped blobs.
void CreateKey(const std::string& identifier, bool dpop, const std::vector<uint8_t>& challenge) {
  ValidateIdentifier(identifier, dpop);
  if (challenge.size() < 16 || challenge.size() > 64) throw std::runtime_error("TPM2 outsideInfo challenge must contain 16–64 bytes");
  const std::string public_destination = KeyBlobPath(identifier, ".pub");
  const std::string private_destination = KeyBlobPath(identifier, ".priv");
  if (g_file_test(public_destination.c_str(), G_FILE_TEST_EXISTS) ||
      g_file_test(private_destination.c_str(), G_FILE_TEST_EXISTS)) {
    throw std::runtime_error("TPM2 key identifier already exists");
  }
  const std::string directory = CreateTempDirectory();
  try {
    std::string challenge_hex;
    static constexpr char hex[] = "0123456789abcdef";
    for (uint8_t byte : challenge) { challenge_hex.push_back(hex[byte >> 4]); challenge_hex.push_back(hex[byte & 0x0f]); }
    Run({"tpm2_createprimary", "-Q", "-C", "o", "-g", "sha256", "-G", "ecc", "-c", directory + "/primary.ctx"});
    Run({"tpm2_create", "-Q", "-C", directory + "/primary.ctx", "-g", "sha256", "-G", "ecc",
         "-a", "fixedtpm|fixedparent|sensitivedataorigin|userwithauth|sign", "-q", challenge_hex,
         "-u", directory + "/key.pub", "-r", directory + "/key.priv",
         "--creation-data", directory + "/creation.data", "-d", directory + "/creation.hash", "-t", directory + "/creation.ticket"});
    const auto public_blob = ReadBlob(directory + "/key.pub");
    const auto private_blob = ReadBlob(directory + "/key.priv");
    try {
      WriteBlob(public_destination, public_blob);
      WriteBlob(private_destination, private_blob);
    } catch (...) {
      RemoveKeyBlobs(identifier);
      throw;
    }
    // TPM creation data includes the challenge, but without a trusted AK/EK
    // certificate this is intentionally not represented as remote attestation.
    RemoveTempDirectory(directory);
  } catch (...) {
    RemoveTempDirectory(directory);
    throw;
  }
}

// GF-01501 — TCG TPM 2.0: reload the protected key and sign without exporting private material.
// GF-02184 — Reloads the TPM-protected key blob and signs without exporting private key material.
std::string Sign(const std::string& identifier, bool dpop, const std::string& encoded) {
  const auto input = DecodeBase64Url(encoded);
  if (input.size() > 16 * 1024) throw std::runtime_error("TPM2 signing input exceeds limit");
  const std::string directory = CreateTempDirectory();
  try {
    const auto point = LoadPublicPoint(identifier, dpop, directory);
    (void)point;
    const std::string input_path = directory + "/input.bin";
    if (!g_file_set_contents(input_path.c_str(), reinterpret_cast<const gchar*>(input.data()), input.size(), nullptr) || g_chmod(input_path.c_str(), 0600) != 0) {
      throw std::runtime_error("TPM2 signing input could not be staged");
    }
    const std::string signature_path = directory + "/signature.der";
    Run({"tpm2_sign", "-Q", "-c", directory + "/key.ctx", "-g", "sha256", "-f", "der", "-o", signature_path, input_path});
    const std::string signature = ReadTextFile(signature_path);
    RemoveTempDirectory(directory);
    return Base64Url(reinterpret_cast<const uint8_t*>(signature.data()), signature.size());
  } catch (...) {
    RemoveTempDirectory(directory);
    throw;
  }
}

// GF-01502 — Create a random identifier in the legacy DPoP namespace.
std::string NewDpopIdentifier() {
  gchar* uuid = g_uuid_string_random();
  const std::string result = std::string(kDpopPrefix) + uuid;
  g_free(uuid);
  return result;
}

// GF-01503 — Route a Flutter method call to a TPM2 device-key operation.
FlValue* Dispatch(const gchar* method, FlValue* arguments, bool dpop) {
  if (!dpop && g_strcmp0(method, "availability") == 0) {
    const gboolean available = HasTpmTools();
    FlValue* result = fl_value_new_map();
    fl_value_set_string_take(result, "supported", fl_value_new_bool(available));
    fl_value_set_string_take(result, "hardwareBacked", fl_value_new_bool(FALSE));
    fl_value_set_string_take(result, "attestationSupported", fl_value_new_bool(FALSE));
    fl_value_set_string_take(result, "securityLevel", fl_value_new_string(available ? "linux_tpm2_local" : "unavailable"));
    fl_value_set_string_take(result, "reason", fl_value_new_string(available ? "TPM2 tools are available; physical TPM and AK/EK provenance are not verified." : "TPM2 device and tpm2-tools are required; no software key fallback is provided."));
    return result;
  }
  if ((!dpop && g_strcmp0(method, "generateKey") == 0) || (dpop && g_strcmp0(method, "createKey") == 0)) {
    const char* challenge_name = dpop ? "attestationChallenge" : "challenge";
    const auto challenge = DecodeBase64Url(Argument(arguments, challenge_name));
    const std::string identifier = dpop ? NewDpopIdentifier() : Argument(arguments, "keyIdentifier");
    CreateKey(identifier, dpop, challenge);
    try {
      return KeyMaterial(identifier, dpop);
    } catch (...) {
      RemoveKeyBlobs(identifier);
      throw;
    }
  }
  if ((dpop && g_strcmp0(method, "getKey") == 0) || (!dpop && g_strcmp0(method, "hasKey") == 0)) {
    const std::string identifier = Argument(arguments, "keyIdentifier");
    if (!dpop) {
      try { g_autoptr(FlValue) material = KeyMaterial(identifier, false); return fl_value_new_bool(TRUE); }
      catch (...) { return fl_value_new_bool(FALSE); }
    }
    return KeyMaterial(identifier, true);
  }
  if (g_strcmp0(method, "sign") == 0) {
    const std::string signature = Sign(Argument(arguments, "keyIdentifier"), dpop, Argument(arguments, "data"));
    return fl_value_new_string(signature.c_str());
  }
  if (g_strcmp0(method, "deleteKey") == 0) {
    const std::string identifier = Argument(arguments, "keyIdentifier");
    ValidateIdentifier(identifier, dpop);
    const std::string public_path = KeyBlobPath(identifier, ".pub");
    const std::string private_path = KeyBlobPath(identifier, ".priv");
    const gboolean existed = g_file_test(public_path.c_str(), G_FILE_TEST_EXISTS) ||
                             g_file_test(private_path.c_str(), G_FILE_TEST_EXISTS);
    RemoveKeyBlobs(identifier);
    if (!existed) throw std::runtime_error("TPM2 key does not exist");
    return fl_value_new_null();
  }
  throw std::runtime_error("unsupported TPM2 operation");
}

// GF-01504 — Execute a Flutter method call and return a typed channel result.
void MethodCallHandler(FlMethodChannel*, FlMethodCall* call, gpointer user_data) {
  auto* context = static_cast<NativeContext*>(user_data);
  try {
    g_autoptr(FlValue) result = Dispatch(fl_method_call_get_name(call), fl_method_call_get_args(call), context->dpop);
    fl_method_call_respond_success(call, result, nullptr);
  } catch (...) {
    g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(
        fl_method_error_response_new("native_key_error", "Linux TPM2 key operation failed.", nullptr));
    fl_method_call_respond(call, response, nullptr);
  }
}

// GF-01505 — Release the native method-channel callback context.
void DestroyContext(gpointer user_data) { delete static_cast<NativeContext*>(user_data); }

// GF-01506 — Create and configure a Flutter method channel for a key namespace.
FlMethodChannel* CreateChannel(FlBinaryMessenger* messenger, const char* name, bool dpop) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* channel = fl_method_channel_new(messenger, name, FL_METHOD_CODEC(codec));
  (void)KeyDirectory();
  auto* context = new NativeContext{dpop};
  fl_method_channel_set_method_call_handler(channel, MethodCallHandler, context, DestroyContext);
  return channel;
}
}  // namespace

// GF-01507 — Register the Linux device-key channel backed by TPM2 tools.
// GF-02185 — Installs the Linux Device key channel backed by TPM2 tools only.
void RegisterLinuxNativeKeyChannels(FlBinaryMessenger* messenger,
                                   FlMethodChannel** device_channel) {
  *device_channel = CreateChannel(messenger, "com.gorapeflutter.gf_app/device_key", false);
}
