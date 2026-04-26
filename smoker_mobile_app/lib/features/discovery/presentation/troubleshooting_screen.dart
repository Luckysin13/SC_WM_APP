import 'package:flutter/material.dart';
import '../../../shared/widgets/version_display.dart';

class TroubleshootingScreen extends StatelessWidget {
  const TroubleshootingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Troubleshooting Guide')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildItem(
            'Cannot discover device?',
            'Ensure you are connected to the same WiFi network as the smoker. Local network permissions must be granted on your phone (specifically on iOS) for mDNS discovery to work. Finally, some WiFi routers isolate clients; check if "AP Isolation" or "Client Isolation" is enabled on your router.',
          ),
          _buildItem(
            'Connected to Smoker AP but no internet?',
            'When the smoker is not connected to your home WiFi network, it broadcasts its own network (Access Point or AP mode). Your phone connects to it to configure it, but it cannot access the internet during this time. To fix this, use the WiFi Setup page in the app to feed your home router credentials to the device.',
          ),
          _buildItem(
            'App constantly reconnecting?',
            'The connection to the smoker works via WebSockets on your local network. Heavy network traffic, thick walls, or being too far from the router can drop the connection. The app tries to silently reconnect in the background, but if it is stuck, try closing and reopening the app.',
          ),
          _buildItem(
            'Features grayed out?',
            'When the device is disconnected, the dashboard controls are temporarily grayed out to prevent you from sending commands that won\'t be received. If you are connected to the device in AP mode, certain features like Timezone and Over-The-Air (OTA) updates are disabled because they require internet access.',
          ),
          const SizedBox(height: 32),
          const Center(
            child: VersionDisplay(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildItem(String title, String body) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(body, style: const TextStyle(height: 1.4)),
          ],
        ),
      ),
    );
  }
}
