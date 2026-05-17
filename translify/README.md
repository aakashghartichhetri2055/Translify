# Translify Mobile App

The mobile app for the Translify project. Uses the camera and microphone of the mobile device to capture input, and sends input to the backend to perform translation services. Once the backend returns the output, it will be displayed on the mobile device.

Built with Dart + Flutter framework.

Currently targeting Android only. IOS planned if time permits.

## Feature Roadmap

1. ~~Add basic screens for everything~~
   - ~~User authentication: login, signup~~, new user page
   - ~~Main landing page~~
   - ~~Camera translation page~~
   - ~~Conversation translation page~~
   - ~~Settings Page~~
   - ~~Add go_router package to facilitate pages~~
     2.~~ Add camera input functionality to Camera translation page~~
2. ~~Add microphone input functionality to Conversation translation page~~
3. ~~Add functionality to other pages~~
4. ~~Connect mobile app to backend server~~
5. Port app to IOS by adding necessary IOS specific code (planned)

## How to Run

1. Install the Flutter SDK for your device, either through the [recommended VSCode integration](https://docs.flutter.dev/install/quick), or [manually](https://docs.flutter.dev/install/manual). This will also install the Dart SDK as part of Flutter
   - Make sure to add Flutter to your PATH variables

2. Install Android Studio [here](https://developer.android.com/studio/install)

3. Set up the Android tooling described [here](https://docs.flutter.dev/platform-integration/android/setup)

4. Set up the appropriate Android device: either an emulated device through Android Studio, or a physical Android device that you connect to your computer, using the instructions [here](https://docs.flutter.dev/platform-integration/android/setup#set-up-devices)
   - Keep in mind that you may have to enable Developer options and Debugging on your physical Android device. Instructions on how to do so vary by device

5. Clone this repo to your local machine, and cd into translify

6. Install all necessary project packages with the following: `flutter pub get`

7. Run the following to see your list of devices: `flutter emulators && flutter devices`
   - Usually, you can start up emulated devices in Android Studio

8. Do the following to run the app on your chosen device: `flutter run -d <device_id>`
   - `device_id` is the second column of the previous step
