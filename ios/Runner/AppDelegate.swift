import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // The Google Maps key: GMS_API_KEY in ios/Flutter/MapsKey.xcconfig
    // (kept out of git), through Info.plist. Without one the SDK stops
    // the app when a map opens; a placeholder only leaves the map blank.
    let key = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String ?? ""
    GMSServices.provideAPIKey(
      key.isEmpty || key.hasPrefix("$(") ? "MISSING_GMS_API_KEY" : key)
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
