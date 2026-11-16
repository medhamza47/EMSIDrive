EMSIDrive - Windows + Android presentation

This ZIP runs independently from the original developer's computer.
The app, backend, Java runtime, Android USB tools and shared AI settings are included.
It is a team-only ZIP: .env.local contains the real shared AI keys.

BEFORE PRESENTATION DAY
1. Extract the entire ZIP to a normal folder, for example C:\EMSIDrive-Demo.
   Do not run START.cmd from inside the ZIP viewer.
2. Install Docker Desktop for Windows if necessary, finish its setup and open it.
   Use Linux containers. Restart Windows if Docker asks.
3. Enable Developer options and USB debugging on the Android phone.
   Connect with a data USB cable, unlock the phone and accept USB debugging.
4. Double-click START.cmd. On the first run, PostgreSQL downloads automatically.
   The script starts the database/API, installs the app and opens it.
5. Double-click CHECK-AI.cmd. It tests the actual AI service with the included
   sample-timetable.png. It should print PASS. Internet is required for the AI.
6. On the app, register a new @emsi-edu.ma account, import your real timetable,
   verify the detected classes, choose its validity dates and confirm it.
   Data persists on this computer across restarts.

ON PRESENTATION DAY
1. Open Docker Desktop, connect/unlock the phone and double-click START.cmd.
2. Keep the computer awake, internet connected and the USB cable attached.
3. Log in to the account created on THIS presentation database.
4. Run CHECK-AI.cmd once before the demonstration.

FEATURES
- The backend and app use the same source/configuration as the working developer setup.
- The database starts empty: accounts, timetables and rides from the developer's
  computer are not included. Create presentation accounts and rides beforehand.
- For two phones using the SAME presentation database, leave both connected and run:
  powershell -ExecutionPolicy Bypass -File Start-Presentation.ps1 -DeviceId PHONE_ID
  Find IDs with android\adb.exe devices. Run once for each phone.
- In this debug app, "Ajouter 3 trajets de test" can create clearly marked sample
  offers after you configure and confirm the timetable/travel preferences.
- Maps, route previews and AI need internet. AI quota is shared across the team;
  provider errors are still possible, so rehearse with your real timetable today.

TROUBLESHOOTING
- "unauthorized": unlock the phone and accept Allow USB debugging.
- No phone: use a data cable, turn USB debugging on; some manufacturers also
  require their Windows USB driver and an "Install via USB" phone setting.
- API errors: read api.log and api-error.log in this folder.
- Installation signing mismatch: uninstall the old app manually, then START.cmd.
  Uninstalling clears the phone's local login; server data remains.
- Port conflict: run Start-Presentation.ps1 -ApiPort 18081 -DatabasePort 15434.
  Use these same ports when starting again; CHECK-AI.ps1 also accepts -ApiPort.
- After unplugging/reconnecting USB, run START.cmd again to restore the USB link.
- Double-click STOP.cmd to stop the presentation backend/database without deleting data.

DEVELOPER SOURCE
The scripts in this folder can be committed to GitHub. The handoff folder and real
.env.local stay outside Git. Teammates can pull the source separately; this ZIP
lets them present without installing Flutter, Maven or a separate Java runtime.
