# Release Checklist — Annadata Mitra (Google Play)

## Build (done locally)

- [x] applicationId `in.annadatamitra.annadata_mitra`, version 1.0.0+1.
- [x] Upload keystore generated locally (`android/upload-keystore.jks`,
      ignored); `key.properties` (ignored) wires release signing with
      debug fallback. BACK UP both files outside this repo.
- [x] Release APK signed (apksigner-verified):
      `app/build/app/outputs/flutter-apk/app-release.apk` (54.18 MB).
- [x] Release AAB signed (keytool-verified, build via
      `gradlew bundleRelease`; flutter wrapper's NDK strip post-step
      fails on NDK 28 Windows toolchain — `ndk.debugSymbolLevel NONE`
      set, symbols optional for Play):
      `app/build/app/outputs/bundle/release/app-release.aab` (25.56 MB).
- [x] Permissions justified: INTERNET, CAMERA (scanner), LOCATION (plots).
- [x] Release APK + AAB built (paths/sizes recorded at commit time).

## Still manual (Play Console + store)

- [ ] Create app in Play Console; upload the AAB (not APK).
- [ ] Complete Data safety form: account email, farm/location/crop data,
      photos; processors Supabase/Open-Meteo/Gemini; no ads/analytics SDK.
- [ ] Link Privacy Policy URL (publish `docs/PRIVACY_POLICY.md` content
      first; URL currently PENDING).
- [ ] Store listing: screenshots (EN + Hindi), feature graphic, description.
- [ ] Content rating questionnaire; target-audience + children declaration.
- [ ] Roll out to internal testing first; verify OTP email delivery,
      camera, and offline behavior on real devices.
- [ ] Deploy backend to HTTPS and rebuild with `API_BASE_URL` before the
      production track (weather/AI/scanner need it).
- [ ] Create a NEW upload key backup + store password in a password
      manager; losing it locks future updates.
