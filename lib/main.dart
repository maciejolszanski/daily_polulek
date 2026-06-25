import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
          seedColor: const Color(0xFF2E4F32), 
          primary: const Color(0xFF2E4F32),
          secondary: const Color(0xFFFFCC80), 
          surface: const Color(0xFFF6F3E6),
        ),
        useMaterial3: true,
        fontFamily: GoogleFonts.outfit().fontFamily,
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
  List<String> bufoTypes = [];
  Map<String, String> history = {};
  String? todaysBufo;
  bool _isLoading = true;
  
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initApp();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
  }

  Future<void> _initApp() async {
    final AssetManifest assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    
    final bufos = assetManifest.listAssets()
        .where((key) => key.startsWith('assets/images/') && 
               (key.endsWith('.png') || key.endsWith('.gif') || key.endsWith('.jpg') || key.endsWith('.jpeg')))
        .map((key) => key.split('/').last)
        .toList();

    if (!mounted) return;
    
    setState(() {
      bufoTypes = bufos;
      _loadHistory();
      
      // If the saved bufo no longer exists in our new list (e.g. old deleted bufos),
      // reset it so the user can roll a new one.
      if (todaysBufo != null && !bufoTypes.contains(todaysBufo)) {
        todaysBufo = null;
      }
      
      if (todaysBufo != null) {
        _controller.value = 1.0;
      }
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatBufoName(String bufo) {
    int dotIndex = bufo.lastIndexOf('.');
    String name = dotIndex != -1 ? bufo.substring(0, dotIndex) : bufo;
    
    String formatted = name.replaceAll(RegExp(r'-bufo-|-bufo|_bufo_|bufo-|bufo_|_bufo|bufo', caseSensitive: false), ' Poluśka ');
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
    if (bufoTypes.isEmpty) return;
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
                        leading: Image.asset(
                          bufo.contains('.') ? 'assets/images/$bufo' : 'assets/images/$bufo.png', 
                          width: 40, 
                          height: 40,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                        ),
                        title: Text(date),
                        subtitle: Text(_formatBufoName(bufo), style: GoogleFonts.balsamiqSans(fontSize: 20)),
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
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (todaysBufo == null) ...[
                const Spacer(),
                Text(
                  'What kind of Poluśka are you today?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 28, color: const Color(0xFF3E4A43)),
                ),
                const SizedBox(height: 40),
                Center(
                  child: ElevatedButton(
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
                ),
                const Spacer(),
              ] else ...[
                const Spacer(flex: 2),
                Text(
                  'Today, you are a...',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 28, color: const Color(0xFF3E4A43)),
                ),
                const Spacer(flex: 3),
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Image.asset(
                    todaysBufo!.contains('.') ? 'assets/images/$todaysBufo' : 'assets/images/$todaysBufo.png',
                    width: 250,
                    height: 250,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 100),
                  ),
                ),
                const Spacer(flex: 2),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Poluśka',
                      style: GoogleFonts.outfit(fontSize: 22, color: Colors.black87),
                    ),
                    Builder(
                      builder: (context) {
                        String fullName = _formatBufoName(todaysBufo!);
                        String mainWord = fullName.replaceAll('Poluśka', '').trim();
                        if (mainWord.isEmpty) mainWord = "Bufo";
                        return Text(
                          '$mainWord!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            fontSize: 72, 
                            fontWeight: FontWeight.w600, 
                            color: const Color(0xFF4A6B42),
                            height: 1.0,
                          ),
                        );
                      }
                    ),
                  ],
                ),
                const Spacer(flex: 3),
                Text(
                  'Come back tomorrow for a new Poluśka!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.kodeMono(fontSize: 14, color: Colors.black87),
                ),
                const Spacer(flex: 1),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
