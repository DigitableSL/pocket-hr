import Flutter
import UIKit
import CoreLocation

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let securityChannelName = "asia.ceynet.pocket/security"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    application.registerForRemoteNotifications()

    let appLaunched = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    if let controller = window?.rootViewController as? FlutterViewController {
      let securityChannel = FlutterMethodChannel(name: securityChannelName,
                                                binaryMessenger: controller.binaryMessenger)

      securityChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        guard let self = self else {
          result(false)
          return
        }

        if call.method == "isDevModeEnabled" {
          result(self.isDevModeEnabled())
        } else if call.method == "isMockLocation" {
          result(self.isMockLocation())
        } else if call.method == "isAutoTimeEnabled" {
          result(true)
        } else {
          result(FlutterMethodNotImplemented)
        }
      })
    }

    return appLaunched
  }

  private func isDevModeEnabled() -> Bool {
    #if DEBUG
    return false
    #else
    return isDebuggerAttached()
    #endif
  }

  private func isDebuggerAttached() -> Bool {
    var info = kinfo_proc()
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    var size = MemoryLayout<kinfo_proc>.stride
    let junk = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
    if junk != 0 {
      return false
    }
    return (info.kp_proc.p_flag & P_TRACED) != 0
  }

  private func isMockLocation() -> Bool {
    let locManager = CLLocationManager()
    guard let location = locManager.location else { return false }
    if #available(iOS 15.0, *) {
      return location.sourceInformation?.isSimulatedBySoftware ?? false
    }
    return false
  }
}
