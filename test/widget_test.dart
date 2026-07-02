import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_poluska/main.dart';
import 'package:google_fonts/google_fonts.dart';

class FakeAssetBundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.json') {
      final Map<String, List<String>> manifest = {
        'assets/images/bufo-happy.png': ['assets/images/bufo-happy.png'],
        'assets/images/bufo-sleepy.png': ['assets/images/bufo-sleepy.png'],
      };
      final jsonString = jsonEncode(manifest);
      final bytes = utf8.encode(jsonString);
      return ByteData.sublistView(Uint8List.fromList(bytes));
    }
    if (key == 'AssetManifest.bin') {
      throw FlutterError('Manifest.bin not found');
    }
    return ByteData(0);
  }

  @override
  Future<T> loadStructuredData<T>(String key, Future<T> Function(String value) parser) async {
    if (key == 'AssetManifest.json') {
      return parser('{"assets/images/bufo-happy.png": ["assets/images/bufo-happy.png"], "assets/images/bufo-sleepy.png": ["assets/images/bufo-sleepy.png"]}');
    }
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Disable Google Fonts HTTP fetching in tests
  GoogleFonts.config.allowRuntimeFetching = false;

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildTestWidget(SharedPreferences prefs) {
    return DefaultAssetBundle(
      bundle: FakeAssetBundle(),
      child: DailyPoluskaApp(prefs: prefs),
    );
  }

  testWidgets('Initial load shows Find Out! button when today is unrolled', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget(prefs));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('What kind of Poluśka are you today?'), findsOneWidget);
    expect(find.text('Find Out!'), findsOneWidget);
  });

  testWidgets('Rolling a bufo shows it and asks for confirmation', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget(prefs));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Find Out!'));
    await tester.pumpAndSettle();

    expect(find.text('Today, you are...'), findsOneWidget);
    expect(find.text('Poluśka'), findsOneWidget);
    expect(find.text('Is this how you feel today?'), findsOneWidget);
    expect(find.text('Yes!'), findsOneWidget);
    expect(find.text('No, re-roll'), findsOneWidget);
  });

  testWidgets('Re-rolling picks a different bufo', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget(prefs));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Find Out!'));
    await tester.pumpAndSettle();

    String? getNameText() {
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      for (final text in textWidgets) {
        final data = text.data;
        if (data != null && data.endsWith('!') && data != 'Find Out!' && data != 'Yes!') {
          return data;
        }
      }
      return null;
    }

    final firstBufoName = getNameText();
    expect(firstBufoName, isNotNull);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    final secondBufoName = getNameText();
    expect(secondBufoName, isNotNull);
    expect(secondBufoName, isNot(equals(firstBufoName)));
  });

  testWidgets('Confirming a bufo saves it and shows lock-in screen', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget(prefs));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Find Out!'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(find.text('Come back tomorrow for a new Poluśka!'), findsOneWidget);
    expect(find.text('Actually, I feel different...'), findsOneWidget);

    final String? historyJson = prefs.getString('bufo_history');
    expect(historyJson, isNotNull);
    expect(historyJson, contains('bufo-'));
  });

  testWidgets('Tapping Actually, I feel different resets state', (WidgetTester tester) async {
    final dateKey = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
    SharedPreferences.setMockInitialValues({
      'bufo_history': '{"$dateKey": "bufo-happy.png"}'
    });
    prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(buildTestWidget(prefs));
    await tester.pumpAndSettle();

    expect(find.text('Come back tomorrow for a new Poluśka!'), findsOneWidget);

    await tester.tap(find.text('Actually, I feel different...'));
    await tester.pumpAndSettle();

    expect(find.text('Is this how you feel today?'), findsOneWidget);
  });

  testWidgets('Opening history dialog shows dialog', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget(prefs));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.calendar_month));
    await tester.pumpAndSettle();

    expect(find.text('Past Poluśkas'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  });
}
