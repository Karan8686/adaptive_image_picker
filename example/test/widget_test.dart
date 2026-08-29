import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_image_picker_example/main.dart';

void main() {
  testWidgets('Verify AdaptiveImagePickerShowcaseApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(const AdaptiveImagePickerShowcaseApp());
    expect(find.text('Adaptive Picker'), findsOneWidget);
    expect(find.text('Live Pipeline Studio'), findsOneWidget);
    expect(find.text('Studio'), findsOneWidget);
    expect(find.text('Recipes'), findsOneWidget);
    expect(find.text('Gallery'), findsWidgets);
  });
}
