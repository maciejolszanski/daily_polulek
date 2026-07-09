import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class PolulekService {
  String formatBufoName(String bufo) {
    int dotIndex = bufo.lastIndexOf('.');
    String name = dotIndex != -1 ? bufo.substring(0, dotIndex) : bufo;
    
    String formatted = name.replaceAll(RegExp(r'-bufo-|-bufo|_bufo_|bufo-|bufo_|_bufo|bufo', caseSensitive: false), ' Polulek ');
    formatted = formatted.replaceAll('-', ' ').replaceAll('_', ' ');
    formatted = formatted.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    if (formatted.isEmpty) return formatted;
    
    List<String> words = formatted.split(' ');
    for (int i = 0; i < words.length; i++) {
      if (words[i].isNotEmpty) {
        words[i] = words[i][0].toUpperCase() + words[i].substring(1).toLowerCase();
      }
    }
    return words.join(' ');
  }

  String getTodayDateString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Map<String, String> loadHistory(SharedPreferences prefs) {
    final String? historyJson = prefs.getString('bufo_history');
    if (historyJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(historyJson);
        return decoded.map((key, value) => MapEntry(key, value.toString()));
      } catch (_) {
        return {};
      }
    }
    return {};
  }

  void saveHistory(SharedPreferences prefs, Map<String, String> history) {
    final String encoded = jsonEncode(history);
    prefs.setString('bufo_history', encoded);
  }

  String? pickRandomBufo(List<String> bufoTypes, {String? exclude, Random? random}) {
    if (bufoTypes.isEmpty) return null;
    final r = random ?? Random();
    
    if (bufoTypes.length > 1 && exclude != null) {
      String selected;
      do {
        selected = bufoTypes[r.nextInt(bufoTypes.length)];
      } while (selected == exclude);
      return selected;
    } else {
      return bufoTypes[r.nextInt(bufoTypes.length)];
    }
  }
}
