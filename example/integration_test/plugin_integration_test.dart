import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:adaptive_image_picker/adaptive_image_picker.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getPlatformVersion test', (WidgetTester tester) async {
    final String? version = await AdaptiveImagePicker.getPlatformVersion();
    expect(version?.isNotEmpty, true);
  });
}
