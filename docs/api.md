# API reference — 1.2.0

Core module `CaresoftVoice`; UI module `CaresoftVoiceUI`. Public client/call/event APIs are MainActor isolated. Objective-C callbacks/delegates also run on main. Swift errors are `VoiceError`; Objective-C errors use domain `CaresoftVoice`, numeric code 1 and stable `userInfo["voiceCode"]`, `operation`, `retryable`, optional `callId`. Do not branch on numeric code 1.

## Configuration

`VoiceOptions(domain:appId:apiBaseURL:installationId:appVersionCode:tokenProvider:iceServers:pushConfig:operationTimeoutMs:appName:credentialStore:pushBackend:)`.

| Field | Contract |
|---|---|
| domain, appId, installationId, appVersionCode | Nonempty strings, no CR/LF/NUL; install ID stable per install |
| apiBaseURL | HTTPS, host present, no URL username/password/fragment |
| tokenProvider | Sendable async throwing closure returning C2C token; no password fallback |
| iceServers | `[IceServer(urls:[String],username:String?,credential:String?)]`; stun/stuns/turn/turns only |
| pushConfig | `AppPushConfig(applicationId:environment:)`; environment sandbox/production |
| operationTimeoutMs | Default 15000; accepted 100...120000 |
| appName | Default Caresoft Voice; call PushKit start early with host display name |
| credentialStore | Optional `VoiceCredentialStore` async read/write/clear Data; defaults to Keychain |
| pushBackend | Optional `VoicePushBackend` async register/unregister with sensitive context; Swift customization |

## Client methods

| Method | Result / semantics |
|---|---|
| `init(options:) throws` | Reject second live client until dispose |
| `connect() async throws` | Shared authentication task; never changes availability/device |
| `checkSession() async throws -> SessionInfo` | Restore/check only, never calls tokenProvider |
| `getSnapshot() -> ClientSnapshot` | Synchronous state, safe fields only |
| `getActiveCall() -> VoiceCall?` | Reserved/new, ringing, connecting or active call; nil after ended |
| `getAvailability() async throws -> Availability` | Server read: available/unavailable/unknown |
| `setAvailability(DesiredAvailability) async throws` | ACK then agentStatus readback |
| `getCallDevice() async throws -> CallDevice` | browser/mobile/other/unknown |
| `selectCallDevice(SelectedCallDevice) async throws` | browser/mobile; blocked while call reserved |
| `checkReadiness() async throws -> Readiness` | auth/microphone/callUI/push/device; never requests permission |
| `registerPushToken(PushRegistration) async throws` | Scope validated; ready only after ACK |
| `unregisterPushToken(PushRegistration) async throws` | Exact prior registration, does not guess current token |
| `createCall(options:) throws -> VoiceCall` | Reserves sole slot; no dial until start |
| `receivePush([AnyHashable:Any]) async throws -> VoiceCall?` | Direct forwarding/test path; early report; duplicates return existing call, canceled/busy nil |
| `observe(handler) -> VoiceSubscription` | Keep subscription alive; cancel detaches observer only |
| `logout() async throws -> LogoutResult` | Both server steps attempted; local clear verified; active call blocks |
| `dispose() async` | Idempotent local cleanup; allows new client; does not logout server or erase saved session |

`SessionInfo`: status authenticated/unauthenticated/unknown, optional agent, reason, checkedAt. Agent has id (String), domain, email/displayName optional. A network error/403/5xx is not inferred revocation.

`ClientSnapshot`: clientId, session, connection (disconnected/connecting/connected/reconnecting/authRequired), availability, callDevice, readiness optional, activeCall optional. `reconnecting` is a reserved public enum case; automatic call recovery is not promised by this release.

`Readiness`: each dimension ready/blocked/unknown, checkedAt. Restored push token remains unknown until fresh registration ACK. Simulator callUI reports blocked.

