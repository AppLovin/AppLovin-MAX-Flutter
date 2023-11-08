# AppLovin MAX Flutter Plugin
AppLovin MAX Flutter Plugin for Android and iOS.

## Documentation
Check out our integration docs [here](https://dash.applovin.com/documentation/mediation/flutter/getting-started/integration).

## Downloads
See [pub.dev](https://pub.dev/packages/applovin_max) for the latest releases of the plugin.

## Demo App Instructions
To get started with the demo app, please ensure Flutter is installed on your system. Once everything is properly installed, follow the instructions below to get the demo application up and running. 

1. Update the `SDK_KEY` and ad unit IDs in the `main.dart` file. 
2. Update the package name from `com.applovin.enterprise.apps.demoapp` to one that matches your ad units. Be sure to do this for every package name reference in the demo app. 

### Android
#### 1. Adding Adapters to `build.gradle`:
- Navigate to your Flutter project directory in your file explorer or terminal. 
- Within the project directory, navigate to `android/app/` to find the `build.gradle` file. 
- Open `build.gradle` with a text editor or an IDE. 
- Add the adapters you need under dependencies, as the documentation specifies. It will look something like this: 
```
dependencies {
    // Other dependencies...
    implementation 'com.example.adapter:version'
}
```

#### 2. Updating `AndroidManifest.xml` with `meta-data` (if required):
- Within the `android/app/` directory, locate and open the `AndroidManifest.xml` file. 
- If the network adapter you add requires `meta-data`, insert the necessary `meta-data` elements within the `<application>` tag. 

#### 3. Adding Java or Kotlin Code (if required):
   
For Java: 
- Navigate to `android/app/src/main/java/com/example/your_project_name`
- Open `MainActivity.java` with a text editor or IDE. 
- Add the required Java code to this file, usually within the `configureFlutterEngine` method. 
```
@Override
public void configureFlutterEngine(FlutterEngine flutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    // Your Java code here...
}
```

For Kotlin: 
- Navigate to `android/app/src/main/kotlin/com/example/your_project_name`
- Open `MainActivity.kt` with a text editor or IDE. 
- Add the required Kotlin code to this file to this file, usually within the `configureFlutterEngine` method. 
```
override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    // Your Kotlin code here...
}
```

### iOS 
#### 1. Adding adapters to your podfile:
- Locate your `Podfile` in the `/ios` folder.
- Open the Podfile with a text editor or IDE.
- Add the adapter pods to your application as specified in the documentation. It will look something like this
```
target 'Runner' do
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  pod `AppLovinSDK`
end
```
#### 2. Install the Pods:
- Save the `Podfile`.
- Open a terminal window, navigate to the root of your Flutter project, and run the following command to install the pods:
```flutter pub get```
- Optionally, you may also run `pod install` within the `ios` directory. 

#### 3. Adding code to your Xcode Project (if required):
- In your Flutter project's `ios` folder, find and open the `Runner.xcworkspace` file to launch Xcode.
- Locate the `AppDelegate.m` (Objective-C) or `AppDelegate.swift` (Swift) file within Xcode.
- Add the necessary code in the `didFinishingLaunchingWithOptions` as the adapter documentation directs. 
  
## License
MIT
