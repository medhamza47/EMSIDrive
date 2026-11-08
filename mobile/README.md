# EMSIDrive Mobile

Flutter application for EMSIDrive, the carpooling platform for EMSI Marrakech
students. UI text is French; code, comments and tests are English.

## Requirements

- Flutter 3.47+ / Dart 3.13+
- Android SDK 23+ (required by `flutter_secure_storage`)

## Setup

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build
```

Re-run `build_runner` after adding or changing a `@riverpod` provider.

## Run

```bash
# Android emulator (default API host is http://10.0.2.2:8080)
flutter run

# Point the app at another backend
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8080
```

## Quality gates

```bash
flutter analyze
flutter test
```

## Structure

```
lib/
  app.dart          MaterialApp.router, locale, themes
  main.dart         ProviderScope bootstrap
  core/
    constants/      API base URL, timeouts, storage keys
    errors/         AppFailure hierarchy + DioException mapping
    network/        Dio and secure storage providers
    router/         go_router configuration and AppTab enum
    theme/          EMSI colours, spacing, radius, typography, themes
  features/
    <feature>/presentation/   screens
  l10n/             ARB sources (fr) and generated localizations
  shared/widgets/   reusable design-system widgets
```

Feature folders follow `lib/features/<feature>/{presentation,application,data}`.
Only `presentation` exists so far: navigation placeholders are in place, business
features land in later sprints.

## Theme

Material 3, built from an explicit `ColorScheme` so the brand hexes stay exact:

| Token | Value |
|---|---|
| Primary (EMSI dark green) | `#015629` |
| Secondary / accent (EMSI light green) | `#7ECC18` |

Success, warning and info colours live in the `AppSemanticColors` theme
extension, reachable through `Theme.of(context).semanticColors`.

## Localization

Never hardcode French strings in widgets. Add a key to
`lib/l10n/app_fr.arb`, run `flutter gen-l10n`, then use
`AppLocalizations.of(context)!.keyName`.

## Marrakech ride map

The mobile form requires one EMSI campus and one point inside Marrakech or
Méchouar-Kasba. The boundaries in `assets/maps/marrakech.geojson` come from
[Communes du Maroc](https://communes.pages.dev/fr/docs/api/) and use
[OpenStreetMap data under ODbL](https://www.openstreetmap.org/copyright).
Campus pins are based on the [EMSI contact page](https://emsi.ma/contact/).
The Targa label uses the published Guéliz pin provisionally.

The development build uses OpenStreetMap tiles and the public OSRM demo.
`MAP_TILE_URL` and `ROUTING_BASE_URL` can be set with `--dart-define` to
use a different tile service or OSRM instance. When a student requests a
route preview, the routing service receives the two selected coordinates.