`LogoutResult`: appSession and voiceSession confirmed/unconfirmed, localCredentials `cleared`, sanitized errors. Throw LOCAL_CLEANUP_FAILED if storage deletion cannot be verified.

## Call methods

`CallOptions(to:callerId:ticketId:)`: to permits +, digits, *, # (max 128); optional metadata rejects header injection. Caller ID maps to X-CalloutId, ticket to X-TicketID.

| Method | Behavior |
|---|---|
| `start()` | Outgoing/new only, shared start task; checks mobile + microphone |
| `answer()` | Incoming ringing/connecting only; shared task; resolves when the call is confirmed |
| `reject()` | Incoming only; local ended immediately, server rejection attempted even if call initialization is incomplete |
| `hangup()` | Local ended immediately; repeated end shares result |
| `setMuted(Bool)` | Local mute first; failure stays muted and native CallKit mute reflects local success, while server uncertainty is emitted. Unmute only active and after ACK |
| `setHeld(Bool)` | Active only; snapshot changes only after ACK; no local optimistic hold |
| `sendDTMF(String)` | Active, 1...128 characters 0-9/A-D/*/#; 100ms tone duration, 500ms gap |
| `getAudioRoutes()` | Real AVAudioSession route inventory; no invented Bluetooth device |
| `setAudioRoute(id:)` | Requires active audio and available route; OS may reject; use returned inventory |
| `getStats()` | Real media counters only; absent fields remain nil |
| `getSnapshot()` / `observe(handler)` | Safe current state and future events |

All call operations above except snapshot/observe are async throwing. `reject`/`hangup` return EndResult(localEnded, serverAcknowledged). Local completion is not proof of server acceptance. Check serverAcknowledged separately; sending an end request alone does not confirm server acceptance.

`CallSnapshot`: id (stable local UUID), direction, remote(number/displayName), serverCallId optional, state, mediaState, muted, held, endReason, createdAt, connectedAt, endedAt. States new/dialing/ringing/connecting/active/ended. Ended is terminal exactly once. Media states notStarted/connecting/connected/disconnected/failed.

End reasons: local-ended, remote-ended, rejected, missed, answered-elsewhere, canceled-elsewhere, auth-failed, connection-failed, busy, disposed.

`CallStats`: optional timestamp, packetsLost, jitterSeconds, roundTripTimeSeconds, bytesSent, bytesReceived. Jitter/RTT units seconds; timestamp remains absent until a supported conversion is implemented. No fabricated zero stats.

## Events and concurrency

ClientEvent: sessionChanged(SessionInfo), connectionChanged(ConnectionState), availabilityChanged(Availability), callDeviceChanged(CallDevice), readinessChanged(Readiness), incomingCall(VoiceCall), callRestored(VoiceCall), error(VoiceError).

CallEvent: stateChanged(CallSnapshot), mediaStateChanged(MediaState), mutedChanged(Bool), heldChanged(Bool), audioRoutesChanged([AudioRoute]), error(VoiceError).

EventMeta: clientId, optional callId, monotonic per-client sequence, Date timestamp. No unlimited replay; read snapshot, subscribe, then read snapshot again. CallKit native events arriving before client/payload are bounded and expire; end/cancel wins answer. View removal must only cancel its subscription.

Shared start/answer/connect tasks have operation lifetime. Canceling one caller does not imply canceling a shared call; use explicit hangup/dispose. Timeout cancels boundary wait without replaying a mutation. Native action failures may be observable on the call and client error streams; subscribe to the appropriate scope to avoid presenting two alerts.

## Push and security helpers

`CaresoftVoicePush.shared.start(appName:)`, `onToken`, `onInvalidated`, `token`, `receive(_:completion:)`. Start in AppDelegate before UI. Host already owning PKPushRegistry may forward instead. Never start two registries. Native report completion is one-shot.

Forward the complete push dictionary unchanged to the SDK. If the host receives a legacy JSON string, decode it into `[AnyHashable:Any]` before forwarding. The SDK validates the call identity, expiry and application scope, filters display metadata and handles duplicate/canceled calls. Do not construct or log call credentials.

`C2CTokenSigner.create(agentId:voiceAPIToken:expired:calloutId:)` throws, returns HS256 JWT. This does not authenticate the app; return result through tokenProvider. Never embed signing secret in a released client.

## Objective-C

Import `@import CaresoftVoice;`. `CSVoiceConfiguration` is an NSObject DTO with domain/appId/apiBaseURL/installationId/appVersionCode/appName/operationTimeoutMs/applicationId/environment/iceServers. ICE entries are NSDictionary with urls array and optional username/credential.

Use generated selector `initWithConfiguration:error:tokenProvider:`. Token provider receives a completion block; invoke once (duplicate completions are ignored), nil token/error maps AUTH_REQUIRED. Never block main while waiting for an SDK completion.

`CSVoiceClient` mirrors connect/checkSession/readiness/status/device/createCall/register/unregister/logout/dispose. Snapshot dictionaries preserve safe field names; optional fields absent, not fabricated. `CSVoiceClientDelegate` delivers event payload/meta and a CSVoiceCall for incoming/restored. Retain wrapper and weak delegate owner. `CSVoiceCall` mirrors start/answer/reject/hangup/mute/hold/DTMF/routes/stats and snapshot. CSVoiceCallDelegate handles call events. NSError carries safe code, not raw underlying error.

`CSVoicePush.startWithAppName:tokenChanged:invalidated:` or receive forwarding allows native bootstrap before client. Custom credential store/push backend hooks are Swift protocols in this release; Objective-C hosts can supply a small Swift adapter if needed. Built-in Keychain/configured APNs behavior works directly.

## UI

`VoiceCallView(call:)`, `VoiceCallViewController(call:)`, `VoiceCallViewModel(call:)` in CaresoftVoiceUI. ViewModel publishes snapshot/error/routes, provides perform and refreshRoutes; it never creates a client or owns call network lifecycle. UI is optional and its absence does not change calling behavior.

## Safe error codes

Error codes are strings exposed through VoiceError; do not interpret them as HTTP status codes. `retryable` is true only for NETWORK_UNAVAILABLE/TIMEOUT/SERVER_ERROR; this never grants permission to replay an already-sent mutation.

`AUDIO_NOT_ACTIVE`, `AUTH_REQUIRED`, `BACKEND_CONTRACT_REQUIRED`, `CALLKIT_FAILED`, `CALL_EXPIRED`, `CALL_IN_PROGRESS`, `CALL_MISMATCH`, `CLIENT_ALREADY_EXISTS`, `CLIENT_DISPOSED`, `DEVICE_NOT_MOBILE`, `INSECURE_ENDPOINT`, `INVALID_ARGUMENT`, `INVALID_PUSH`, `INVALID_PUSH_CONFIG`, `INVALID_RESPONSE`, `INVALID_SIP`, `INVALID_STATE`, `INVALID_STORED_SESSION`, `LOCAL_CLEANUP_FAILED`, `MEDIA_FAILED`, `MEDIA_NOT_READY`, `NETWORK_UNAVAILABLE`, `OPERATION_CANCELED`, `OPERATION_FAILED`, `OPERATION_IN_PROGRESS`, `PERMISSION_DENIED`, `SIP_ENGINE_ERROR`, `PUSH_NOT_REGISTERED`, `PUSH_SCOPE_MISMATCH`, `REQUEST_REJECTED`, `ROUTE_UNAVAILABLE`, `SERVER_ERROR`, `SIP_AUTH_UNSUPPORTED`, `SIP_REFRESH_FAILED`, `SIP_REGISTRATION_FAILED`, `SIP_REJECTED`, `STORAGE_FAILED`, `TIMEOUT`, `UNSUPPORTED_PLATFORM`
