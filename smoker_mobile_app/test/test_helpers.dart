import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ossc/core/networking/smoker_socket_client.dart';
import 'package:ossc/core/networking/smoker_api_client.dart';

class MockSmokerSocketClient extends Mock implements SmokerSocketClient {}
class MockSmokerApiClient extends Mock implements SmokerApiClient {}

void setupTestMocks() {
  SharedPreferences.setMockInitialValues({});
}
