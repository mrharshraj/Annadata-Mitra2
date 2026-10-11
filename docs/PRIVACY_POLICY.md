# Privacy Policy — Annadata Mitra

**Effective date:** 2026-10-11 · **Version:** 1.0
**Published policy URL:** PENDING (deploy `docs/privacy.html` or website page and replace this line)
**Contact / grievance:** [SUPPORT EMAIL PLACEHOLDER] · [POSTAL ADDRESS PLACEHOLDER]

Annadata Mitra ("the App") is an AI-assisted farming companion for Indian
farmers. This policy describes what the App actually does in its current
implementation. It does not claim compliance by itself; review against the
Information Technology Act, 2000, the DPDP Act, 2023, and Google Play
policies before publication.

## 1. Information collected

- **Account:** email address (login/signup, OTP codes sent by email).
- **Profile:** full name, phone number (optional), preferred language,
  village/block/district/state linkage, avatar URL (optional).
- **Farm data:** field names, areas, soil type, notes, approximate
  coordinates you enter; crops planted with sowing/expected-harvest dates.
- **Tasks, advisories, AI chats:** to-do items, field context shared with
  the assistant, conversation transcripts.
- **Crop photos:** images you capture for health scans (stored privately,
  analyzed on request, never public).
- **Location:** only coordinates you enter or that your village record
  carries (used for weather mapping). The App does not run background
  location tracking.
- **Device/technical:** crash-safe diagnostics (request IDs, error codes);
  passwords, tokens and API keys are never logged.

## 2. How information is used

To authenticate you, sync your farm records, fetch weather for your area,
generate AI agronomy advice and scan results, and enforce that each farmer
sees only their own data (Row Level Security).

## 3. Sharing and processors

- **Supabase** (PostgreSQL/Auth/Storage): hosts account, farm and image data.
- **Open-Meteo**: receives village latitude/longitude only, returns weather.
- **Google Gemini**: receives your question plus farm context you provide
  (name, village, crop, weather summary) to generate advice and scan
  analysis. No advertising use.
- No sale of personal data. No other third parties in the current build
  (no analytics SDK, no ad SDK, no Firebase).

## 4. Storage, retention, deletion

- Data lives in your Supabase project region until you delete it.
- **Delete my data** (Profile screen): permanently deletes your profile row;
  fields, crops, tasks, scans and AI history cascade-delete with it, then
  signs you out. The authentication account itself is removed on request
  via the contact above (server-side operation).
- Backups, if enabled on the database, age out per provider policy.

## 5. Your rights

Access, correction, deletion, and grievance redressal via the contact
above. Deletion requests are honored within 30 days.

## 6. Security and limits

TLS in transit, RLS owner-policies, private storage prefixes, JWT-checked
backend, rate-limited AI endpoints. No system is impenetrable; report
abuse to the contact above.

## 7. Children

The App targets adult farmers; accounts for children under 13 require
verifiable parental consent — contact us and we will remove such data.

## 8. Changes

Material changes will be announced in-app with an updated effective date.
