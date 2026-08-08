# Phone verification — setup

The app code is ready. What is missing is **Firebase project configuration**,
and one item in it is currently blocking phone verification *and* native Google
sign-in at the same time.

---

## 1. The blocker: no SHA fingerprints are registered

`android/app/google-services.json` currently contains:

```json
"oauth_client": [],
```

and no `certificate_hash` anywhere. That means Firebase does not know which app
signing certificate belongs to this project, so Google Play services refuses to
vouch for the app. Two consequences:

- **Native Google sign-in fails** with `DEVELOPER_ERROR` — this is the
  `GoogleApiManager` error in the run log.
- **Phone verification cannot work at all.** Firebase verifies that the request
  really comes from your app before it will verify a number. On Android that is
  done through Play Integrity, keyed on the SHA-256 of the signing certificate.
  Without it every attempt fails with `app-not-authorized`.

Silent, no-SMS verification depends on the same check, so this must be fixed
first regardless of which delivery path you end up using.

### Your debug fingerprints

Read from `~/.android/debug.keystore` on this machine:

```
SHA-1    8F:6D:5C:C0:BA:5E:14:F1:A9:66:B5:29:A0:CA:52:AF:52:61:49:F4
SHA-256  68:29:AC:B3:3F:20:A5:DA:60:6B:EE:73:E5:EC:87:21:F7:79:2E:B3:03:17:7D:09:24:6B:9A:C3:25:27:E9:E4
```

Regenerate at any time with:

```bash
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore \
  -storepass android -keypass android
```

### Steps

1. Firebase Console → ⚙ **Project settings** → **Your apps** → the Android app
   (`com.example.hisabET`).
2. **Add fingerprint** → paste the SHA-1. **Add fingerprint** again → paste the
   SHA-256. Both are needed: SHA-1 for Google sign-in, SHA-256 for Play
   Integrity.
3. **Download google-services.json** and replace
   `android/app/google-services.json`.
4. Confirm the new file has a non-empty `oauth_client` array and a
   `certificate_hash` entry. If it does not, the fingerprint did not save.
5. `flutter clean && flutter run`.

> A release build is signed with a **different** key, so it needs its own
> fingerprints added later. `android/app/build.gradle.kts` currently signs
> release with the debug key (`signingConfig = signingConfigs.getByName("debug")`),
> so for now the same two values cover both.

---

## 2. Enable the provider

Firebase Console → **Authentication** → **Sign-in method** → **Phone** →
enable.

---

## 3. Free testing without SMS

Two paths, both free.

### a. Fictional test numbers (works today, no billing)

Authentication → Sign-in method → Phone → **Phone numbers for testing**. Add
e.g. `+251911000001` with code `123456`. These never dispatch an SMS and are
not billed.

```bash
flutter run --dart-define=PHONE_AUTH_TESTING=true
```

Optionally pin one number so the code is filled in automatically:

```bash
flutter run \
  --dart-define=PHONE_AUTH_TESTING=true \
  --dart-define=PHONE_AUTH_TEST_NUMBER=+251911000001 \
  --dart-define=PHONE_AUTH_TEST_CODE=123456
```

`PHONE_AUTH_TESTING` calls `setSettings(appVerificationDisabledForTesting: true)`
in `lib/main.dart`, which **switches off device verification**. That is what
makes fictional numbers work — and it is also why it disables the silent
network path below. Use one or the other, never both.

### b. Silent verification on your own device (no SMS, no cost)

When the number being verified is the number of the device doing the
verifying, Play services can confirm it over the data connection and Firebase
returns a finished credential without sending anything. This is the
`verificationCompleted` callback, handled in
[otp_service.dart](lib/features/auth/data/services/otp_service.dart).

Requirements:

- SHA-256 registered (section 1).
- A recent Google Play services on the device, signed in to a Google account.
- **Do not** pass `PHONE_AUTH_TESTING` — it disables the very check this path
  needs.

```bash
flutter run
```

Phone auth is now **on by default**; the flag only exists to switch it off.

---

## 4. Real SMS

Since September 2024 Firebase requires the **Blaze** plan for SMS delivery to
real numbers. Neither test numbers nor silent verification send an SMS, so
neither is billed — but a real user on a number that is not their device's own
will need Blaze.

---

## 5. Where a token goes

There is exactly one place: `--dart-define` at run time, read in
`lib/main.dart`. Nothing secret is committed.

Which key it uses depends on what the token is, and the three candidates need
different wiring:

| If your token is… | Where it belongs | Extra work |
|---|---|---|
| **App Check debug token** (from the console's App Check tab, or printed by the app on first run) | `--dart-define=APP_CHECK_DEBUG_TOKEN=…` | needs the `firebase_app_check` package added and activated in `main.dart` |
| **reCAPTCHA / reCAPTCHA Enterprise site key** | `--dart-define=RECAPTCHA_SITE_KEY=…` | web only; Android uses Play Integrity instead |
| **A Play services / preview-program enrolment token** | nothing to add in code | it is a device-side enrolment, not an app credential |

Tell me which one it is — or paste the console screen it came from — and I will
wire it up. Do not paste the token into a file that is committed.

---

## 6. Unrelated, but worth knowing

`applicationId` is still `com.example.hisabET`. Google Play rejects any
`com.example.*` package. Changing it means re-registering the Android app in
Firebase and downloading a fresh `google-services.json`, so it is better done
deliberately and before the first release — not now, in the middle of feature
work.
