# Assets — self-hosting plan

Phase 1 must not hotlink `lh3.googleusercontent.com` at runtime. Direct
download was attempted from this workstation and timed out, so Phase 1
renders brand/field/portrait roles with Material icons + monochrome
containers (same layout, no network images).

## Prototype → app mapping (to vendor in Phase 2)

| Role | Prototype source | Phase 1 stand-in | Vendor target |
|---|---|---|---|
| Brandmark | `01_splash_screen/code.html` aida-public brandmark img | `assets/images/brandmark.png` (vendored 176KB, wired in Splash) | done |
| Wheat hero (dashboard) | `07_home_dashboard` wheat seedlings bg | `AmCard` + `Icons.grass` | `app/assets/images/wheat_tillering.jpg` |
| Farmer portrait | `07_home_dashboard` + `20_profile_settings` Ramesh img | `CircleAvatar(Icons.person)` | `app/assets/images/farmer_sample.png` |
| Drone aerial (farm profile) | `05_farm_profile_setup` drone img | `AmCard` (no photo) | `app/assets/images/farm_aerial.jpg` |
| Scanner macro leaf | `13_crop_health_scanner` macro blade img | viewfinder placeholder box | `app/assets/images/leaf_macro.jpg` |
| Field/mist hero (forecast) | `09_detailed_weather_forecast` misty farm img | metric tiles only | `app/assets/images/field_mist.jpg` |

Local Stitch screenshots remain the visual reference in place at
`stitch_new_project_setup (1)/stitch_new_project_setup/*/screen.png`
(committed untouched) — no runtime dependency on them.

## Rules for Phase 2+

- Download each remote file once, verify MIME/extension/size, commit
  under `app/assets/images/`, register in `pubspec.yaml`.
- Never reference `lh3.googleusercontent.com` from Dart code.
