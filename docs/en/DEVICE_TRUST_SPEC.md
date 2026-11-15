# Gorapeflutter Requirements, Architecture, and Implementation Specification

This document defines the architecture, assurance levels, API contracts, and platform matrix for `gf-app` (GF Native), `gorape` (Gorape Server), and the external service samples (`gf-sample-backend` / `gf-sample-web`).

---

## 1. Architecture Overview

```mermaid
flowchart LR
    User[User] --> Native[GF Native / Flutter]
    Native -->|OIDC Authorization Code + PKCE| Keycloak[Keycloak IdP]
    Native -->|OS Passkey API| Authn[OS Passkey Provider / Authenticator]
    Native -->|WebAuthn Registration Options / Verify| Gorape[Gorape Server / WebAuthn RP]

    User --> Vue[External Web App / gf-sample-web]
    Vue -->|OIDC + PKCE| Keycloak
    Vue -->|1. Start Sensitive Operation| Svc[External Service Server / gf-sample-backend]
    Svc -->|2. Service Account + GF-API-01<br/>POST /proof-requests| Gorape
    Gorape -->|3. proof_id + public_key_options| Svc
    Svc -->|4. WebAuthn Options| Vue
    Vue -->|5. navigator.credentials.get()<br/>Same-device or cross-device hybrid| Authn
    Authn -->|6. Signed Assertion| Vue
    Vue -->|7. Submit Assertion| Svc
    Svc -->|8. GF-API-02<br/>POST /proof-requests/:proofId/verify| Gorape
    Gorape -->|9. verified + assurance_level + operation_id| Svc
    Svc -->|10. Execute Operation Once| Vue
```

---

## 2. Assurance Level Matrix

| Assurance Level (`assurance_level`) | Condition | High-Assurance Services (`hardware_attested`) | Standard Services (`standard_passkey`) |
|---|---|---|---|
| `hardware_attested` | `BE=0` (single-device bound) AND verified hardware attestation (`android-key` TEE/StrongBox+RootOfTrust, `tpm` AIK chain, `apple` chain, or FIDO MDS hardware-backed key) | **Allowed** (preserved over `hybrid` transport) | **Allowed** |
| `device_bound_unattested` | `BE=0`, but hardware backing is unverified (`fmt=none` or Self Attestation) | **Denied** | **Allowed** |
| `standard_passkey` | Valid WebAuthn credential with `BE=1` (syncable passkey) | **Denied** | **Allowed** |
| `rejected` | Invalid evidence, policy mismatch, revoked, or clone warning | **Denied** | **Denied** |

---

## 3. External Service Verification APIs

- **GF-API-01: Issue Operation-Bound Challenge**
  - `POST /v1/projects/{projectId}/proof-requests`
  - Required Permission: `proof:request` (`gorape-service` role)
  - Request fields: `service_id`, `principal_id`, `operation_id`, `method`, `path`, `body_hash`, `required_assurance`, `credential_id` (optional)
  - Response fields: `proof_id`, `expires_at`, `public_key_options`
- **GF-API-02: Verify Operation-Bound Assertion**
  - `POST /v1/projects/{projectId}/proof-requests/{proofId}/verify`
  - Required Permission: `proof:verify` (`gorape-service` role)
  - Request fields: `service_id`, `operation_id`, `credential`
  - Response fields: `verified`, `principal_id`, `device_id`, `credential_id`, `assurance_level`, `operation_id`
