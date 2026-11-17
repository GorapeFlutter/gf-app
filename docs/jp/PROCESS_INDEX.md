# 処理ステップID一覧

各GF IDは実装へリンクします。概要はソースコード内の英語コメントを掲載しています。

| GF ID | 概要 |
| --- | --- |
| [GF-02000](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L53) | Read and decode the locally persisted token set. |
| [GF-02001](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L60) | Remove malformed session data so it cannot be restored again. |
| [GF-02002](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L64) | Reuse the session directly while its access token is valid. |
| [GF-02003](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L68) | Refresh an expired session and persist the replacement. |
| [GF-02004](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L76) | Clear expired sessions that could not be refreshed. |
| [GF-02005](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L87) | Reject OIDC sign-in on platforms without an adapter. |
| [GF-02006](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L93) | Complete Authorization Code + PKCE with the identity provider. |
| [GF-02007](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L105) | Persist tokens before exposing the authenticated session. |
| [GF-02008](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L123) | Skip refresh when the platform or refresh token is unavailable. |
| [GF-02009](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L126) | Refresh tokens and persist the replacement session. |
| [GF-02010](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L139) | Attempt provider logout when a supported remote session exists. |
| [GF-02011](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/auth.dart#L149) | Always clear local credentials after remote logout handling. |
| [GF-02012](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L621) | Build the URI, JSON payload, and authentication headers. |
| [GF-02013](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L636) | Send the initial API request with Bearer credentials. |
| [GF-02014](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L646) | Refresh an expired access token at most once. |
| [GF-02015](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L654) | Retry the original request once with the refreshed token. |
| [GF-02016](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L664) | Decode a successful JSON response for the repository caller. |
| [GF-02017](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L672) | Convert non-success HTTP responses into app-level exceptions. |
| [GF-02018](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L704) | Dispatch the request using the selected HTTP verb. |
| [GF-02019](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L740) | Map transport timeouts to a user-facing network error. |
| [GF-02020](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L756) | Map client transport failures to a network error. |
| [GF-02021](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L770) | Prefer structured API error details when the body is JSON. |
| [GF-02022](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L781) | Add authentication guidance for rejected credentials. |
| [GF-02023](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L96) | Normalize and validate the display name before device work. |
| [GF-02024](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L106) | Check whether this platform can create an attested key. |
| [GF-02025](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L119) | Require a configured backend verifier before issuing a challenge. |
| [GF-02026](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L122) | Request a single-use registration challenge from Gorape. |
| [GF-02027](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L134) | Bind the decoded challenge to a newly generated OS key. |
| [GF-02028](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L151) | Submit the public key and attestation evidence for verification. |
| [GF-02029](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L174) | Persist the local key alias only after server verification. |
| [GF-02030](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L182) | Remove the generated key if registration does not complete. |
| [GF-02031](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L199) | Load and verify that this device owns the registered private key. |
| [GF-02032](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L213) | Request a fresh proof challenge and reject expired challenges. |
| [GF-02033](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L223) | Sign the raw challenge bytes inside the OS key store. |
| [GF-02034](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L234) | Submit the challenge reference and signature for verification. |
| [GF-02035](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L253) | Revoke the authoritative server-side device record first. |
| [GF-02036](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L257) | Best-effort delete the OS key, then remove its local record. |
| [GF-02037](https://github.com/GorapeFlutter/gf-app/blob/main/lib/app.dart#L47) | Resolve platform, saved connection settings, and auth state. |
| [GF-02038](https://github.com/GorapeFlutter/gf-app/blob/main/lib/app.dart#L53) | Keep the splash screen visible while settings are loading. |
| [GF-02039](https://github.com/GorapeFlutter/gf-app/blob/main/lib/app.dart#L57) | Surface settings errors with a retry action. |
| [GF-02040](https://github.com/GorapeFlutter/gf-app/blob/main/lib/app.dart#L78) | Route restored or signed-in sessions to the app shell. |
| [GF-02041](https://github.com/GorapeFlutter/gf-app/blob/main/lib/app.dart#L89) | Build the login screen with platform support and settings. |
| [GF-02042](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/device.dart#L109) | Run the registration use case and retain its result. |
| [GF-02043](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/device.dart#L113) | Refresh the project device list and local key view. |
| [GF-02044](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/device.dart#L147) | Complete proof verification through the device use case. |
| [GF-02045](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/device.dart#L151) | Refresh attestation history and device verification status. |
| [GF-02046](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/device.dart#L178) | Revoke the device and let the use case clean up local keys. |
| [GF-02047](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/device.dart#L182) | Invalidate every provider that exposes revoked-device data. |
| [GF-02048](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L81) | Create the group through the application use case. |
| [GF-02049](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L85) | Refresh the project's group list after creation. |
| [GF-02050](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L97) | Persist the edited group through the application use case. |
| [GF-02051](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L101) | Refresh the project's group list after editing. |
| [GF-02052](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L109) | Delete the group on the backend. |
| [GF-02053](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L111) | Invalidate the group and its membership data. |
| [GF-02054](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L125) | Add the device to the backend group membership. |
| [GF-02055](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L129) | Reload the membership list after assignment. |
| [GF-02056](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L142) | Remove the device from the backend group membership. |
| [GF-02057](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/group.dart#L146) | Reload the membership list after removal. |
| [GF-02058](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/role.dart#L131) | Create a project role binding in Gorape. |
| [GF-02059](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/role.dart#L133) | Refresh the project's role-binding list. |
| [GF-02060](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/role.dart#L140) | Delete a project role binding in Gorape. |
| [GF-02061](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/role.dart#L144) | Refresh the project's role-binding list. |
| [GF-02062](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/role.dart#L155) | Create a group role binding in Gorape. |
| [GF-02063](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/role.dart#L159) | Refresh the group's role-binding list. |
| [GF-02064](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/role.dart#L174) | Delete a group role binding in Gorape. |
| [GF-02065](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/role.dart#L178) | Refresh the group's role-binding list. |
| [GF-02066](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/connection.dart#L29) | Start from platform-specific runtime defaults. |
| [GF-02067](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/connection.dart#L31) | Prefer locally saved settings when they can be decoded. |
| [GF-02068](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/connection.dart#L36) | Reject saved settings that omit the required OIDC scope. |
| [GF-02069](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/connection.dart#L73) | Validate all URLs and OIDC fields before persistence. |
| [GF-02070](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/connection.dart#L81) | Persist the validated connection configuration securely. |
| [GF-02071](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/connection.dart#L88) | Remove overrides and return the platform defaults. |
| [GF-02072](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/language.dart#L17) | Restore the saved language, defaulting to Japanese. |
| [GF-02073](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/language.dart#L26) | Accept only the languages supported by the app. |
| [GF-02074](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/language.dart#L30) | Persist the selected language and update reactive UI state. |
| [GF-02075](https://github.com/GorapeFlutter/gf-app/blob/main/lib/entity/model/role.dart#L157) | Normalize Keycloak user attributes before resolving roles. |
| [GF-02076](https://github.com/GorapeFlutter/gf-app/blob/main/lib/entity/model/role.dart#L159) | Collect realm and client roles from token claims. |
| [GF-02077](https://github.com/GorapeFlutter/gf-app/blob/main/lib/entity/model/role.dart#L173) | Resolve cluster-wide role claims and role-name fallbacks. |
| [GF-02078](https://github.com/GorapeFlutter/gf-app/blob/main/lib/entity/model/role.dart#L184) | Build project-specific roles from maps and user attributes. |
| [GF-02079](https://github.com/GorapeFlutter/gf-app/blob/main/lib/entity/model/role.dart#L212) | Build group-specific roles from maps and user attributes. |
| [GF-02080](https://github.com/GorapeFlutter/gf-app/blob/main/lib/entity/model/role.dart#L241) | Interpret group paths that also encode authorization roles. |
| [GF-02081](https://github.com/GorapeFlutter/gf-app/blob/main/lib/entity/model/role.dart#L275) | Publish one immutable role snapshot for UI access decisions. |
| [GF-02082](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/driver/flutter/FlutterDeviceKeyChannelDriver.kt#L35) | Selects the operation and validates its required arguments. |
| [GF-02083](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/driver/flutter/FlutterDeviceKeyChannelDriver.kt#L48) | Decodes the registration challenge before key creation. |
| [GF-02084](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/driver/flutter/FlutterDeviceKeyChannelDriver.kt#L56) | Decodes proof bytes before asking Keystore to sign. |
| [GF-02085](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/driver/devicekey/AndroidDeviceKeyDriver.kt#L28) | Detects StrongBox and hardware-backed Keystore availability. |
| [GF-02086](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/driver/devicekey/AndroidDeviceKeyDriver.kt#L32) | Returns support status and the effective security level. |
| [GF-02087](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/driver/devicekey/AndroidDeviceKeyDriver.kt#L45) | Removes a stale alias before generating its replacement. |
| [GF-02088](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/driver/devicekey/AndroidDeviceKeyDriver.kt#L48) | Prefers StrongBox and falls back to the device TEE. |
| [GF-02089](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/driver/devicekey/AndroidDeviceKeyDriver.kt#L52) | Requires a certificate chain from Android Key Attestation. |
| [GF-02090](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/driver/devicekey/AndroidDeviceKeyDriver.kt#L55) | Packages the public key, evidence chain, and security level. |
| [GF-02091](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/driver/devicekey/AndroidDeviceKeyDriver.kt#L101) | Binds signing, SHA-256, and the server challenge to the key. |
| [GF-02092](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/driver/devicekey/AndroidDeviceKeyDriver.kt#L116) | Generates the key pair inside Android Keystore. |
| [GF-02093](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/driver/devicekey/AndroidDeviceKeyDriver.kt#L67) | Loads the private-key entry by its local Keystore alias. |
| [GF-02094](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/driver/devicekey/AndroidDeviceKeyDriver.kt#L71) | Signs the raw challenge using SHA256withECDSA. |
| [GF-02095](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/driver/devicekey/AndroidDeviceKeyDriver.kt#L73) | Returns the ASN.1/DER signature as unpadded Base64url. |
| [GF-02096](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/register_device_screen.dart#L272) | Reset form errors and mark registration as in progress. |
| [GF-02097](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/register_device_screen.dart#L280) | Invoke the WebAuthn device-registration ceremony for this platform. |
| [GF-02098](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/register_device_screen.dart#L288) | Present the verified device details and assurance level. |
| [GF-02099](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/register_device_screen.dart#L332) | Notify the parent and clear the submitted device name. |
| [GF-02100](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/register_device_screen.dart#L336) | Keep registration failures visible in the form. |
| [GF-02101](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/register_device_screen.dart#L344) | Restore the form's idle state after every outcome. |
| [GF-02102](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L304) | Clear the previous action error and lock duplicate submissions. |
| [GF-02103](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L312) | Run the WebAuthn assertion ownership proof. |
| [GF-02104](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L320) | Report verified proof and reload device evidence. |
| [GF-02105](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L326) | Surface proof failures in the device detail screen. |
| [GF-02106](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L334) | Release the action lock after success or failure. |
| [GF-02107](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L346) | Require explicit confirmation before irreversible revocation. |
| [GF-02108](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L371) | Clear old errors and mark the revoke action as active. |
| [GF-02109](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L379) | Revoke the backend record and clean up the local key. |
| [GF-02110](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L384) | Notify the user and close the revoked device detail. |
| [GF-02111](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L390) | Keep revocation failures on the current screen. |
| [GF-02112](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/device_detail_screen.dart#L398) | Release the action lock after success or failure. |
| [GF-02113](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L386) | Clear feedback state and mark settings as saving. |
| [GF-02114](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L395) | Validate and persist connection settings through the controller. |
| [GF-02115](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L398) | Confirm the saved settings to the user. |
| [GF-02116](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L403) | Display validation or persistence errors. |
| [GF-02117](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L410) | Clear the saving state for every outcome. |
| [GF-02118](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L421) | Start reset feedback and prevent concurrent settings actions. |
| [GF-02119](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L430) | Remove the saved override and load platform defaults. |
| [GF-02120](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L434) | Synchronize all text fields with the reset configuration. |
| [GF-02121](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L441) | Confirm that defaults have been restored. |
| [GF-02122](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L446) | Display reset failures without discarding the form. |
| [GF-02123](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L453) | Clear the saving state for every outcome. |
| [GF-02124](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L464) | Start the health check and clear stale results. |
| [GF-02125](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L473) | Query the configured Gorape endpoint. |
| [GF-02126](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L476) | Format and show the health response. |
| [GF-02127](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L485) | Display health-check transport or API errors. |
| [GF-02128](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/settings_screen.dart#L492) | Clear the health-check progress state. |
| [GF-02129](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L361) | Collect group edits and stop when the dialog is cancelled. |
| [GF-02130](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L369) | Persist the group changes through the group controller. |
| [GF-02131](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L378) | Replace local group state and report the successful update. |
| [GF-02132](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L397) | Confirm the irreversible group deletion with the user. |
| [GF-02133](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L427) | Delete the group through the group controller. |
| [GF-02134](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L432) | Close the detail view after successful deletion. |
| [GF-02135](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L447) | Find active devices that are not already assigned. |
| [GF-02136](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L468) | Ask the user to choose one eligible device. |
| [GF-02137](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L476) | Add the selected device to the group's backend membership. |
| [GF-02138](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L494) | Mark the group membership change as active. |
| [GF-02139](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L500) | Remove the device from the backend group membership. |
| [GF-02140](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L518) | Collect the subject and role to grant. |
| [GF-02141](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L526) | Persist the group role binding through the role controller. |
| [GF-02142](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L551) | Mark the role-binding change as active. |
| [GF-02143](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_detail_screen.dart#L557) | Delete the selected group role binding in Gorape. |
| [GF-02144](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L355) | Collect group details and stop when the dialog is cancelled. |
| [GF-02145](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L363) | Create the group and show the outcome in project management. |
| [GF-02146](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L386) | Collect the subject and role to grant. |
| [GF-02147](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L394) | Persist the project role binding through the role controller. |
| [GF-02148](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L418) | Mark the role-binding change as active. |
| [GF-02149](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L424) | Delete the selected project role binding in Gorape. |
| [GF-02150](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L442) | Confirm the irreversible device revocation. |
| [GF-02151](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/project_management_screen.dart#L472) | Revoke the device and clean up any local key record. |
| [GF-02152](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_management_screen.dart#L128) | Collect group details and stop when the dialog is cancelled. |
| [GF-02153](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_management_screen.dart#L136) | Create the group and retain its server-generated record. |
| [GF-02154](https://github.com/GorapeFlutter/gf-app/blob/main/lib/ui/screens/group_management_screen.dart#L144) | Confirm creation and open the new group's detail screen. |
| [GF-02155](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L99) | Enter loading state before starting the provider interaction. |
| [GF-02156](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L108) | Call the use case and publish the restored session. |
| [GF-02157](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L118) | Preserve expected application errors for the UI. |
| [GF-02158](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L136) | Wrap unexpected provider errors as authentication failures. |
| [GF-02159](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L171) | Reuse an in-flight refresh to prevent duplicate token requests. |
| [GF-02160](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L174) | Start one refresh and clear the in-flight marker afterward. |
| [GF-02161](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L240) | Clear rejected credentials before publishing the auth error. |
| [GF-02162](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L791) | Attach attestation-specific guidance to validation failures. |
| [GF-02163](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L800) | Explain that backend role bindings govern forbidden actions. |
| [GF-02164](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L272) | Accept only the implemented verifier state for this platform. |
| [GF-02165](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L296) | Decode and reject empty challenge bytes. |
| [GF-02166](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/device.dart#L301) | Convert malformed server challenges to a domain error. |
| [GF-02167](https://github.com/GorapeFlutter/gf-app/blob/main/lib/app.dart#L100) | Starts Keycloak OIDC login and requires a passkey AMR. |
| [GF-02168](https://github.com/GorapeFlutter/gf-app/blob/main/lib/app.dart#L104) | Starts Keycloak's passkey registration AIA. |
| [GF-02169](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L73) | Record the outcome of restoring the stored authentication session. |
| [GF-02170](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L102) | Record sign-in mode and completion without logging tokens. |
| [GF-02171](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L153) | Record the Keycloak passkey action without credential data. |
| [GF-02172](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/controller/auth.dart#L187) | Record refresh outcomes without logging token material. |
| [GF-02173](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/repository/gorape.dart#L701) | Record HTTP outcome metadata without headers or body content. |
| [GF-02174](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/passkey_device.dart#L56) | Record passkey ceremony stages without credential payloads. |
| [GF-02175](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/passkey_device.dart#L156) | Record possession ceremony stages without assertion payloads. |
| [GF-02176](https://github.com/GorapeFlutter/gf-app/blob/main/android/app/src/main/kotlin/com/gorapeflutter/gf_app/driver/devicekey/AndroidDeviceKeyDriver.kt#L134) | Rejects software-backed device identity keys before returning evidence. |
| [GF-02177](https://github.com/GorapeFlutter/gf-app/blob/main/platform/apple/SecureNativeKeyChannels.swift#L18) | Registers the Secure Enclave channel for Device keys. |
| [GF-02178](https://github.com/GorapeFlutter/gf-app/blob/main/platform/apple/SecureNativeKeyChannels.swift#L112) | Creates a non-exportable P-256 Secure Enclave key and labels its attestation boundary. |
| [GF-02179](https://github.com/GorapeFlutter/gf-app/blob/main/platform/apple/SecureNativeKeyChannels.swift#L198) | Signs data with a validated Secure Enclave key without exporting private material. |
| [GF-02180](https://github.com/GorapeFlutter/gf-app/blob/main/windows/runner/windows_native_keys.cpp#L281) | Creates a non-exportable P-256 key in the TPM-backed CNG provider. |
| [GF-02181](https://github.com/GorapeFlutter/gf-app/blob/main/windows/runner/windows_native_keys.cpp#L321) | Signs a Device payload through the TPM-backed CNG key. |
| [GF-02182](https://github.com/GorapeFlutter/gf-app/blob/main/windows/runner/windows_native_keys.cpp#L443) | Installs the Device key channel using the Windows Platform Crypto Provider. |
| [GF-02183](https://github.com/GorapeFlutter/gf-app/blob/main/linux/runner/linux_native_keys.cc#L345) | Creates a TPM2 P-256 key with challenge in creation data and stores only TPM-wrapped blobs. |
| [GF-02184](https://github.com/GorapeFlutter/gf-app/blob/main/linux/runner/linux_native_keys.cc#L384) | Reloads the TPM-protected key blob and signs without exporting private key material. |
| [GF-02185](https://github.com/GorapeFlutter/gf-app/blob/main/linux/runner/linux_native_keys.cc#L493) | Installs the Linux Device key channel backed by TPM2 tools only. |
| [GF-02186](https://github.com/GorapeFlutter/gf-app/blob/main/lib/back/usecase/connection.dart#L39) | Migrate legacy local API and issuer defaults to the gorapeflutter.site domain. |
