#include "windows_native_keys.h"

#include <windows.h>
#include <bcrypt.h>
#include <ncrypt.h>

#include <array>
#include <algorithm>
#include <cstdint>
#include <iterator>
#include <memory>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

namespace {
using Value = flutter::EncodableValue;
using Map = flutter::EncodableMap;
using Channel = flutter::MethodChannel<Value>;

constexpr wchar_t kPlatformProvider[] = MS_PLATFORM_CRYPTO_PROVIDER;
constexpr char kDevicePrefix[] = "gorape-windows-";
constexpr char kDpopPrefix[] = "gfapp_dpop_";
constexpr char kB64Url[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
constexpr std::array<uint8_t, 26> kSpkiPrefix = {
    0x30,0x59,0x30,0x13,0x06,0x07,0x2A,0x86,0x48,0xCE,0x3D,0x02,0x01,
    0x06,0x08,0x2A,0x86,0x48,0xCE,0x3D,0x03,0x01,0x07,0x03,0x42,0x00};

struct ProviderHandle {
  NCRYPT_PROV_HANDLE value = 0;
  ProviderHandle() = default;
  ProviderHandle(const ProviderHandle&) = delete;
  ProviderHandle& operator=(const ProviderHandle&) = delete;
  ProviderHandle(ProviderHandle&& other) noexcept : value(other.value) { other.value = 0; }
  ProviderHandle& operator=(ProviderHandle&& other) noexcept {
    if (this != &other) {
      if (value) NCryptFreeObject(value);
      value = other.value;
      other.value = 0;
    }
    return *this;
  }
  ~ProviderHandle() { if (value) NCryptFreeObject(value); }
};
struct KeyHandle {
  NCRYPT_KEY_HANDLE value = 0;
  ~KeyHandle() { if (value) NCryptFreeObject(value); }
};

[[noreturn]] void Fail(const char* message) { throw std::runtime_error(message); }

void Check(SECURITY_STATUS status, const char* message) {
  if (status != ERROR_SUCCESS) Fail(message);
}

std::string EncodeBase64Url(const uint8_t* bytes, size_t length) {
  std::string output;
  output.reserve((length * 4 + 2) / 3);
  uint32_t accumulator = 0;
  int bits = -6;
  for (size_t i = 0; i < length; ++i) {
    accumulator = (accumulator << 8) | bytes[i];
    bits += 8;
    while (bits >= 0) {
      output.push_back(kB64Url[(accumulator >> bits) & 0x3f]);
      bits -= 6;
    }
  }
  if (bits > -6) output.push_back(kB64Url[((accumulator << 8) >> (bits + 8)) & 0x3f]);
  return output;
}

std::vector<uint8_t> DecodeBase64Url(const std::string& text) {
  std::vector<uint8_t> output;
  uint32_t accumulator = 0;
  int bits = -8;
  for (char character : text) {
    const char* position = std::find(std::begin(kB64Url), std::end(kB64Url) - 1, character);
    if (position == std::end(kB64Url) - 1) Fail("Invalid base64url input.");
    accumulator = (accumulator << 6) | static_cast<uint32_t>(position - kB64Url);
    bits += 6;
    if (bits >= 0) {
      output.push_back(static_cast<uint8_t>((accumulator >> bits) & 0xff));
      bits -= 8;
    }
  }
  if (output.empty()) Fail("Empty base64url input.");
  return output;
}

std::wstring Widen(const std::string& value) {
  if (value.empty()) Fail("Empty native key identifier.");
  int count = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, value.data(),
                                  static_cast<int>(value.size()), nullptr, 0);
  if (count <= 0) Fail("Invalid native key identifier.");
  std::wstring result(count, L'\0');
  if (MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, value.data(),
                          static_cast<int>(value.size()), result.data(), count) != count) {
    Fail("Invalid native key identifier.");
  }
  return result;
}

std::string StringArgument(const Value* arguments, const char* name) {
  const auto* map = std::get_if<Map>(arguments);
  if (!map) Fail("Native key method arguments are missing.");
  auto found = map->find(Value(name));
  if (found == map->end()) Fail("Native key method argument is missing.");
  const auto* value = std::get_if<std::string>(&found->second);
  if (!value || value->empty()) Fail("Native key method argument is invalid.");
  return *value;
}

