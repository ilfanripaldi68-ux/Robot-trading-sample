# Robot Trading App (simple)

This is a minimal Flutter project prepared for phone users.
It contains:
- Realtime simulated price chart (using fl_chart)
- Buttons to Force BUY / Force SELL and a Generate button (random)
- Notification on signal (flutter_local_notifications)

**Important note**: This repo intentionally *does not* contain `android/` and `ios/` folders.
The provided GitHub Actions workflow will run `flutter create .` on CI to generate platform folders before building the APK.
This lets you upload the code from your phone and still get an APK from GitHub Actions.

## How to use (phone-friendly)

1. Extract this zip on your phone.
2. Open and edit code using Acode or any code editor (optional).
3. Create a new GitHub repository (or use existing).
4. Upload all files and folders (including the `.github/` folder) to the GitHub repo root.
   - You can use GitHub mobile app or GitHub website (upload files).
5. Push to branch `main`.
6. The GitHub Actions workflow will run automatically and build the APK.
7. After workflow completes, go to the Actions tab > the run > Artifacts > download `app-release.apk`.

## Local testing (if you have PC)
If you have a PC with Flutter SDK:
- Run `flutter pub get`
- Run `flutter run` to test
- Or generate platforms with `flutter create .` then `flutter build apk`

## Disclaimer
This project simulates price data only for demo. Do not use it for real trading without adding proper data feeds, risk management and thorough testing.
