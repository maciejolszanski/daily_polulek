import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'polulek_service.dart';

class AllPossiblePolulkisScreen extends StatefulWidget {
  final List<String> bufoTypes;
  final PolulekService service;

  const AllPossiblePolulkisScreen({
    super.key,
    required this.bufoTypes,
    required this.service,
  });

  @override
  State<AllPossiblePolulkisScreen> createState() => _AllPossiblePolulkisScreenState();
}

class _AllPossiblePolulkisScreenState extends State<AllPossiblePolulkisScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredBufos = [];

  @override
  void initState() {
    super.initState();
    _filteredBufos = widget.bufoTypes;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBufos = widget.bufoTypes.where((bufo) {
        final formattedName = widget.service.formatBufoName(bufo).toLowerCase();
        return formattedName.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('All Polulkis', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Polulkis...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredBufos.isEmpty
                ? Center(
                    child: Text(
                      'No matching Polulkis found',
                      style: GoogleFonts.outfit(fontSize: 18, color: Colors.black54),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _filteredBufos.length,
                    itemBuilder: (context, index) {
                      final bufo = _filteredBufos[index];
                      final formatted = widget.service.formatBufoName(bufo);
                      return Card(
                        color: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Image.asset(
                                  bufo.contains('.') ? 'assets/images/$bufo' : 'assets/images/$bufo.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image, size: 50),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                formatted,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.fredoka(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF2E4F32),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
