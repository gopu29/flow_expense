# Agent Working Notes

Short, current facts for any agent. Read this before exploring the code, and keep it short.

## Working with the user
- Do not build or test on the phone after each change. Batch the corrections and install only when the user says "test" or "install".
- Before installing, run `flutter analyze` and `flutter test`.
- Keep replies and tool use lean. Read the phone screen as text first, and use screenshots only when the layout matters.
- Build features from what the app does. Never decompile or copy another app's code or assets.

## Machine setup (Windows)
- Flutter 3.47.7: `C:\Users\USER\develop\flutter\bin`. JDK 17: `C:\Users\USER\develop\jdk-17`.
- Android SDK: `%LOCALAPPDATA%\Android\Sdk`. adb is at `platform-tools\adb.exe`.
- Builds need `JAVA_TOOL_OPTIONS=-Djava.net.preferIPv6Addresses=true`, because the network is IPv6-only.
- Phone: Galaxy S21 FE, serial `RZCX10V25NJ`, package `com.example.flow_expense`.
- `flutter pub get` rewrites 3 `windows/flutter/*` files with line-ending noise. Run `git checkout -- windows/flutter` before committing.

## Commands
```bash
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell uiautomator dump /sdcard/ui.xml && adb shell cat /sdcard/ui.xml
```
- Read the screen as text with the `uiautomator` command above, then grep `text=` and `content-desc=`.

## Git
- No global git identity. Commit with `-c user.name="GOPU\Gopu" -c user.email=govindagopuucc@gmail.com`.
- Push works non-interactively with `GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never git push origin main`.

## App facts
- Sub-category transactions store the sub-category id in `categoryId`. Summary and Budget roll them up to the parent.
- User preferences live in `shared_preferences`, for example `visibleEntryFieldsProvider`.
- Voice Logger and Receipt Scanner are simulated with sample data and have no entry point. They are skipped until real speech and OCR exist.
- Test data still on the phone: sub-categories Sub1–Sub7 under Food, and a ₹50 "Lunch" transaction. The user chose to keep these for now.
