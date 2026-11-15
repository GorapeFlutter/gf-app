# Processing-step ID index

[GF-02000](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L53) and above identify meaningful stages inside multi-step functions.
The corresponding English comments appear at the operation they describe.
These are logical processing boundaries, not IDs for individual statements.

| ID | Processing step | Source |
| --- | --- | --- |
| [GF-02000](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L53) | Read and decode the locally persisted token set | `lib/back/usecase/auth.dart` |
| [GF-02001](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L60) | Remove malformed session data | `lib/back/usecase/auth.dart` |
| [GF-02002](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L64) | Reuse a session with a valid access token | `lib/back/usecase/auth.dart` |
| [GF-02003](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L68) | Refresh an expired session and persist the replacement | `lib/back/usecase/auth.dart` |
| [GF-02004](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L76) | Clear an expired session that cannot be refreshed | `lib/back/usecase/auth.dart` |
| [GF-02005](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L87) | Reject sign-in on unsupported platforms | `lib/back/usecase/auth.dart` |
| [GF-02006](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L93) | Complete Authorization Code + PKCE sign-in | `lib/back/usecase/auth.dart` |
| [GF-02007](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L105) | Persist tokens before returning the authenticated session | `lib/back/usecase/auth.dart` |
| [GF-02008](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L123) | Skip refresh when the adapter or refresh token is unavailable | `lib/back/usecase/auth.dart` |
| [GF-02009](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L126) | Refresh and persist the replacement tokens | `lib/back/usecase/auth.dart` |
| [GF-02010](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L139) | Attempt provider logout for a supported remote session | `lib/back/usecase/auth.dart` |
| [GF-02011](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L149) | Clear the local session after logout handling | `lib/back/usecase/auth.dart` |
| [GF-02012](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L621) | Build the API URI, JSON body, and request headers | `lib/back/repository/gorape.dart` |
| [GF-02013](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L636) | Send the initial API request | `lib/back/repository/gorape.dart` |
| [GF-02014](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L646) | Refresh an expired access token at most once | `lib/back/repository/gorape.dart` |
| [GF-02015](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L654) | Retry the original API request once with the new token | `lib/back/repository/gorape.dart` |
| [GF-02016](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L664) | Decode a successful JSON response | `lib/back/repository/gorape.dart` |
| [GF-02017](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L672) | Map non-success HTTP responses to app exceptions | `lib/back/repository/gorape.dart` |
| [GF-02018](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L704) | Dispatch the request using its HTTP method | `lib/back/repository/gorape.dart` |
| [GF-02019](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L740) | Map request timeouts to network errors | `lib/back/repository/gorape.dart` |
| [GF-02020](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L756) | Map HTTP client failures to network errors | `lib/back/repository/gorape.dart` |
| [GF-02021](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L770) | Read structured API error details from JSON | `lib/back/repository/gorape.dart` |
| [GF-02022](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L781) | Add guidance for rejected authentication | `lib/back/repository/gorape.dart` |
| [GF-02023](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L96) | Normalize and validate the registration display name | `lib/back/usecase/device.dart` |
| [GF-02024](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L106) | Check local OS-key and attestation capability | `lib/back/usecase/device.dart` |
| [GF-02025](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L119) | Require a configured backend verifier | `lib/back/usecase/device.dart` |
| [GF-02026](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L122) | Request a single-use registration challenge | `lib/back/usecase/device.dart` |
| [GF-02027](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L134) | Bind the decoded challenge to a new OS key | `lib/back/usecase/device.dart` |
| [GF-02028](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L151) | Submit the public key and attestation evidence | `lib/back/usecase/device.dart` |
| [GF-02029](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L174) | Persist the local key alias after server verification | `lib/back/usecase/device.dart` |
| [GF-02030](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L182) | Delete the generated key when registration fails | `lib/back/usecase/device.dart` |
| [GF-02031](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L199) | Load and validate the registered local private key | `lib/back/usecase/device.dart` |
| [GF-02032](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L213) | Request a fresh proof challenge | `lib/back/usecase/device.dart` |
| [GF-02033](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L223) | Sign raw challenge bytes inside the OS key store | `lib/back/usecase/device.dart` |
| [GF-02034](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L234) | Submit the signature for server verification | `lib/back/usecase/device.dart` |
| [GF-02035](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L253) | Revoke the authoritative backend device record | `lib/back/usecase/device.dart` |
| [GF-02036](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L257) | Best-effort local key deletion and metadata cleanup | `lib/back/usecase/device.dart` |
| [GF-02037](https://github.com/GorapeFlutter/gf-app/blob/main/lib/app.dart#L47) | Resolve platform, settings, and authentication state | `lib/app.dart` |
| [GF-02038](https://github.com/GorapeFlutter/gf-app/blob/main/lib/app.dart#L53) | Keep the splash screen visible while settings load | `lib/app.dart` |
| [GF-02039](https://github.com/GorapeFlutter/gf-app/blob/main/lib/app.dart#L57) | Show connection-setting errors with a retry action | `lib/app.dart` |
| [GF-02040](https://github.com/GorapeFlutter/gf-app/blob/main/lib/app.dart#L78) | Route authenticated sessions to the app shell | `lib/app.dart` |
| [GF-02041](https://github.com/GorapeFlutter/gf-app/blob/main/lib/app.dart#L89) | Build the login screen with platform and settings data | `lib/app.dart` |
| [GF-02042](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/device.dart#L109) | Run device registration through its controller | `lib/back/controller/device.dart` |
| [GF-02043](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/device.dart#L113) | Invalidate device and local-key providers after registration | `lib/back/controller/device.dart` |
| [GF-02044](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/device.dart#L147) | Run possession proof through its controller | `lib/back/controller/device.dart` |
| [GF-02045](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/device.dart#L151) | Invalidate attestation and device providers after proof | `lib/back/controller/device.dart` |
| [GF-02046](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/device.dart#L178) | Revoke the device and trigger local key cleanup | `lib/back/controller/device.dart` |
| [GF-02047](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/device.dart#L182) | Invalidate providers that expose revoked-device data | `lib/back/controller/device.dart` |
| [GF-02048](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L81) | Create a group through the group use case | `lib/back/controller/group.dart` |
| [GF-02049](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L85) | Refresh the group list after creation | `lib/back/controller/group.dart` |
| [GF-02050](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L97) | Persist group edits through the group use case | `lib/back/controller/group.dart` |
| [GF-02051](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L101) | Refresh the group list after editing | `lib/back/controller/group.dart` |
| [GF-02052](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L109) | Delete the group on the backend | `lib/back/controller/group.dart` |
| [GF-02053](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L111) | Invalidate group and membership data after deletion | `lib/back/controller/group.dart` |
| [GF-02054](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L125) | Add a device to backend group membership | `lib/back/controller/group.dart` |
| [GF-02055](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L129) | Refresh group membership after assignment | `lib/back/controller/group.dart` |
| [GF-02056](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L142) | Remove a device from backend group membership | `lib/back/controller/group.dart` |
| [GF-02057](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L146) | Refresh group membership after removal | `lib/back/controller/group.dart` |
| [GF-02058](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/role.dart#L131) | Create a project role binding in Gorape | `lib/back/controller/role.dart` |
| [GF-02059](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/role.dart#L133) | Refresh project role bindings after creation | `lib/back/controller/role.dart` |
| [GF-02060](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/role.dart#L140) | Delete a project role binding in Gorape | `lib/back/controller/role.dart` |
| [GF-02061](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/role.dart#L144) | Refresh project role bindings after deletion | `lib/back/controller/role.dart` |
| [GF-02062](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/role.dart#L155) | Create a group role binding in Gorape | `lib/back/controller/role.dart` |
| [GF-02063](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/role.dart#L159) | Refresh group role bindings after creation | `lib/back/controller/role.dart` |
| [GF-02064](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/role.dart#L174) | Delete a group role binding in Gorape | `lib/back/controller/role.dart` |
| [GF-02065](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/role.dart#L178) | Refresh group role bindings after deletion | `lib/back/controller/role.dart` |
| [GF-02066](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/connection.dart#L29) | Start connection loading from platform defaults | `lib/back/usecase/connection.dart` |
| [GF-02067](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/connection.dart#L31) | Prefer locally persisted connection settings | `lib/back/usecase/connection.dart` |
| [GF-02068](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/connection.dart#L36) | Reject saved settings without the required OIDC scope | `lib/back/usecase/connection.dart` |
| [GF-02069](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/connection.dart#L61) | Validate connection URLs and OIDC fields | `lib/back/usecase/connection.dart` |
| [GF-02070](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/connection.dart#L69) | Persist validated settings securely | `lib/back/usecase/connection.dart` |
| [GF-02071](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/connection.dart#L76) | Remove overrides and return platform defaults | `lib/back/usecase/connection.dart` |
| [GF-02072](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/language.dart#L17) | Restore the saved language or default to Japanese | `lib/back/controller/language.dart` |
| [GF-02073](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/language.dart#L26) | Restrict language selection to supported locales | `lib/back/controller/language.dart` |
| [GF-02074](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/language.dart#L30) | Persist the language and update reactive UI state | `lib/back/controller/language.dart` |
| [GF-02075](https://github.com/GorapeFlutter/gf-app/blob/main/lib/entity/model/role.dart#L157) | Normalize Keycloak user attributes | `lib/entity/model/role.dart` |
| [GF-02076](https://github.com/GorapeFlutter/gf-app/blob/main/lib/entity/model/role.dart#L159) | Collect realm and client roles from token claims | `lib/entity/model/role.dart` |
| [GF-02077](https://github.com/GorapeFlutter/gf-app/blob/main/lib/entity/model/role.dart#L173) | Resolve cluster-wide roles and role-name fallbacks | `lib/entity/model/role.dart` |
| [GF-02078](https://github.com/GorapeFlutter/gf-app/blob/main/lib/entity/model/role.dart#L184) | Build project roles from claims and attributes | `lib/entity/model/role.dart` |
| [GF-02079](https://github.com/GorapeFlutter/gf-app/blob/main/lib/entity/model/role.dart#L212) | Build group roles from claims and attributes | `lib/entity/model/role.dart` |
| [GF-02080](https://github.com/GorapeFlutter/gf-app/blob/main/lib/entity/model/role.dart#L241) | Interpret group paths that encode roles | `lib/entity/model/role.dart` |
| [GF-02081](https://github.com/GorapeFlutter/gf-app/blob/main/lib/entity/model/role.dart#L275) | Publish the role snapshot used for UI access decisions | `lib/entity/model/role.dart` |
| [GF-02082](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L67) | Dispatch a native method-channel operation | `android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt` |
| [GF-02083](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L71) | Decode the registration challenge before key creation | `MainActivity.kt` |
| [GF-02084](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L77) | Decode proof bytes before signing | `MainActivity.kt` |
| [GF-02085](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L93) | Detect StrongBox and hardware-backed Keystore availability | `MainActivity.kt` |
| [GF-02086](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L97) | Return platform support and effective security level | `MainActivity.kt` |
| [GF-02087](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L117) | Remove a stale alias before key generation | `MainActivity.kt` |
| [GF-02088](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L124) | Prefer StrongBox and fall back to the device TEE | `MainActivity.kt` |
| [GF-02089](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L137) | Require an Android Key Attestation certificate chain | `MainActivity.kt` |
| [GF-02090](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L162) | Package public key, evidence chain, and security level | `MainActivity.kt` |
| [GF-02091](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L182) | Bind signing purpose, digest, and challenge to the key | `MainActivity.kt` |
| [GF-02092](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L196) | Generate the key pair inside Android Keystore | `MainActivity.kt` |
| [GF-02093](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L207) | Load a private-key entry by its Keystore alias | `MainActivity.kt` |
| [GF-02094](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L213) | Sign raw challenge bytes using SHA256withECDSA | `MainActivity.kt` |
| [GF-02095](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L217) | Return the DER signature as unpadded Base64url | `MainActivity.kt` |
| [GF-02096](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/register_device_screen.dart#L206) | Reset form errors and mark registration as active | `lib/ui/screens/register_device_screen.dart` |
| [GF-02097](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/register_device_screen.dart#L214) | Invoke the device-registration application flow | `lib/ui/screens/register_device_screen.dart` |
| [GF-02098](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/register_device_screen.dart#L222) | Present verified device details and next actions | `lib/ui/screens/register_device_screen.dart` |
| [GF-02099](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/register_device_screen.dart#L264) | Notify the parent and clear the submitted name | `lib/ui/screens/register_device_screen.dart` |
| [GF-02100](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/register_device_screen.dart#L268) | Keep registration failures visible in the form | `lib/ui/screens/register_device_screen.dart` |
| [GF-02101](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/register_device_screen.dart#L276) | Restore the form idle state after every outcome | `lib/ui/screens/register_device_screen.dart` |
| [GF-02102](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L301) | Clear proof errors and prevent duplicate submissions | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02103](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L309) | Run the challenge-signing ownership proof | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02104](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L317) | Report proof success and reload device evidence | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02105](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L323) | Surface proof failures on the device detail screen | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02106](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L331) | Release the proof action lock | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02107](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L343) | Require confirmation before device revocation | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02108](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L368) | Mark device revocation as active | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02109](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L376) | Revoke the backend device and clean up its local key | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02110](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L381) | Notify the user and close revoked device details | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02111](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L387) | Keep revocation failures on the current screen | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02112](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L395) | Release the revoke action lock | `lib/ui/screens/device_detail_screen.dart` |
| [GF-02113](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L385) | Clear feedback and mark connection settings as saving | `lib/ui/screens/settings_screen.dart` |
| [GF-02114](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L394) | Validate and persist settings through the controller | `lib/ui/screens/settings_screen.dart` |
| [GF-02115](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L397) | Confirm settings persistence to the user | `lib/ui/screens/settings_screen.dart` |
| [GF-02116](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L402) | Display validation or persistence errors | `lib/ui/screens/settings_screen.dart` |
| [GF-02117](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L409) | Clear the saving state after every outcome | `lib/ui/screens/settings_screen.dart` |
| [GF-02118](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L420) | Start reset feedback and prevent concurrent actions | `lib/ui/screens/settings_screen.dart` |
| [GF-02119](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L429) | Remove saved overrides and load platform defaults | `lib/ui/screens/settings_screen.dart` |
| [GF-02120](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L433) | Synchronize text fields with reset settings | `lib/ui/screens/settings_screen.dart` |
| [GF-02121](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L440) | Confirm that defaults have been restored | `lib/ui/screens/settings_screen.dart` |
| [GF-02122](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L445) | Display reset failures without discarding the form | `lib/ui/screens/settings_screen.dart` |
| [GF-02123](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L452) | Clear the saving state after reset | `lib/ui/screens/settings_screen.dart` |
| [GF-02124](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L463) | Start a health check and clear stale results | `lib/ui/screens/settings_screen.dart` |
| [GF-02125](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L472) | Query the configured Gorape endpoint | `lib/ui/screens/settings_screen.dart` |
| [GF-02126](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L475) | Format and display the health response | `lib/ui/screens/settings_screen.dart` |
| [GF-02127](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L484) | Display health-check transport or API errors | `lib/ui/screens/settings_screen.dart` |
| [GF-02128](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L491) | Clear the health-check progress state | `lib/ui/screens/settings_screen.dart` |
| [GF-02129](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L361) | Collect group edits and stop on dialog cancellation | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02130](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L369) | Persist group changes through the group controller | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02131](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L378) | Replace local group state and report success | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02132](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L397) | Confirm irreversible group deletion | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02133](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L427) | Delete the group through the group controller | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02134](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L432) | Close the detail screen after deletion | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02135](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L447) | Find active devices that are not yet assigned | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02136](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L468) | Ask the user to choose an eligible device | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02137](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L476) | Add the selected device to backend group membership | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02138](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L494) | Mark group membership removal as active | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02139](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L500) | Remove the device from backend group membership | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02140](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L518) | Collect the subject and role to grant | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02141](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L526) | Persist a group role binding through the controller | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02142](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L551) | Mark group role-binding deletion as active | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02143](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L557) | Delete the selected group role binding | `lib/ui/screens/group_detail_screen.dart` |
| [GF-02144](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L355) | Collect group details and handle dialog cancellation | `lib/ui/screens/project_management_screen.dart` |
| [GF-02145](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L363) | Create a group and report the outcome | `lib/ui/screens/project_management_screen.dart` |
| [GF-02146](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L386) | Collect the subject and project role to grant | `lib/ui/screens/project_management_screen.dart` |
| [GF-02147](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L394) | Persist a project role binding through the controller | `lib/ui/screens/project_management_screen.dart` |
| [GF-02148](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L418) | Mark project role-binding deletion as active | `lib/ui/screens/project_management_screen.dart` |
| [GF-02149](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L424) | Delete the selected project role binding | `lib/ui/screens/project_management_screen.dart` |
| [GF-02150](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L442) | Confirm irreversible device revocation | `lib/ui/screens/project_management_screen.dart` |
| [GF-02151](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L472) | Revoke the device and clean up local key data | `lib/ui/screens/project_management_screen.dart` |
| [GF-02152](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_management_screen.dart#L128) | Collect group details and handle dialog cancellation | `lib/ui/screens/group_management_screen.dart` |
| [GF-02153](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_management_screen.dart#L136) | Create a group and retain its server-generated record | `lib/ui/screens/group_management_screen.dart` |
| [GF-02154](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_management_screen.dart#L144) | Confirm creation and open the new group details | `lib/ui/screens/group_management_screen.dart` |
| [GF-02155](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L103) | Enter loading state before provider sign-in | `lib/back/controller/auth.dart` |
| [GF-02156](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L112) | Call the sign-in use case and publish the session | `lib/back/controller/auth.dart` |
| [GF-02157](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L122) | Preserve expected authentication errors for the UI | `lib/back/controller/auth.dart` |
| [GF-02158](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L140) | Wrap unexpected errors as authentication failures | `lib/back/controller/auth.dart` |
| [GF-02159](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L175) | Reuse an in-flight refresh instead of duplicating it | `lib/back/controller/auth.dart` |
| [GF-02160](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L178) | Start one refresh and clear its in-flight marker | `lib/back/controller/auth.dart` |
| [GF-02161](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L244) | Clear rejected credentials before publishing the auth error | `lib/back/controller/auth.dart` |
| [GF-02162](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L791) | Attach attestation guidance to validation failures | `lib/back/repository/gorape.dart` |
| [GF-02163](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L800) | Explain backend role authorization for forbidden actions | `lib/back/repository/gorape.dart` |
| [GF-02164](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L272) | Accept only implemented backend verifier capabilities | `lib/back/usecase/device.dart` |
| [GF-02165](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L296) | Decode and reject empty challenge bytes | `lib/back/usecase/device.dart` |
| [GF-02166](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L301) | Convert malformed challenges to a domain error | `lib/back/usecase/device.dart` |
| [GF-02169](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L77) | Record session restore outcomes without credential material | `lib/back/controller/auth.dart` |
| [GF-02170](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L106) | Record sign-in mode and outcome without tokens | `lib/back/controller/auth.dart` |
| [GF-02171](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L157) | Record Keycloak passkey action outcomes | `lib/back/controller/auth.dart` |
| [GF-02172](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L191) | Record refresh outcomes without token material | `lib/back/controller/auth.dart` |
| [GF-02173](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L701) | Record API method, redacted path, status and duration | `lib/back/repository/gorape.dart` |
| [GF-02174](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/passkey_device.dart#L56) | Record registration ceremony stages without credential payloads | `lib/back/usecase/passkey_device.dart` |
| [GF-02175](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/passkey_device.dart#L156) | Record possession ceremony stages without assertion payloads | `lib/back/usecase/passkey_device.dart` |
| [GF-02176](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt#L139) | Reject a software-backed Android device identity key | `android/app/src/main/kotlin/com/gorapeflutter/gf_app/MainActivity.kt` |
| [GF-02177](https://github.com/GorapeFlutter/gf-app/blob/main/platform/apple/SecureNativeKeyChannels.swift#L17) | Register Apple Secure Enclave Device key channel | `platform/apple/SecureNativeKeyChannels.swift` |
| [GF-02178](https://github.com/GorapeFlutter/gf-app/blob/main/platform/apple/SecureNativeKeyChannels.swift#L102) | Create P-256 keys locally in Secure Enclave and label non-attested boundary | `platform/apple/SecureNativeKeyChannels.swift` |
| [GF-02179](https://github.com/GorapeFlutter/gf-app/blob/main/platform/apple/SecureNativeKeyChannels.swift#L185) | Sign with a Secure Enclave key without exporting private material | `platform/apple/SecureNativeKeyChannels.swift` |
| [GF-02180](https://github.com/GorapeFlutter/gf-app/blob/main/windows/runner/windows_native_keys.cpp#L259) | Create a non-exportable P-256 key in Platform Crypto Provider | `windows/runner/windows_native_keys.cpp` |
| [GF-02181](https://github.com/GorapeFlutter/gf-app/blob/main/windows/runner/windows_native_keys.cpp#L298) | Sign through the TPM-backed CNG key provider | `windows/runner/windows_native_keys.cpp` |
| [GF-02182](https://github.com/GorapeFlutter/gf-app/blob/main/windows/runner/windows_native_keys.cpp#L417) | Register Windows Device CNG/TPM channel | `windows/runner/windows_native_keys.cpp` |
| [GF-02183](https://github.com/GorapeFlutter/gf-app/blob/main/linux/runner/linux_native_keys.cc#L325) | Create a TPM2 P-256 key and store only TPM-wrapped key blobs | `linux/runner/linux_native_keys.cc` |
| [GF-02184](https://github.com/GorapeFlutter/gf-app/blob/main/linux/runner/linux_native_keys.cc#L363) | Reload and sign with a TPM2 protected key | `linux/runner/linux_native_keys.cc` |
| [GF-02185](https://github.com/GorapeFlutter/gf-app/blob/main/linux/runner/linux_native_keys.cc#L466) | Register Linux TPM2 Device channel | `linux/runner/linux_native_keys.cc` |
