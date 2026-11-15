# AppLovin MAX Flutter Plugin
AppLovin MAX Flutter Plugin for Android and iOS.

## Documentation
Check out our integration docs [here](https://support.axon.ai/en/max/flutter/overview/integration).

## Downloads
See [pub.dev](https://pub.dev/packages/applovin_max) for the latest releases of the plugin.

## Demo App Instructions
To get started with the demo app, please ensure Flutter is installed on your system. Once everything is properly installed, follow the instructions below to get the demo application up and running. 

1. Obtain your AppLovin SDK Key from the dashboard [here](https://support.axon.ai/en/max/flutter/overview/integration#initialize-the-sdk).
2. Obtain your Ad Unit IDs from the dashboard [here](https://dash.applovin.com/o/mediation/ad_units).
3. Update the `SDK_KEY` and Ad Unit IDs in the `main.dart` file. 
4. Update the package name from `com.applovin.enterprise.apps.demoapp` to one that matches your ad units. Be sure to do this for every package name reference in the demo app. 

### Android
#### 1. Updating the package name in `app/build.gradle`:
- Navigate to your Flutter project directory in your file explorer or terminal. 
- Within the project directory, navigate to `android/app/` to find the `build.gradle` file. 
- Open `build.gradle` with a text editor or an IDE. 
- Update `applicationId` with your package name.
````
android {
    ⋮
    defaultConfig {
        applicationId "your_package_name"
        ⋮
    }
````

#### 2. Adding adapters to `app/build.gradle`:
- Add the necessary adapters for the mediated ad networks you plan to integrate, as specified in the [documentation](https://support.axon.ai/en/max/flutter/preparing-mediated-networks#android). It will look something like this:
```
dependencies {
    // Other dependencies...
    implementation 'com.example.adapter:version'
}
```
> [!CAUTION]
> Do not add the underlying AppLovin SDK to your dependencies. The AppLovin MAX Flutter plugin
> already specifies the certified SDK version corresponding to the plugin. If you also manually add
> the dependency, this may break your build and cause unpredictable results.
>
> ~~implementation 'com.applovin:applovin-sdk:+'~~

#### 3. Updating `AndroidManifest.xml` with `meta-data` (if required):
- Within the `android/app/` directory, locate and open the `AndroidManifest.xml` file.
- If the mediated ad network adapter you add requires `meta-data`, insert the necessary `meta-data` elements within the `<application>` tag. 

### iOS 
The plugin gets the AppLovin SDK through Swift Package Manager. It requires Flutter 3.41 or later with Swift Package Manager turned on (the default from Flutter 3.44; before that, run `flutter config --enable-swift-package-manager`). Other plugins don't need to support Swift Package Manager: Flutter keeps installing those through CocoaPods alongside it.

#### 1. Adding adapters as Swift packages:
- In your Flutter project's `ios` folder, open `Runner.xcworkspace` in Xcode.
- Select **File > Add Package Dependencies…** and add the Swift package of each mediated network you're integrating (`https://github.com/AppLovin/AppLovin-MAX-Swift-Package-<Network>`), as specified in the [documentation](https://support.axon.ai/en/max/flutter/preparing-mediated-networks#ios). Add its `AppLovinMediation<Network>Adapter` product to the **Runner** target.

> [!CAUTION]
> Do not add the underlying AppLovin SDK to your dependencies. The AppLovin MAX Flutter plugin
> already specifies the certified SDK version corresponding to the plugin. If you also manually add
> the dependency, this may break your build and cause unpredictable results.
>
> ~~https://github.com/AppLovin/AppLovin-MAX-Swift-Package~~

#### 2. Building the app:
- Run `flutter build ios` or `flutter run`. Xcode resolves the Swift packages; Flutter runs `pod install` only for other plugins that still use CocoaPods.

#### 3. Updating the Bundle Identifier with your package name:
- In Xcode, select the **Signing and Capabilities** tab and update the Bundle Identifier with your package name, ensuring it matches the package name configured in your AppLovin dashboard.

#### 4. Adding the `NSUserTrackingUsageDescription` key to the Information Property List (Info.plist):
- Add `NSUserTrackingUsageDescription` to your Information Property List via Xcode or directly edit
  `Info.plist`. This key is necessary so that your app can display the permission prompt for tracking user activity across apps.

#### 5. Updating 'Info.plist' (if required):
- If the mediated ad network adapter you add requires an information property, update `Info.plist`
  with the necessary key-value pairs.
  
## License
MIT
