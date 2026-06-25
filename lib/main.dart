import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(DailyPoluskaApp(prefs: prefs));
}

class DailyPoluskaApp extends StatelessWidget {
  final SharedPreferences prefs;

  const DailyPoluskaApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Poluśka',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC8E6C9), // Pastel green
          primary: const Color(0xFF81C784),
          secondary: const Color(0xFFFFCC80), // Pastel orange
          surface: const Color(0xFFF1F8E9),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto', // Default, but can be customized
      ),
      home: HomePage(prefs: prefs),
    );
  }
}

class HomePage extends StatefulWidget {
  final SharedPreferences prefs;

  const HomePage({super.key, required this.prefs});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final List<String> bufoTypes = ['happy_bufo', 'sleepy_bufo', 'party_bufo'];
  Map<String, String> history = {};
  String? todaysBufo;
  
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    
    if (todaysBufo != null) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getTodayDateString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  void _loadHistory() {
    final String? historyJson = widget.prefs.getString('bufo_history');
    if (historyJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(historyJson);
      history = decoded.map((key, value) => MapEntry(key, value.toString()));
    }
    todaysBufo = history[_getTodayDateString()];
  }

  void _saveHistory() {
    final String encoded = jsonEncode(history);
    widget.prefs.setString('bufo_history', encoded);
  }

  void _rollBufo() {
    final random = Random();
    final selected = bufoTypes[random.nextInt(bufoTypes.length)];
    
    setState(() {
      todaysBufo = selected;
      history[_getTodayDateString()] = selected;
      _saveHistory();
    });
    
    _controller.forward(from: 0.0);
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final sortedKeys = history.keys.toList()..sort((a, b) => b.compareTo(a));
        
        return AlertDialog(
          title: const Text('Past Poluśkas', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Theme.of(context).colorScheme.surface,
          content: SizedBox(
            width: double.maxFinite,
            child: sortedKeys.isEmpty
                ? const Text('No history yet. Come back tomorrow!')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: sortedKeys.length,
                    itemBuilder: (context, index) {
                      final date = sortedKeys[index];
                      final bufo = history[date]!;
                      return ListTile(
                        leading: Image.asset('assets/images/$bufo.png', width: 40, height: 40),
                        title: Text(date),
                        subtitle: Text(bufo.replaceAll('_bufo', ' Poluśka')),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Daily Poluśka', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _showHistoryDialog,
            tooltip: 'History',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (todaysBufo == null) ...[
                const Text(
                  'What kind of Poluśka are you today?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _rollBufo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    'Find Out!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ] else ...[
                const Text(
                  'Today, you are a...',
                  style: TextStyle(fontSize: 24, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Image.asset(
                    'assets/images/$todaysBufo.png',
                    width: 250,
                    height: 250,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '${todaysBufo!.replaceAll('_bufo', ' Poluśka')}!',
                  style: TextStyle(
                    fontSize: 32, 
                    fontWeight: FontWeight.bold, 
                    color: Theme.of(context).colorScheme.primary
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Come back tomorrow for a new Poluśka!',
                  style: TextStyle(fontSize: 16, color: Colors.black45),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
