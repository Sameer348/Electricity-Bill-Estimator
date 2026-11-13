# Electricity Bill Estimator

Offline Flutter app that estimates monthly electricity bills in Pakistan from
units consumed (kWh), using configurable tariff slabs, taxes and surcharges.

> This is an **estimator**, not an official WAPDA/DISCO billing system. Rates
> are estimates and may change.

## Features

- Bill calculator for residential and commercial connections, with input validation
- Result screen showing slab breakdown, energy charges, additional charges, taxes, total and cost per unit
- Save estimates to history and share them as text
- Appliance calculator with 8 presets (fan, LED bulb, refrigerator, TV, iron, washing machine, AC, water pump)
- History with delete, undo and clear-all
- Settings for English/Urdu (right-to-left), theme (system/light/dark), default connection type, tariff editor and about
- No login, no internet, no runtime permissions; everything is stored on the device

## Project structure

```
lib/
  main.dart                 Startup: loads stored data, runs app
  app.dart                  MaterialApp, themes, locales
  core/                     Strings (EN/UR), theme, formatters, validators, app info
  data/                     Default tariffs and appliance presets
  models/                   TariffConfig, BillResult, SavedEstimate, AppSettings, Appliance
  services/
    bill_calculator.dart    Pure calculation engine (no hard-coded rates)
    storage_service.dart    SharedPreferences persistence (JSON)
  state/                    AppController (ChangeNotifier) + AppScope
  screens/                  Home, Result, Appliances, History, Settings, Tariff editor
  widgets/                  Shared UI components
test/                       Engine, validation, persistence and widget tests
store/                      Play Store listing text
assets/branding/            Icon source (SVG) and 512px Play Store icon
```

## Updating tariff rates

All rates live in `TariffConfig` objects.

- **For everyone (next release):** edit `lib/data/default_tariffs.dart`.
- **On a single device:** Settings → Manage tariff rates. User edits are saved
  locally and override the defaults until reset.

Each tariff has:

- **Slabs:** upper unit limits with a rate per unit. The last slab is open-ended.
- **Slab mode:** `progressive` (each rate applies only to the units inside its
  slab) or `singleSlab` (all units are charged at the rate of the slab reached).
- **Fixed monthly charge.**
- **Charges:** each has a name, a basis (fixed amount, per unit, % of energy or
  % of subtotal) and a flag for whether it counts as a tax.

Order of calculation: energy → fixed → non-tax charges → taxes. For taxes,
"% of subtotal" means % of energy + fixed + non-tax charges.

The bundled default rates are illustrative samples. Check them against a
current NEPRA notification or DISCO bill before release.

## Run and test

```bash
flutter pub get
flutter test
flutter run
```

## Release build

1. **Application ID:** replace the placeholder `pk.billestimator.app` in
   `android/app/build.gradle.kts` (`namespace` and `applicationId`), and move
   `MainActivity.kt` to match. The ID cannot change after the first upload.
2. **Version:** `version: 1.0.0+1` in `pubspec.yaml` (name+code). Also update
   `lib/core/app_info.dart`. Increase the `+N` code for every upload.
3. **Signing:** create an upload keystore:
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   Then copy `android/key.properties.example` to `android/key.properties` and
   fill it in. Both files are git-ignored. Without the file, release builds fall
   back to debug signing, which the Play Store rejects.
4. **Build:**
   ```bash
   flutter build appbundle --release   # Upload to Play Console
   flutter build apk --release         # For sideload testing
   ```

R8 code shrinking and resource shrinking are enabled for release builds.

## Icon and splash

- The launcher icon is an adaptive icon (gradient background + vector bolt,
  with a monochrome layer for themed icons). Legacy PNGs for Android 7.x are in
  `mipmap-*`.
- The splash screen uses the Android 12+ splash API (`values-v31/styles.xml`)
  and a layer-list for older versions.
- To rebrand, replace `assets/branding/` and the `ic_bolt` /
  `ic_launcher_background` drawables. The icon is a placeholder design.

## Privacy

The app declares no permissions (the merged manifest contains only AndroidX's
internal non-exported receiver permission). It makes no network calls and
disables Android backup, so data stays on the device. For the Play Console
Data safety form, answer **"No data collected or shared."**
