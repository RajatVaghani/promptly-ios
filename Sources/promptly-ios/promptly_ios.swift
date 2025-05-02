import Foundation
import UserNotifications
#if os(iOS)
import UIKit
#endif

public final class Promptly {
    public static let shared = Promptly()
    private init() {}

    // MARK: – Configuration properties
    public var apiKey: String = ""          // set at init
    public var apiBaseURL: String = "http://localhost/promptly-web" // default for local testing
    public var askAfterLaunches: Int = 2    // -1 = manual only
    public var onPermissionChange: ((Bool)->Void)?
    public var debugMode: Bool = false      // Enable logging for debugging

    private let ud = UserDefaults.standard
    private let tokenKey = "plc_token"
    private let launchCountKey = "plc_launches"

    public func start(apiKey: String, 
                     baseURL: String? = nil,
                     askAfterLaunches n: Int = 2,
                     callback: ((Bool)->Void)? = nil) {
        self.apiKey = apiKey
        if let url = baseURL {
            self.apiBaseURL = url
        }
        self.askAfterLaunches = n
        self.onPermissionChange = callback
        incrementLaunchCount()
        maybeRequest()
        registerForRemoteNotifications()
        
        // Store API key and base URL in app group for extensions to access
        if let groupUD = UserDefaults(suiteName: "group.promptly.notifications") {
            groupUD.set(apiKey, forKey: "promptly_api_key")
            groupUD.set(apiBaseURL, forKey: "promptly_base_url")
        }
        
        log("Promptly SDK initialized with baseURL: \(apiBaseURL)")
    }

    public func askForPermission() {
        requestPermission(force: true)
    }
    
    public func getPermissionStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    // MARK: – Private helpers
    private func incrementLaunchCount() {
        let k = launchCountKey
        ud.set(ud.integer(forKey: k) + 1, forKey: k)
    }

    private func maybeRequest() {
        guard askAfterLaunches > 0 else { return }
        if ud.integer(forKey: launchCountKey) >= askAfterLaunches {
            requestPermission(force: true)
        }
    }

    private func requestPermission(force: Bool) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                self.promptForPermission()
            case .denied:
                if force {
                    #if os(iOS)
                    DispatchQueue.main.async {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    #endif
                }
            case .authorized, .provisional, .ephemeral:
                if force {
                    self.promptForPermission()
                }
            @unknown default:
                if force {
                    self.promptForPermission()
                }
            }
        }
    }
    
    private func promptForPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.track(event: granted ? "permission_allowed" : "permission_denied")
                self.onPermissionChange?(granted)
                
                if let error = error {
                    self.log("Permission request error: \(error.localizedDescription)")
                }
            }
        }
    }

    private func registerForRemoteNotifications() {
        #if os(iOS)
        DispatchQueue.main.async { 
            UIApplication.shared.registerForRemoteNotifications() 
        }
        #endif
    }

    public func didRegister(deviceToken: Data) {
        let token = deviceToken.map { String(format:"%02.2hhx", $0) }.joined()
        
        // Store token for future use
        ud.set(token, forKey: tokenKey)
        
        // Also store in app group for extensions
        if let groupUD = UserDefaults(suiteName: "group.promptly.notifications") {
            groupUD.set(token, forKey: tokenKey)
        }
        
        log("Registering device token: \(token)")
        
        postJson(path:"/api/sdk/register", [
            "api_key": apiKey,
            "token": token,
            "platform": "ios",
            "locale": Locale.current.identifier,
            "tz": TimeZone.current.identifier,
            "app_ver": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
            "build": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        ])
    }
    
    public func didFailToRegister(error: Error) {
        log("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    public func trackNotificationResponse(_ response: UNNotificationResponse) {
        let type = response.actionIdentifier == UNNotificationDefaultActionIdentifier ? "push_tap" : "push_dismiss"
        let userInfo = response.notification.request.content.userInfo
        var meta: [String: Any] = [:]
        
        if let campaignId = userInfo["c"] {
            meta["campaign_id"] = campaignId
        }
        
        // Include other relevant notification data
        userInfo.forEach { key, value in
            if let keyString = key as? String, keyString != "aps" && keyString != "c" {
                meta[keyString] = value
            }
        }
        
        track(event: type, meta: meta)
    }
    
    public func track(event: String, meta: [String: Any] = [:]) {
        log("Tracking event: \(event) with meta: \(meta)")
        
        let token = ud.string(forKey: tokenKey) ?? ""
        if token.isEmpty && !debugMode {
            log("Warning: Attempting to track event without device token")
        }
        
        postJson(path:"/api/sdk/track", [
            "api_key": apiKey,
            "token": token,
            "type": event,
            "meta": meta
        ])
    }

    private func postJson(path: String, _ body: [String: Any]) {
        guard let url = URL(string: apiBaseURL + path) else {
            log("Invalid URL: \(apiBaseURL + path)")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                if let error = error {
                    self?.log("Network error: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if !(200...299).contains(httpResponse.statusCode) {
                        self?.log("HTTP error: \(httpResponse.statusCode)")
                        if let data = data, let responseString = String(data: data, encoding: .utf8) {
                            self?.log("Response: \(responseString)")
                        }
                    } else {
                        self?.log("Successfully sent to \(path)")
                    }
                }
            }
            task.resume()
        } catch {
            log("JSON serialization error: \(error.localizedDescription)")
        }
    }
    
    private func log(_ message: String) {
        if debugMode {
            print("Promptly: \(message)")
        }
    }
}
