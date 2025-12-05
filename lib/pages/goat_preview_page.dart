import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goat.dart';

class GoatPreviewPage extends StatefulWidget {
  final List<Goat> goats;
  final int initialIndex;

  const GoatPreviewPage({Key? key, required this.goats, this.initialIndex = 0}) : super(key: key);

  @override
  State<GoatPreviewPage> createState() => _GoatPreviewPageState();
}

class _GoatPreviewPageState extends State<GoatPreviewPage> {
  late PageController _controller;
  late int _index;
  late List<String?> _imagePaths;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.goats.length - 1);
    _controller = PageController(initialPage: _index);
    _imagePaths = List<String?>.filled(widget.goats.length, null);
    _loadImagePaths();
  }

  Future<void> _loadImagePaths() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < widget.goats.length; i++) {
      final key = 'goat_image_${widget.goats[i].tagNo}';
      final path = prefs.getString(key);
      if (path != null && File(path).existsSync()) {
        _imagePaths[i] = path;
      } else {
        _imagePaths[i] = null;
      }
    }
    if (mounted) setState(() {});
  }

  String _formatAge(String? dob) {
    if (dob == null) return '-';
    DateTime? dt;
    // try ISO
    dt = DateTime.tryParse(dob);
    if (dt == null) {
      // try dd/mm/yyyy or dd-mm-yyyy
      final s = dob.replaceAll('/', '-');
      final parts = s.split('-');
      if (parts.length == 3) {
        try {
          if (parts[2].length == 4) {
            final d = int.parse(parts[0]);
            final m = int.parse(parts[1]);
            final y = int.parse(parts[2]);
            dt = DateTime(y, m, d);
          } else if (parts[0].length == 4) {
            final y = int.parse(parts[0]);
            final m = int.parse(parts[1]);
            final d = int.parse(parts[2]);
            dt = DateTime(y, m, d);
          }
        } catch (_) {}
      }
    }
    if (dt == null) return '-';
    final now = DateTime.now();
    int years = now.year - dt.year;
    int months = now.month - dt.month;
    int days = now.day - dt.day;
    if (days < 0) {
      final prevMonth = DateTime(now.year, now.month, 0);
      days += prevMonth.day;
      months -= 1;
    }
    if (months < 0) {
      months += 12;
      years -= 1;
    }
    if (years > 0) return '${years}y ${months}m';
    if (months > 0) return '${months}m ${days}d';
    return '${days} days';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.goats.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final imgPath = _imagePaths.length > i ? _imagePaths[i] : null;
                return Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: imgPath != null
                            ? Image.file(File(imgPath), fit: BoxFit.contain, width: double.infinity)
                            : Container(
                                width: double.infinity,
                                margin: const EdgeInsets.symmetric(horizontal: 24.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300, width: 2),
                                ),
                                height: 320,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image, size: 84, color: Colors.grey[400]),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No image',
                                      style: TextStyle(color: Colors.grey[500], fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 140), // leave space for bottom details
                  ],
                );
              },
            ),

            // Close button top-right
            Positioned(
              right: 12,
              top: 12,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),

            // Left / Right arrows
            Positioned(
              left: 8,
              top: MediaQuery.of(context).size.height / 2 - 24,
              child: IconButton(
                icon: const Icon(Icons.skip_previous, color: Colors.orange),
                onPressed: () {
                  if (_index > 0) {
                    _controller.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  }
                },
              ),
            ),
            Positioned(
              right: 8,
              top: MediaQuery.of(context).size.height / 2 - 24,
              child: IconButton(
                icon: const Icon(Icons.skip_next, color: Colors.orange),
                onPressed: () {
                  if (_index < widget.goats.length - 1) {
                    _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  }
                },
              ),
            ),

            // Bottom details card
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange, width: 3),
                ),
                child: _buildDetails(widget.goats[_index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails(Goat g) {
    final TextStyle labelStyle = const TextStyle(color: Colors.white, fontSize: 16);
    final TextStyle valueStyle = const TextStyle(color: Colors.white, fontSize: 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _row('Tag', g.tagNo, labelStyle, valueStyle),
        _row('Name', g.name ?? '-', labelStyle, valueStyle),
        _row('Gender', g.gender, labelStyle, valueStyle),
        _row('Stage', g.goatStage ?? '-', labelStyle, valueStyle),
        _row('Breed', g.breed ?? '-', labelStyle, valueStyle),
        _row('Group', g.group ?? '-', labelStyle, valueStyle),
        _row('D.O.B', g.dateOfBirth ?? '-', labelStyle, valueStyle),
        _row('Age', _formatAge(g.dateOfBirth), labelStyle, valueStyle),
      ],
    );
  }

  Widget _row(String label, String value, TextStyle labelStyle, TextStyle valueStyle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: labelStyle)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: valueStyle)),
        ],
      ),
    );
  }
}
