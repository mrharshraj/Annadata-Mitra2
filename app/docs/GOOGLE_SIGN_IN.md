# Google Sign-In Setup

Annadata Mitra uses native Google Sign-In on Android and exchanges the Google
ID token with Supabase Auth. No Google client secret, Supabase service-role key,
or Supabase JWT secret belongs in Flutter.

## Flutter build values

Keep the existing Supabase public configuration and add the Google web OAuth
client ID:

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<supabase-publishable-anon-key> \
  --dart-define=GOOGLE_WEB_CLIENT_ID=<web-oauth-client-id>
```

`GOOGLE_ANDROID_CLIENT_ID` is optional. The app passes it to the Google SDK
when supplied, but the required token audience for Supabase is the web client
ID in `GOOGLE_WEB_CLIENT_ID`.

## Google Cloud Console

Use the package name:

```text
in.annadatamitra.annadata_mitra
```

Configure:

1. OAuth consent screen for the app.
2. Android OAuth client for the package above.
3. SHA-1 and SHA-256 fingerprints for every signing key used to install the
   app: debug, upload, and Play app-signing if applicable.
4. Web OAuth client. Use its client ID as `GOOGLE_WEB_CLIENT_ID`.

Useful fingerprint commands:

```bash
cd app/android
./gradlew signingReport
```

For the local release upload key, inspect `android/key.properties` locally and
run `keytool -list -v -keystore <storeFile> -alias <keyAlias>`. Do not commit
the keystore or passwords.

## Supabase Dashboard

Enable Authentication -> Providers -> Google and set:

- Client ID: the same web OAuth client ID used for `GOOGLE_WEB_CLIENT_ID`.
- Client Secret: the web OAuth client secret from Google Cloud. This stays only
  in Supabase, never in Flutter or Git.

The app uses `signInWithIdToken(provider: OAuthProvider.google, idToken: ...)`,
so no fake account picker or password fallback is involved in the primary
Android flow.

## Failure checklist

- `Google sign-in is not configured.` means `GOOGLE_WEB_CLIENT_ID` was not
  provided at build/run time.
- `Google OAuth client configuration is invalid.` usually means the Android
  package name or signing fingerprint is missing or wrong in Google Cloud.
- Supabase Auth errors usually mean the Google provider is disabled or the web
  client ID/secret in Supabase does not match the Google project.
