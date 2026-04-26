# QA & Testing Checklist

Use this manual checklist prior to releasing Android or iOS binaries.

## 1. Network Acquisition
- [ ] Connect device to Smoker Controller on home WiFi via mDNS scan.
- [ ] Verify successful fallback Connection Banner rendering when device forcibly disconnected.
- [ ] Enter wrong Manual IP, confirm timeout behavior.
- [ ] Input correct Manual IP, intercept device correctly.

## 2. Dashboard Interaction
- [ ] Modify Pit Target constraints, confirm socket string `2b<value>` fires immediately.
- [ ] Validate Keep Warm / Meat Done triggers conditionally disabling based on dependencies.
- [ ] Dashboard overlays `IgnorePointer` cleanly when the WiFi shuts off.

## 3. History Matrix
- [ ] Reboot the router. 
- [ ] Open `HistoryScreen`, ensure chunked payloads compile immediately over WebSockets.
- [ ] Evaluate real-time charting additions continuing off the back of the seed transfer cleanly.

## 4. AP Mode & Configuration
- [ ] Force the controller into AP mode. Connect cellular phone.
- [ ] Ensure the amber `AP MODE` restrictions banner visually fires and disables OTA/Timezone fields.
- [ ] Input credentials inside WiFi setup, monitor successful POST resulting in the app navigating back to device discovery.

## 5. Automated Testing

To ensure stability across the domain logic, the app contains automated tests built using `flutter_test` and `mocktail`.
You can run the full test suite locally by running:

```bash
flutter test
```

### Coverage
- **LiveState**: Validation of all API JSON payloads and parsing robustness.
- **HistoryAssembler**: Validation of WebSocket chunk merging and metadata.
- **Providers**: Expected connections state testing.

## 6. Local Development Testing (Mock Mode)

To run the app locally on your computer (e.g. Linux Desktop) without physical smoker hardware connected to your network, you can use **Mock Mode**.

### Enabling Mock Mode
1. Open `lib/core/providers.dart`
2. Update the `deviceSessionManagerProvider` instantiation string:
```dart
  final manager = DeviceSessionManager(
    dio: dio,
    enableMockMode: true, // ADD THIS LINE
    onLiveStateUpdated: (state) {
```
3. Run `flutter run -d linux`
4. Input any IP (e.g., `1.1.1.1`) into the Manual Connect field. The system will artificially transition into a `connected` status, sending looping mocked temperature ticks directly to the dashboard.
