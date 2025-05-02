# Promptly iOS SDK

A lightweight, zero-dependency push notification SDK for iOS that connects with the Promptly backend.

## Features

- Simple device registration with Apple Push Notification service (APNs)
- Intelligent permission request timing
- Notification tracking (taps, dismissals)
- Custom event tracking
- Support for rich notifications and notification content extensions
- Local development mode

## Installation

### Swift Package Manager

Add the following dependency to your `Package.swift` file:

```swift
.package(url: "https://github.com/yourusername/promptly-ios.git", from: "1.0.0")
```

Or add it through Xcode:
1. File > Add Packages...
2. Enter repository URL
3. Select version requirements

## Quick Start

### 1. Initialize the SDK

In your `AppDelegate`:

```swift
import UIKit
import promptly_ios

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize Promptly with your API key
        Promptly.shared.start(
            apiKey: "YOUR_API_KEY",
            baseURL: "https://your-server.com" // For local testing: "http://localhost/promptly-web"
        )
        
        // Enable debug logs during development
        Promptly.shared.debugMode = true
        
        return true
    }
    
    // Handle device token registration
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Promptly.shared.didRegister(deviceToken: deviceToken)
    }
    
    // Handle registration errors
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Promptly.shared.didFailToRegister(error: error)
    }
}
```

### 2. Track Notification Interactions

In your `SceneDelegate` or `AppDelegate`:

```swift
// Track when users interact with notifications
func userNotificationCenter(_ center: UNUserNotificationCenter, 
                           didReceive response: UNNotificationResponse, 
                           withCompletionHandler completionHandler: @escaping () -> Void) {
    
    Promptly.shared.trackNotificationResponse(response)
    completionHandler()
}
```

### 3. Request Permissions Manually (Optional)

By default, permission requests are triggered after the configured number of app launches. You can also trigger it manually:

```swift
// Request permission manually
button.addTarget(self, action: #selector(requestPushPermission), for: .touchUpInside)

@objc func requestPushPermission() {
    Promptly.shared.askForPermission()
}
```

### 4. Track Custom Events

Track any user interactions or events:

```swift
// Track simple event
Promptly.shared.track(event: "feature_used")

// Track event with metadata
Promptly.shared.track(event: "purchase_completed", meta: [
    "amount": 19.99,
    "item_id": "premium_subscription",
    "currency": "USD"
])
```

## Local Testing

For local development, set the base URL to your local Promptly backend:

```swift
Promptly.shared.start(
    apiKey: "test_api_key",
    baseURL: "http://localhost/promptly-web",
    askAfterLaunches: 1
)
```

## Notification Content Extensions

If you're using notification content extensions, add this to your extension:

```swift
import UserNotifications
import UserNotificationsUI
import promptly_ios

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    func didReceive(_ notification: UNNotification) {
        // Track that the content extension was displayed
        PrompthlyNotificationExtension.trackContentExtensionDisplay(notification: notification)
        
        // Your normal content extension code...
    }
    
    @IBAction func buttonTapped(_ sender: Any) {
        // Track custom interactions in your content extension
        if let notification = self.notification {
            PrompthlyNotificationExtension.trackContentExtensionInteraction(
                notification: notification, 
                action: "cta_button_tap"
            )
        }
    }
}
```

## Requirements

- iOS 13.0+ / macOS 10.15+
- Swift 5.2+
- Xcode 13.0+

## License

This project is licensed under the MIT License. 