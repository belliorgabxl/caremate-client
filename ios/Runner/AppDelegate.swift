import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // iOS has no local.properties equivalent, so unlike Android this key is
    // committed. It ships in the binary either way; restrict it in Google
    // Cloud Console (iOS bundle ID + Maps SDK for iOS only).
    GMSServices.provideAPIKey("AIzaSyD7Kw_w4HSkFrfjIULXFXBAzCtYGnamYA8")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
