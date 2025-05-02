# Local Testing Guide for Promptly SDK

This guide explains how to test the Promptly iOS SDK with a local backend running on XAMPP.

## Prerequisites

1. XAMPP installed on your Mac
2. Promptly backend running in XAMPP (as per the documentation)
3. iOS app with Promptly SDK integrated
4. Network connectivity between your iOS device/simulator and Mac

## Setup Steps

### 1. Configure XAMPP for External Access

By default, XAMPP only listens on localhost. To make it accessible to your iOS device:

1. Open Terminal and navigate to XAMPP's Apache config directory:
   ```bash
   cd /Applications/XAMPP/xamppfiles/etc/httpd.conf
   ```

2. Edit the httpd.conf file:
   ```bash
   sudo nano httpd.conf
   ```

3. Find the line containing `Listen 80` and change it to:
   ```
   Listen 0.0.0.0:80
   ```

4. Save and restart Apache from the XAMPP Control Panel.

### 2. Find Your Mac's IP Address

1. Open System Preferences > Network
2. Select your active network connection (Wi-Fi or Ethernet)
3. Note the IP address (e.g., 192.168.1.15)

### 3. Configure Your iOS App

In your app's implementation of Promptly SDK:

```swift
// Initialize with your local IP address
Promptly.shared.start(
    apiKey: "YOUR_TEST_API_KEY", 
    baseURL: "http://192.168.1.15/promptly-web",  // Replace with your Mac's IP
    askAfterLaunches: 1  // Set to 1 for faster testing
)

// Enable debug mode to see logs
Promptly.shared.debugMode = true
```

### 4. Create a Test App in Promptly Web Dashboard

1. Open your browser and navigate to `http://localhost/promptly-web`
2. Log in to the dashboard
3. Go to "Apps" and create a new application
4. Note the API key that's generated

### 5. Test Device Registration

1. Run your iOS app on a real device (or simulator)
2. Accept the push notification permission prompt
3. Check the XAMPP logs for registration requests
4. Verify in the MySQL database that your device token was registered

### 6. Test Push Notifications

To test push notifications locally:

1. Use a tool like [Pusher](https://github.com/noodlewerk/NWPusher) to send test pushes
2. Or create a campaign in the Promptly dashboard and trigger it

### Troubleshooting

#### Network Issues

If your iOS device can't connect to your Mac:
- Ensure both are on the same Wi-Fi network
- Check if your Mac's firewall is blocking connections
- Try disabling your Mac's firewall temporarily for testing

#### APNS Certificate Issues

For push notification testing:
- You need a valid APNS certificate
- For development, use a sandbox certificate
- Register the bundle ID in your Apple Developer account

#### Database Connection Issues

If API calls fail:
- Check MySQL is running in XAMPP
- Verify database credentials in your Promptly backend config
- Look at the PHP error logs in XAMPP

### Using Charles Proxy for Debugging

Charles Proxy can help debug the communication between your iOS app and the local server:

1. Install [Charles Proxy](https://www.charlesproxy.com/)
2. Configure your iOS device to use Charles as a proxy
3. Monitor the API requests in real-time

## Next Steps

Once local testing works correctly, you can deploy the Promptly backend to a real server and update the `baseURL` in your iOS app to point to the production server. 