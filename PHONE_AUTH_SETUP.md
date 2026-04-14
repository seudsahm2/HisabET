# Phone Auth Setup (HisabET)

This project uses Firebase Phone Authentication (not Supabase).

## 1. Required Firebase Console Setup

1. Open Firebase Console -> Authentication -> Sign-in method.
2. Enable Phone provider.
3. In Phone provider settings, allow your target SMS regions.
4. Open Project settings -> Your Android app (`com.example.hisabET`).
5. Add SHA-1 and SHA-256 fingerprints for the keystore you are using.
6. Download latest `google-services.json` and place it at `android/app/google-services.json`.

## 2. Android App Identity Check

These values must stay aligned:

- `android/app/build.gradle.kts`: `applicationId = "com.example.hisabET"`
- `android/app/google-services.json`: `package_name = "com.example.hisabET"`

If they differ, phone auth can fail with `app-not-authorized`.

## 3. Dev Test Numbers (No real SMS)

Use this during development to avoid quota/throttling:

1. Firebase Console -> Authentication -> Sign-in method -> Phone -> Phone numbers for testing.
2. Add test number and 6-digit code (for example `+251911000001` / `123456`).
3. Use those exact values in app during testing.

### Debug Test Mode (No SMS Billing)

This project supports a debug-only mode that disables app verification and allows
Firebase fictional phone login.

Run from project root:

```powershell
flutter run --dart-define=PHONE_AUTH_TESTING=true --dart-define=PHONE_AUTH_TEST_NUMBER=+251911000001 --dart-define=PHONE_AUTH_TEST_CODE=123456
```

Notes:

- Works only in debug mode (`kDebugMode`).
- Keep using fictional phone numbers configured in Firebase Console.
- Never use this mode in production builds.

### Manual OTP Bypass (No SMS request at all)

If Firebase still tries to send SMS due provider/region constraints, use manual bypass:

```powershell
flutter run --dart-define=PHONE_AUTH_TESTING=true --dart-define=PHONE_AUTH_MANUAL_BYPASS=true --dart-define=PHONE_AUTH_TEST_CODE=123456
```

Behavior:

- App does not call SMS API.
- OTP screen appears immediately.
- Enter the same test code (`PHONE_AUTH_TEST_CODE`) to continue.
- Uses anonymous sign-in for dev access.

Required Firebase setting for this path:

- Authentication -> Sign-in method -> Enable **Anonymous** provider.

### Optional Profile Gate Bypass (Development only)

If Firestore rules are still being configured, you can bypass profile checks temporarily:

```powershell
flutter run --dart-define=DEV_BYPASS_PROFILE_CHECK=true
```

This should only be used while developing and must be removed for production.

## 3.1 Firestore Rules Required For Profile Save

The profile save button writes to `users/{uid}`. Add rules like this:

```txt
rules_version = '2';
service cloud.firestore {
	match /databases/{database}/documents {
		match /users/{userId} {
			allow read, write: if request.auth != null && request.auth.uid == userId;
		}
	}
}
```

Without this, profile creation fails with `PERMISSION_DENIED`.

## 4. Common Error Meaning

- `invalid-phone-number`: wrong format. Use international format (example `+251911223344`).
- `app-not-authorized`: SHA-1/SHA-256 missing or wrong app package in Firebase.
- `captcha-check-failed`: Play Integrity/reCAPTCHA challenge failed.
- `too-many-requests` or `quota-exceeded`: retry later or use test numbers.
- `session-expired` / `invalid-verification-id`: request a new OTP and verify again.

## 5. Commands to Get SHA Fingerprints

Run in project root:

```powershell
cd android
./gradlew signingReport
```

Copy SHA-1 and SHA-256 from the `Variant: debug` section into Firebase Console.

## 6. Phone Input Rules in App

The app normalizes Ethiopian format:

- `09XXXXXXXX` -> `+2519XXXXXXXX`
- `9XXXXXXXX` -> `+2519XXXXXXXX`

It then validates E.164-style input before requesting OTP.

## 7. If OTP Still Fails

Collect and share these exact items:

1. Full error text shown in app.
2. Phone number format entered.
3. Whether device has Google Play Services.
4. Whether build is debug or release.
5. Confirmation that SHA-1 and SHA-256 were added for this package name.
