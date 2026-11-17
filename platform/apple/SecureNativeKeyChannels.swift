#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif
import Foundation
import Security

/// Apple Secure Enclave P-256 key operations for Device and DPoP namespaces.
/// Secure Enclave keys are non-exportable locally; Apple does not remotely
/// attest arbitrary Secure Enclave keys, so the response never claims that it
/// does. App Attest is a separate key and is intentionally not substituted.
enum SecureNativeKeyChannels {
  private static let keyStoreQueue = DispatchQueue(label: "com.gorapeflutter.gf_app.secure-key")
  private static let deviceChannel = "com.gorapeflutter.gf_app/device_key"

  // GF-01394 — Install the Apple Secure Enclave Driver for device-key operations.
  // GF-02177 — Registers the Secure Enclave channel for Device keys.
  static func install(binaryMessenger: FlutterBinaryMessenger) {
    installChannel(name: deviceChannel, binaryMessenger: binaryMessenger, namespace: "device")
  }

  // GF-01395 — Register one MethodChannel for an Apple native-key namespace.
  private static func installChannel(
    name: String,
    binaryMessenger: FlutterBinaryMessenger,
    namespace: String
  ) {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: binaryMessenger)
    channel.setMethodCallHandler { /* GF-01411 — Dispatch a Flutter call to the serialized native-key queue. */ call, result in
      keyStoreQueue.async {
        // GF-01412 — Run Keychain work away from Flutter's main thread.
        do {
          let value = try dispatch(call, namespace: namespace)
          DispatchQueue.main.async {
            // GF-01413 — Deliver a successful method-channel result on the main thread.
            result(value)
          }
        } catch {
          DispatchQueue.main.async {
            // GF-01414 — Deliver a typed method-channel error on the main thread.
            result(FlutterError(code: "secure_key_error", message: "Apple Secure Enclave key operation failed.", details: nil))
          }
        }
      }
    }
  }

  // GF-01396 — Route Flutter method-channel commands to an Apple key operation.
  private static func dispatch(_ call: FlutterMethodCall, namespace: String) throws -> Any? {
    let arguments = call.arguments as? [String: Any] ?? [:]
    switch (namespace, call.method) {
    case ("device", "availability"):
      return probe(namespace: "device")
    case ("device", "generateKey"):
      let identifier = try string(arguments, "keyIdentifier")
      let challenge = try decode(string(arguments, "challenge"))
      guard (16...128).contains(challenge.count) else { throw KeyError.invalidInput }
      return try createKey(identifier: identifier, namespace: "device")
    case ("device", "sign"):
      return try sign(identifier: string(arguments, "keyIdentifier"), namespace: "device", data: decode(string(arguments, "data")))
    case ("device", "hasKey"):
      return hasKey(identifier: string(arguments, "keyIdentifier"), namespace: "device")
    case ("device", "deleteKey"):
      try deleteKey(identifier: string(arguments, "keyIdentifier"), namespace: "device")
      return nil
    case ("dpop", "createKey"):
      let challenge = try decode(string(arguments, "attestationChallenge"))
      guard (16...128).contains(challenge.count) else { throw KeyError.invalidInput }
      return try createKey(identifier: "gfapp_dpop_\(UUID().uuidString)", namespace: "dpop")
    case ("dpop", "getKey"):
      return try keyMaterial(identifier: string(arguments, "keyIdentifier"), namespace: "dpop")
    case ("dpop", "sign"):
      return try sign(identifier: string(arguments, "keyIdentifier"), namespace: "dpop", data: decode(string(arguments, "data")))
    case ("dpop", "hasKey"):
      return hasKey(identifier: string(arguments, "keyIdentifier"), namespace: "dpop")
    case ("dpop", "deleteKey"):
      try deleteKey(identifier: string(arguments, "keyIdentifier"), namespace: "dpop")
      return nil
    default:
      throw KeyError.invalidInput
    }
  }

  // GF-01397 — Report Secure Enclave availability without claiming remote attestation.
  private static func probe(namespace: String) -> [String: Any] {
    let identifier = namespace == "dpop"
      ? "gfapp_dpop_probe_\(UUID().uuidString)"
      : "gorape-probe-\(UUID().uuidString)"
    do {
      _ = try createKey(identifier: identifier, namespace: namespace)
      try? deleteKey(identifier: identifier, namespace: namespace)
      return [
        "supported": true,
        "hardwareBacked": true,
        "attestationSupported": false,
        "securityLevel": "secure_enclave_local",
        "reason": "Secure Enclave key operations are available; arbitrary-key remote attestation is not exposed by Apple.",
      ]
    } catch {
      return [
        "supported": false,
        "hardwareBacked": false,
        "attestationSupported": false,
        "securityLevel": "unavailable",
        "reason": "Secure Enclave P-256 key creation is unavailable on this device.",
      ]
    }
  }

  // GF-01398 — Create a non-exportable P-256 Secure Enclave key and describe its assurance boundary.
  // GF-02178 — Creates a non-exportable P-256 Secure Enclave key and labels its attestation boundary.
  private static func createKey(identifier: String, namespace: String) throws -> [String: Any] {
    try validateIdentifier(identifier, namespace: namespace)
    try deleteKey(identifier: identifier, namespace: namespace)
    var accessError: Unmanaged<CFError>?
    guard let access = SecAccessControlCreateWithFlags(
      kCFAllocatorDefault,
      kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
      [.privateKeyUsage],
      &accessError
    ) else {
      if let error = accessError?.takeRetainedValue() { throw error }
      throw KeyError.keyUnavailable
    }

    let attributes: [String: Any] = [
      kSecUseDataProtectionKeychain as String: true,
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeySizeInBits as String: 256,
      kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
      kSecPrivateKeyAttrs as String: [
        kSecAttrIsPermanent as String: true,
        kSecAttrApplicationTag as String: tag(identifier, namespace: namespace),
        kSecAttrAccessControl as String: access,
      ],
    ]
    var keyError: Unmanaged<CFError>?
    guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &keyError) else {
      if let error = keyError?.takeRetainedValue() { throw error }
      throw KeyError.keyUnavailable
    }
    guard isSecureEnclave(privateKey) else {
      try? deleteKey(identifier: identifier, namespace: namespace)
      throw KeyError.keyUnavailable
    }
    return try keyMaterial(privateKey: privateKey, identifier: identifier, namespace: namespace)
  }

  // GF-01399 — Load and serialize public material for a Secure Enclave key.
  private static func keyMaterial(identifier: String, namespace: String) throws -> [String: Any] {
    try validateIdentifier(identifier, namespace: namespace)
    var query: [String: Any] = [
      kSecUseDataProtectionKeychain as String: true,
      kSecClass as String: kSecClassKey,
      kSecAttrApplicationTag as String: tag(identifier, namespace: namespace),
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
      kSecReturnRef as String: true,
    ]
    var item: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
          let privateKey = item as? SecKey else { throw KeyError.keyUnavailable }
    guard isSecureEnclave(privateKey) else { throw KeyError.keyUnavailable }
    return try keyMaterial(privateKey: privateKey, identifier: identifier, namespace: namespace)
  }

  // GF-01400 — Serialize public-key evidence and the local assurance boundary.
  private static func keyMaterial(privateKey: SecKey, identifier: String, namespace: String) throws -> [String: Any] {
    guard let publicKey = SecKeyCopyPublicKey(privateKey) else { throw KeyError.keyUnavailable }
    var exportError: Unmanaged<CFError>?
    guard let raw = SecKeyCopyExternalRepresentation(publicKey, &exportError) as Data?,
          raw.count == 65, raw.first == 0x04 else {
      if let error = exportError?.takeRetainedValue() { throw error }
      throw KeyError.keyUnavailable
    }
    let x = raw.subdata(in: 1..<33)
    let y = raw.subdata(in: 33..<65)
    let spkiPrefix = Data([0x30,0x59,0x30,0x13,0x06,0x07,0x2A,0x86,0x48,0xCE,0x3D,0x02,0x01,0x06,0x08,0x2A,0x86,0x48,0xCE,0x3D,0x03,0x01,0x07,0x03,0x42,0x00])
    let publicKeyPem = pem(spkiPrefix + raw)
    return [
      "keyIdentifier": identifier,
      "publicJwk": ["kty": "EC", "crv": "P-256", "x": encode(x), "y": encode(y)],
      "publicKeyPem": publicKeyPem,
      "algorithm": "ES256",
      "securityLevel": "secure_enclave_local",
      "certificateChain": [String](),
      "attestationEvidence": [
        "format": "apple-secure-enclave-local",
        "remote_attestation": false,
        "challenge_bound": false,
        "note": "App Attest is a distinct key and is not evidence for this P-256 key.",
      ],
    ]
  }

  // GF-01401 — Sign data with an existing Secure Enclave key without exporting private material.
  // GF-02179 — Signs data with a validated Secure Enclave key without exporting private material.
  private static func sign(identifier: String, namespace: String, data: Data) throws -> String {
    try validateIdentifier(identifier, namespace: namespace)
    guard !data.isEmpty, data.count <= 16 * 1024 else { throw KeyError.invalidInput }
    _ = try keyMaterial(identifier: identifier, namespace: namespace)
    var query: [String: Any] = [
      kSecUseDataProtectionKeychain as String: true,
      kSecClass as String: kSecClassKey,
      kSecAttrApplicationTag as String: tag(identifier, namespace: namespace),
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
      kSecReturnRef as String: true,
    ]
    var item: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
          let privateKey = item as? SecKey else { throw KeyError.keyUnavailable }
    guard isSecureEnclave(privateKey) else { throw KeyError.keyUnavailable }
    var signatureError: Unmanaged<CFError>?
    guard let signature = SecKeyCreateSignature(
      privateKey,
      .ecdsaSignatureMessageX962SHA256,
      data as CFData,
      &signatureError
    ) as Data? else {
      if let error = signatureError?.takeRetainedValue() { throw error }
      throw KeyError.keyUnavailable
    }
    return encode(signature)
  }

  // GF-01402 — Check whether a key is bound to the Secure Enclave token.
  private static func isSecureEnclave(_ key: SecKey) -> Bool {
    guard let attributes = SecKeyCopyAttributes(key) as? [String: Any] else { return false }
    return (attributes[kSecAttrTokenID as String] as? String) == (kSecAttrTokenIDSecureEnclave as String)
  }

  // GF-01403 — Check whether a Secure Enclave key exists in its namespace.
  private static func hasKey(identifier: String, namespace: String) -> Bool {
    guard (try? validateIdentifier(identifier, namespace: namespace)) != nil else { return false }
    let query: [String: Any] = [
      kSecUseDataProtectionKeychain as String: true,
      kSecClass as String: kSecClassKey,
      kSecAttrApplicationTag as String: tag(identifier, namespace: namespace),
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
    ]
    return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
  }

  // GF-01404 — Delete a Secure Enclave key from its namespace.
  private static func deleteKey(identifier: String, namespace: String) throws {
    try validateIdentifier(identifier, namespace: namespace)
    let query: [String: Any] = [
      kSecUseDataProtectionKeychain as String: true,
      kSecClass as String: kSecClassKey,
      kSecAttrApplicationTag as String: tag(identifier, namespace: namespace),
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
    ]
    let status = SecItemDelete(query as CFDictionary)
    if status != errSecSuccess && status != errSecItemNotFound { throw KeyError.keyUnavailable }
  }

  // GF-01405 — Validate the native-key identifier and its namespace prefix.
  private static func validateIdentifier(_ value: String, namespace: String) throws {
    guard !value.isEmpty, value.count <= 128,
          value.range(of: "^[A-Za-z0-9_-]+$", options: .regularExpression) != nil,
          (namespace == "dpop" ? value.hasPrefix("gfapp_dpop_") : value.hasPrefix("gorape-")) else {
      throw KeyError.invalidInput
    }
  }

  // GF-01406 — Build a namespaced Keychain application tag.
  private static func tag(_ identifier: String, namespace: String) -> Data {
    Data("com.gorapeflutter.gf_app.\(namespace).\(identifier)".utf8)
  }

  // GF-01407 — Read a required non-empty string from Flutter arguments.
  private static func string(_ arguments: [String: Any], _ name: String) throws -> String {
    guard let value = arguments[name] as? String, !value.isEmpty else { throw KeyError.invalidInput }
    return value
  }

  // GF-01408 — Decode unpadded Base64url input into bytes.
  private static func decode(_ value: String) throws -> Data {
    var normalized = value.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
    let remainder = normalized.count % 4
    if remainder != 0 { normalized += String(repeating: "=", count: 4 - remainder) }
    guard let data = Data(base64Encoded: normalized) else { throw KeyError.invalidInput }
    return data
  }

  // GF-01409 — Encode bytes as unpadded Base64url.
  private static func encode(_ data: Data) -> String {
    data.base64EncodedString().replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }

  // GF-01410 — Wrap DER SubjectPublicKeyInfo bytes in a PEM document.
  private static func pem(_ der: Data) -> String {
    let text = der.base64EncodedString(options: [.lineLength64Characters, .endLineWithLineFeed])
    return "-----BEGIN PUBLIC KEY-----\n\(text)-----END PUBLIC KEY-----\n"
  }

  private enum KeyError: Error { case invalidInput, keyUnavailable }
}
