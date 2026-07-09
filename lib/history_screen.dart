import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'polulek_service.dart';

class HistoryScreen extends StatelessWidget {
  final Map<String, String> history;
  final PolulekService service;

  const HistoryScreen({
    super.key,
    required this.history,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final sortedKeys = history.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Past Polulkis', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: sortedKeys.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'No history yet. Come back tomorrow!',
                  style: GoogleFonts.outfit(fontSize: 18, color: const Color(0xFF3E4A43)),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              itemCount: sortedKeys.length,
              itemBuilder: (context, index) {
                final date = sortedKeys[index];
                final bufo = history[date]!;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  leading: Image.asset(
                    bufo.contains('.') ? 'assets/images/$bufo' : 'assets/images/$bufo.png',
                    width: 50,
                    height: 50,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
                  ),
                  title: Text(
                    date,
                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.black54),
                  ),
                  subtitle: Text(
                    service.formatBufoName(bufo),
                    style: GoogleFonts.fredoka(fontSize: 22, color: const Color(0xFF2E4F32), fontWeight: FontWeight.w500),
                  ),
                );
              },
            ),
    );
  }
}
