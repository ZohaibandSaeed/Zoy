import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeetube/main.dart';
import 'package:zeetube/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  testWidgets('zoy smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ZoyApp());
    expect(find.byType(ZoyApp), findsOneWidget);
  });
}
