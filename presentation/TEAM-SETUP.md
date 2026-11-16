# Team presentation setup

For Windows and a USB-connected Android phone, use the prepared private
`EMSIDrive-Presentation.zip`. It includes the compiled app, backend, Java runtime,
Android USB tools and the working shared AI configuration. Extract it, open Docker
Desktop and double-click `START.cmd`. Run `CHECK-AI.cmd` before presenting.
See [README.txt](README.txt) for rehearsal steps and troubleshooting.

## Teammates pulling the source

1. Pull the exact team branch containing the current backend and mobile changes.
2. Extract the privately shared `EMSIDrive-Team-Config.zip` into the repository
   root. It supplies `backend/.env.local` with the actual team AI configuration.
3. Install Docker Desktop, Java 17+, Maven 3.9+ and Flutter with Dart 3.13.7 or
   newer compatible with `mobile/pubspec.yaml`. The working SDK here is Flutter
   3.47.8. Make sure an older Flutter SDK is not first on PATH.
4. Start the API from `backend/`:

   ```powershell
   docker compose up -d
   mvn spring-boot:run "-Dspring-boot.run.profiles=dev"
   ```

5. In another terminal, use your own phone ID from `adb devices`:

   ```powershell
   adb -s YOUR_PHONE_ID reverse tcp:8080 tcp:8080
   cd mobile
   flutter pub get
   flutter run -d YOUR_PHONE_ID --dart-define=API_BASE_URL=http://localhost:8080
   ```

If `adb` is not on PATH, use
`& "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe"` instead of `adb`.
Enable USB debugging and accept the phone's authorization prompt.

The local database starts empty. Register an `@emsi-edu.ma` account and prepare
the timetable and rides on the presentation computer before the demonstration.
Two phones using the same backend can test booking, notifications and chat with
two separate accounts. Separate computers have separate databases.

## Rebuilding the private presentation package

Build the current backend and a debug APK using `API_BASE_URL=http://localhost:8080`,
then run `scripts/package-presentation.ps1`. Override `-JavaHome` and `-AndroidSdk`
if the installed tools use different locations. The resulting `handoff/` folder
contains the real team configuration and is ignored by Git.