void ValidateIdentifier(const std::string& name, bool dpop) {
  const std::string prefix = dpop ? kDpopPrefix : kDevicePrefix;
  if (name.size() > 128 || name.rfind(prefix, 0) != 0) Fail("Invalid key namespace.");
  for (char character : name) {
    if (!((character >= 'a' && character <= 'z') ||
          (character >= 'A' && character <= 'Z') ||
          (character >= '0' && character <= '9') || character == '-' || character == '_')) {
      Fail("Invalid key identifier.");
    }
  }
}

ProviderHandle OpenHardwareProvider() {
  ProviderHandle provider;
  Check(NCryptOpenStorageProvider(&provider.value, kPlatformProvider, 0),
        "Windows Platform Crypto Provider is unavailable.");
  DWORD implementation = 0;
  DWORD size = 0;
  Check(NCryptGetProperty(provider.value, NCRYPT_IMPL_TYPE_PROPERTY,
                          reinterpret_cast<PBYTE>(&implementation), sizeof(implementation),
                          &size, 0),
        "Windows TPM provider capability could not be verified.");
  if (size != static_cast<DWORD>(sizeof(implementation)) ||
      (implementation & NCRYPT_IMPL_HARDWARE_FLAG) == 0 ||
      (implementation & NCRYPT_IMPL_SOFTWARE_FLAG) != 0) {
    Fail("Windows Platform Crypto Provider is not confirmed hardware-backed.");
  }
  return provider;
}

std::vector<uint8_t> ExportPublicKey(NCRYPT_KEY_HANDLE key) {
  DWORD size = 0;
  Check(NCryptExportKey(key, 0, BCRYPT_ECCPUBLIC_BLOB, nullptr, nullptr, 0, &size,
                        NCRYPT_SILENT_FLAG),
        "Windows TPM public key could not be queried.");
  if (size != static_cast<DWORD>(sizeof(BCRYPT_ECCKEY_BLOB) + 64)) Fail("Windows TPM public key size is invalid.");
  std::vector<uint8_t> blob(size);
  Check(NCryptExportKey(key, 0, BCRYPT_ECCPUBLIC_BLOB, nullptr, blob.data(), size,
                        &size, NCRYPT_SILENT_FLAG),
        "Windows TPM public key could not be exported.");
  const auto* header = reinterpret_cast<const BCRYPT_ECCKEY_BLOB*>(blob.data());
  if (header->dwMagic != BCRYPT_ECDSA_PUBLIC_P256_MAGIC || header->cbKey != 32) {
    Fail("Windows TPM key is not ECDSA P-256.");
  }
  std::vector<uint8_t> point(65);
  point[0] = 0x04;
  std::copy(blob.begin() + sizeof(BCRYPT_ECCKEY_BLOB), blob.end(), point.begin() + 1);
  return point;
}

