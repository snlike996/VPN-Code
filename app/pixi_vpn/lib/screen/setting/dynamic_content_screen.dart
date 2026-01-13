import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DynamicContentScreen extends StatefulWidget {
  final String title;
  final String prefKey;

  const DynamicContentScreen({super.key, required this.title, required this.prefKey});

  @override
  State<DynamicContentScreen> createState() => _DynamicContentScreenState();
}

class _DynamicContentScreenState extends State<DynamicContentScreen> {
  String _content = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(widget.prefKey) ?? '';

    // Simple HTML tag stripper: if content contains html tags, show as plain text by removing tags.
    String stripped = raw.replaceAll(RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true), '');

    setState(() {
      _content = stripped.trim();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(widget.title, style: GoogleFonts.openSans(color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 16
        )),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                _content.isEmpty ? '暂无内容。' : _content,
                style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87, height: 1.6),
              ),
            ),
    );
  }
}

