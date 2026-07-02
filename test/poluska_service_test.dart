import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_poluska/poluska_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PoluskaService service;

  setUp(() {
    service = PoluskaService();
  });

  group('formatBufoName', () {
    test('formats basic name by removing extension and capitalization', () {
      expect(service.formatBufoName('bufo-happy.png'), 'Poluśka Happy');
    });

    test('formats name with bufo prefix', () {
      expect(service.formatBufoName('bufo-takes-a-bath.png'), 'Poluśka Takes A Bath');
    });

    test('formats name with bufo suffix', () {
      expect(service.formatBufoName('salty-bufo.png'), 'Salty Poluśka');
    });

    test('formats name with bufo in the middle', () {
      expect(service.formatBufoName('big-bufo-energy.png'), 'Big Poluśka Energy');
    });

    test('formats name case-insensitively for bufo occurrences', () {
      expect(service.formatBufoName('BUFO-Sleepy.png'), 'Poluśka Sleepy');
      expect(service.formatBufoName('sleepy-BUFO.png'), 'Sleepy Poluśka');
    });

    test('replaces dashes and underscores with spaces', () {
      expect(service.formatBufoName('very_sleepy_bufo.png'), 'Very Sleepy Poluśka');
      expect(service.formatBufoName('super-duper-happy-bufo.png'), 'Super Duper Happy Poluśka');
    });

    test('returns empty string if input is empty', () {
      expect(service.formatBufoName(''), '');
    });
  });

  group('getTodayDateString', () {
    test('returns formatted date string', () {
      final dateStr = service.getTodayDateString();
      final regExp = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      expect(regExp.hasMatch(dateStr), isTrue);
    });
  });

  group('loadHistory and saveHistory', () {
    test('loads empty history when preferences are empty', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final history = service.loadHistory(prefs);
      expect(history, isEmpty);
    });

    test('saves and loads history correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      
      final history = {
        '2026-06-28': 'bufo-sleepy.png',
        '2026-06-29': 'bufo-happy.png',
      };
      
      service.saveHistory(prefs, history);
      
      final loaded = service.loadHistory(prefs);
      expect(loaded, equals(history));
    });

    test('returns empty map on malformed history json', () async {
      SharedPreferences.setMockInitialValues({
        'bufo_history': 'not-a-json-string'
      });
      final prefs = await SharedPreferences.getInstance();
      final history = service.loadHistory(prefs);
      expect(history, isEmpty);
    });
  });

  group('pickRandomBufo', () {
    test('returns null if list is empty', () {
      expect(service.pickRandomBufo([]), isNull);
    });

    test('picks the only available bufo', () {
      expect(service.pickRandomBufo(['bufo-happy.png']), 'bufo-happy.png');
    });

    test('excludes the specified bufo if possible', () {
      final list = ['bufo-happy.png', 'bufo-sleepy.png'];
      final results = <String?>{};
      final random = Random(42); // deterministic random
      
      for (int i = 0; i < 50; i++) {
        results.add(service.pickRandomBufo(list, exclude: 'bufo-happy.png', random: random));
      }
      
      expect(results, equals({'bufo-sleepy.png'}));
    });

    test('picks the excluded one if it is the only one in list', () {
      expect(service.pickRandomBufo(['bufo-happy.png'], exclude: 'bufo-happy.png'), 'bufo-happy.png');
    });
  });
}
