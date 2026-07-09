import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'polulek_service.dart';
import 'history_screen.dart';
import 'all_possible_polulkis_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(DailyPolulekApp(prefs: prefs));
}

class DailyPolulekApp extends StatelessWidget {
  final SharedPreferences prefs;

  const DailyPolulekApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Polulek',
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
  final _service = PolulekService();
  List<String> bufoTypes = [];
  Map<String, String> history = {};
  String? todaysBufo;
  bool isConfirmed = false;
  bool _isLoading = true;
  
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _initApp();
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
    return _service.formatBufoName(bufo);
  }

  void _loadHistory() {
    history = _service.loadHistory(widget.prefs);
    todaysBufo = history[_service.getTodayDateString()];
    isConfirmed = todaysBufo != null;
  }

  void _saveHistory() {
    _service.saveHistory(widget.prefs, history);
  }

  void _rollBufo() {
    final selected = _service.pickRandomBufo(bufoTypes, exclude: todaysBufo);
    if (selected == null) return;
    
    setState(() {
      todaysBufo = selected;
      isConfirmed = false;
    });
    
    _controller.forward(from: 0.0);
  }

  void _confirmBufo() {
    if (todaysBufo == null) return;
    setState(() {
      isConfirmed = true;
      history[_service.getTodayDateString()] = todaysBufo!;
      _saveHistory();
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Daily Polulek', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'calendar') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryScreen(
                      history: history,
                      service: _service,
                    ),
                  ),
                );
              } else if (value == 'all_polulkis') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllPossiblePolulkisScreen(
                      bufoTypes: bufoTypes,
                      service: _service,
                    ),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'calendar',
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, color: Colors.black87),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Past Polulkis', overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'all_polulkis',
                child: Row(
                  children: [
                    Icon(Icons.collections, color: Colors.black87),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('See all possible Polulkis', overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (todaysBufo == null) ...[
                          const Spacer(),
                          Text(
                            'What kind of Polulek are you today?',
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
                            'Today, you are...',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(fontSize: 28, color: const Color(0xFF3E4A43)),
                          ),
                          const Spacer(flex: 1),
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Image.asset(
                              todaysBufo!.contains('.') ? 'assets/images/$todaysBufo' : 'assets/images/$todaysBufo.png',
                              width: 250,
                              height: 250,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 100),
                            ),
                          ),
                          const Spacer(flex: 1),
                          Builder(
                            builder: (context) {
                              final segments = _service.splitBufoNameForStyling(todaysBufo!);
                              return RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: GoogleFonts.fredoka(
                                    fontSize: 72, 
                                    fontWeight: FontWeight.w600, 
                                    height: 1.1,
                                  ),
                                  children: [
                                    ...segments.map((segment) {
                                      return TextSpan(
                                        text: segment.text,
                                        style: TextStyle(
                                          color: segment.isPolulek ? const Color(0xFFC87A53) : const Color(0xFF4A6B42),
                                        ),
                                      );
                                    }),
                                    const TextSpan(
                                      text: '!',
                                      style: TextStyle(color: Color(0xFF4A6B42)),
                                    ),
                                  ],
                                ),
                              );
                            }
                          ),
                          const Spacer(flex: 3),
                          if (!isConfirmed) ...[
                            Text(
                              'Is this how you feel today?',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(fontSize: 20, color: const Color(0xFF3E4A43)),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _rollBufo,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('No, re-roll'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _confirmBufo,
                                  icon: const Icon(Icons.check),
                                  label: const Text('Yes!'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.secondary,
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                    elevation: 3,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            Text(
                              'Come back tomorrow for a new Polulek!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.kodeMono(fontSize: 14, color: Colors.black87),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: _rollBufo,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.black54,
                              ),
                              child: const Text('Actually, I feel different...', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                          const Spacer(flex: 1),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        ),
      ),
    );
  }
}
