# Run InvoiceFlow on another machine

InvoiceFlow is a Flutter Android app. Its current data is local dummy data; no backend or API credentials are needed.

## 1. Install the tools

Install:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) and add its `bin` folder to your `PATH`.
- [Git](https://git-scm.com/downloads).
- [Android Studio](https://developer.android.com/studio), including the Android SDK, Android SDK Platform-Tools, and Android Emulator.

In Android Studio, open **Tools → Device Manager**, create a virtual device (for example, a Pixel device), and download an Android system image when prompted.

## 2. Clone the repository

The repository is private, so sign in with an authorized GitHub account first. With GitHub CLI:

```bash
gh auth login
gh repo clone itssmfaisal/invoice-flow
cd invoice-flow
```

Or clone it with Git after setting up GitHub authentication:

```bash
git clone https://github.com/itssmfaisal/invoice-flow.git
cd invoice-flow
```

## 3. Check the Android setup

Run these commands in a terminal from the project folder. Accept the Android SDK licenses when asked:

```bash
flutter doctor --android-licenses
flutter doctor
```

If `flutter doctor` reports missing Android SDK components, install them from **Android Studio → SDK Manager**.

## 4. Start the emulator and app

Start the virtual device from **Android Studio → Tools → Device Manager**, then run:

```bash
flutter pub get
flutter devices
flutter run -d <device-id>
```

Replace `<device-id>` with the Android emulator ID shown by `flutter devices` (for example, `emulator-5554`). To list Flutter-managed emulators, run `flutter emulators`; to start one from the terminal, run `flutter emulators --launch <emulator-id>`.

The first Android build may take a few minutes while Gradle downloads build dependencies. While `flutter run` is active, press `r` in its terminal for hot reload or `q` to stop the app.