std::string Pem(const std::vector<uint8_t>& point) {
  std::vector<uint8_t> der(kSpkiPrefix.begin(), kSpkiPrefix.end());
  der.insert(der.end(), point.begin(), point.end());
  const std::string encoded = EncodeBase64Url(der.data(), der.size());
  // PEM requires standard Base64 with padding; convert the same DER bytes directly.
  static constexpr char alphabet[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  std::string base64;
  uint32_t accumulator = 0;
  int bits = -6;
  for (uint8_t byte : der) {
    accumulator = (accumulator << 8) | byte;
    bits += 8;
    while (bits >= 0) {
      base64.push_back(alphabet[(accumulator >> bits) & 0x3f]);
      bits -= 6;
    }
  }
  if (bits > -6) base64.push_back(alphabet[((accumulator << 8) >> (bits + 8)) & 0x3f]);
  while (base64.size() % 4) base64.push_back('=');
  std::string output = "-----BEGIN PUBLIC KEY-----\n";
  for (size_t i = 0; i < base64.size(); i += 64) output += base64.substr(i, 64) + "\n";
  output += "-----END PUBLIC KEY-----\n";
  (void)encoded;
  return output;
}

std::vector<uint8_t> DerSignature(const std::vector<uint8_t>& raw) {
  if (raw.size() != 64) Fail("Windows TPM ECDSA signature has an invalid length.");
  auto integer = [](const uint8_t* input) {
    size_t first = 0;
    while (first < 31 && input[first] == 0) ++first;
    std::vector<uint8_t> output(input + first, input + 32);
    if (output.front() & 0x80) output.insert(output.begin(), 0);
    return output;
  };
  auto r = integer(raw.data());
  auto s = integer(raw.data() + 32);
  std::vector<uint8_t> body = {0x02, static_cast<uint8_t>(r.size())};
  body.insert(body.end(), r.begin(), r.end());
  body.push_back(0x02);
  body.push_back(static_cast<uint8_t>(s.size()));
  body.insert(body.end(), s.begin(), s.end());
  std::vector<uint8_t> result = {0x30, static_cast<uint8_t>(body.size())};
  result.insert(result.end(), body.begin(), body.end());
  return result;
}

Map Evidence(bool /* dpop */) {
  return {{Value("format"), Value("windows-cng-platform-tpm-local")},
          {Value("remote_attestation"), Value(false)},
          {Value("challenge_bound"), Value(false)},
          {Value("note"), Value("TPM-protected key; server-verifiable key attestation is not supplied by this provider.")}};
}

Map KeyMaterial(const std::string& name, bool dpop) {
  ValidateIdentifier(name, dpop);
  auto provider = OpenHardwareProvider();
  KeyHandle key;
  Check(NCryptOpenKey(provider.value, &key.value, Widen(name).c_str(), 0,
                      NCRYPT_SILENT_FLAG),
        "Windows TPM key is unavailable.");
  const auto point = ExportPublicKey(key.value);
  const std::vector<uint8_t> x(point.begin() + 1, point.begin() + 33);
  const std::vector<uint8_t> y(point.begin() + 33, point.end());
  return {{Value("keyIdentifier"), Value(name)},
          {Value("publicJwk"), Value(Map{{Value("kty"), Value("EC")},
                                         {Value("crv"), Value("P-256")},
                                         {Value("x"), Value(EncodeBase64Url(x.data(), x.size()))},
                                         {Value("y"), Value(EncodeBase64Url(y.data(), y.size()))}})},
          {Value("publicKeyPem"), Value(Pem(point))},
          {Value("algorithm"), Value("ES256")},
          {Value("securityLevel"), Value("windows_tpm_local")},
          {Value("certificateChain"), Value(flutter::EncodableList())},
          {Value("attestationEvidence"), Value(Evidence(dpop))}};
}

std::string NewDpopIdentifier() {
  std::array<uint8_t, 16> bytes{};
  if (BCryptGenRandom(nullptr, bytes.data(), static_cast<ULONG>(bytes.size()),
                      BCRYPT_USE_SYSTEM_PREFERRED_RNG) < 0) {
    Fail("Windows secure random generator is unavailable.");
  }
  bytes[6] = static_cast<uint8_t>((bytes[6] & 0x0f) | 0x40);
  bytes[8] = static_cast<uint8_t>((bytes[8] & 0x3f) | 0x80);
  static constexpr char hex[] = "0123456789abcdef";
  std::string uuid;
  for (size_t i = 0; i < bytes.size(); ++i) {
    if (i == 4 || i == 6 || i == 8 || i == 10) uuid.push_back('-');
    uuid.push_back(hex[bytes[i] >> 4]);
    uuid.push_back(hex[bytes[i] & 0x0f]);
  }
  return std::string(kDpopPrefix) + uuid;
}

// GF-02180 — Creates a non-exportable P-256 key in the TPM-backed CNG provider.
Map CreateKey(const std::string& name, bool dpop) {
  ValidateIdentifier(name, dpop);
  auto provider = OpenHardwareProvider();
  KeyHandle key;
  Check(NCryptCreatePersistedKey(provider.value, &key.value,
                                 BCRYPT_ECDSA_P256_ALGORITHM, Widen(name).c_str(),
                                 0, 0),
        "Windows TPM P-256 key could not be created.");
  DWORD export_policy = 0;
  try {
    Check(NCryptSetProperty(key.value, NCRYPT_EXPORT_POLICY_PROPERTY,
                            reinterpret_cast<PBYTE>(&export_policy), static_cast<DWORD>(sizeof(export_policy)), 0),
          "Windows TPM key export policy could not be restricted.");
    DWORD usage = NCRYPT_ALLOW_SIGNING_FLAG;
    Check(NCryptSetProperty(key.value, NCRYPT_KEY_USAGE_PROPERTY,
                            reinterpret_cast<PBYTE>(&usage), static_cast<DWORD>(sizeof(usage)), 0),
          "Windows TPM key usage could not be restricted.");
    Check(NCryptFinalizeKey(key.value, NCRYPT_SILENT_FLAG),
          "Windows TPM P-256 key could not be finalized.");
    NCryptFreeObject(key.value);
    key.value = 0;
    return KeyMaterial(name, dpop);
  } catch (...) {
    if (key.value) {
      NCRYPT_KEY_HANDLE failed = key.value;
      key.value = 0;
      NCryptDeleteKey(failed, NCRYPT_SILENT_FLAG);
    } else {
      NCRYPT_KEY_HANDLE failed = 0;
      if (NCryptOpenKey(provider.value, &failed, Widen(name).c_str(), 0,
                        NCRYPT_SILENT_FLAG) == ERROR_SUCCESS) {
        NCryptDeleteKey(failed, NCRYPT_SILENT_FLAG);
      }
    }
    throw;
  }
}

// GF-02181 — Signs a Device payload through the TPM-backed CNG key.
std::string Sign(const std::string& name, bool dpop, const std::string& data_text) {
  ValidateIdentifier(name, dpop);
  const auto data = DecodeBase64Url(data_text);
  if (data.size() > 16 * 1024) Fail("Native signing input exceeds the size limit.");
  auto provider = OpenHardwareProvider();
  KeyHandle key;
  Check(NCryptOpenKey(provider.value, &key.value, Widen(name).c_str(), 0,
                      NCRYPT_SILENT_FLAG), "Windows TPM key is unavailable.");
  BCRYPT_ALG_HANDLE algorithm = nullptr;
  Check(BCryptOpenAlgorithmProvider(&algorithm, BCRYPT_SHA256_ALGORITHM, nullptr, 0),
        "SHA-256 is unavailable.");
  std::array<uint8_t, 32> digest{};
  DWORD digest_size = 0;
  DWORD bytes_returned = 0;
  Check(BCryptGetProperty(algorithm, BCRYPT_HASH_LENGTH,
                          reinterpret_cast<PUCHAR>(&digest_size), sizeof(digest_size),
                          &bytes_returned, 0), "SHA-256 output size is unavailable.");
  if (digest_size != static_cast<DWORD>(digest.size())) { BCryptCloseAlgorithmProvider(algorithm, 0); Fail("SHA-256 output size is invalid."); }
  BCRYPT_HASH_HANDLE hash = nullptr;
  DWORD object_size = 0;
  DWORD result_size = 0;
  Check(BCryptGetProperty(algorithm, BCRYPT_OBJECT_LENGTH,
                          reinterpret_cast<PUCHAR>(&object_size), sizeof(object_size),
                          &result_size, 0), "SHA-256 hash context size is unavailable.");
  std::vector<uint8_t> hash_object(object_size);
  NTSTATUS status = BCryptCreateHash(algorithm, &hash, hash_object.data(), object_size, nullptr, 0, 0);
  if (status < 0) { BCryptCloseAlgorithmProvider(algorithm, 0); Fail("SHA-256 hash initialization failed."); }
  status = BCryptHashData(hash, const_cast<PUCHAR>(data.data()), static_cast<ULONG>(data.size()), 0);
  if (status >= 0) status = BCryptFinishHash(hash, digest.data(), static_cast<ULONG>(digest.size()), 0);
  BCryptDestroyHash(hash);
  BCryptCloseAlgorithmProvider(algorithm, 0);
  if (status < 0) Fail("SHA-256 hashing failed.");
  DWORD signature_size = 0;
  Check(NCryptSignHash(key.value, nullptr, digest.data(), static_cast<DWORD>(digest.size()), nullptr, 0,
                       &signature_size, NCRYPT_SILENT_FLAG),
        "Windows TPM signing is unavailable.");
  std::vector<uint8_t> raw(signature_size);
  Check(NCryptSignHash(key.value, nullptr, digest.data(), static_cast<DWORD>(digest.size()), raw.data(),
                       signature_size, &signature_size, NCRYPT_SILENT_FLAG),
        "Windows TPM signing failed.");
  const auto der = DerSignature(raw);
  return EncodeBase64Url(der.data(), der.size());
}

Value Dispatch(const flutter::MethodCall<Value>& call, bool dpop) {
  const std::string method = call.method_name();
  const auto* arguments = call.arguments();
  if (!dpop && method == "availability") {
    try {
      auto provider = OpenHardwareProvider();
      (void)provider;
      return Value(Map{{Value("supported"), Value(true)},
                       {Value("hardwareBacked"), Value(true)},
                       {Value("attestationSupported"), Value(false)},
                       {Value("securityLevel"), Value("windows_tpm_local")},
                       {Value("reason"), Value("Microsoft Platform Crypto Provider is TPM-backed; remote key attestation is not configured.")}});
    } catch (...) {
      return Value(Map{{Value("supported"), Value(false)},
                       {Value("hardwareBacked"), Value(false)},
                       {Value("attestationSupported"), Value(false)},
                       {Value("securityLevel"), Value("unavailable")},
                       {Value("reason"), Value("Windows TPM Platform Crypto Provider is unavailable.")}});
    }
  }
  if ((dpop && method == "createKey") || (!dpop && method == "generateKey")) {
    if (!dpop) {
      auto challenge = DecodeBase64Url(StringArgument(arguments, "challenge"));
      if (challenge.size() < 16 || challenge.size() > 128) Fail("Attestation challenge size is invalid.");
    } else {
      auto challenge = DecodeBase64Url(StringArgument(arguments, "attestationChallenge"));
      if (challenge.size() < 16 || challenge.size() > 128) Fail("Attestation challenge size is invalid.");
    }
    std::string name = dpop ? NewDpopIdentifier()
                            : StringArgument(arguments, "keyIdentifier");
    auto result = CreateKey(name, dpop);
    return Value(std::move(result));
  }
  if ((dpop && method == "getKey") || (!dpop && method == "hasKey")) {
    const auto name = StringArgument(arguments, "keyIdentifier");
    ValidateIdentifier(name, dpop);
    if (!dpop) {
      try { (void)KeyMaterial(name, false); return Value(true); }
      catch (...) { return Value(false); }
    }
    return Value(KeyMaterial(name, true));
  }
  if (method == "sign") {
    return Value(Sign(StringArgument(arguments, "keyIdentifier"), dpop,
                      StringArgument(arguments, "data")));
  }
  if (method == "deleteKey") {
    const auto name = StringArgument(arguments, "keyIdentifier");
    ValidateIdentifier(name, dpop);
    auto provider = OpenHardwareProvider();
    KeyHandle key;
    SECURITY_STATUS status = NCryptOpenKey(provider.value, &key.value,
                                           Widen(name).c_str(), 0, NCRYPT_SILENT_FLAG);
    if (status == NTE_BAD_KEYSET) return Value();
    Check(status, "Windows TPM key could not be opened for deletion.");
    NCRYPT_KEY_HANDLE handle = key.value;
    key.value = 0;
    Check(NCryptDeleteKey(handle, NCRYPT_SILENT_FLAG), "Windows TPM key deletion failed.");
    return Value();
  }
  Fail("Unknown native key operation.");
}

void SetHandler(Channel* channel, bool dpop) {
  channel->SetMethodCallHandler([dpop](const auto& call, auto result) {
    try {
      result->Success(Dispatch(call, dpop));
    } catch (...) {
      result->Error("native_key_error", "Windows hardware key operation failed.", nullptr);
    }
  });
}
}  // namespace

// GF-02182 — Installs the Device key channel using the Windows Platform Crypto Provider.
void RegisterWindowsNativeKeyChannels(
    flutter::BinaryMessenger* messenger,
    std::unique_ptr<Channel>* device_channel) {
  *device_channel = std::make_unique<Channel>(
      messenger, "com.gorapeflutter.gf_app/device_key",
      &flutter::StandardMethodCodec::GetInstance());
  SetHandler(device_channel->get(), false);
}
