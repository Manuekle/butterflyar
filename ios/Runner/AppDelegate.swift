import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Request camera permission on app launch
    AVCaptureDevice.requestAccess(for: .video) { granted in
      if granted {
        print("Camera access granted")
      } else {
        print("Camera access denied")
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle permission changes while app is running
  override func applicationWillEnterForeground(_ application: UIApplication) {
    // Check camera permission status when app comes to foreground
    let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
    if cameraStatus == .denied || cameraStatus == .restricted {
      // Camera permission was denied or restricted
      print("Camera permission denied or restricted")
    }
  }
}