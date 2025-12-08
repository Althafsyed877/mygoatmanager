import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/goat.dart';
import 'package:mygoatmanager/l10n/app_localizations.dart';

class GoatsReportPage extends StatefulWidget {
  const GoatsReportPage({super.key});

  @override
  State<GoatsReportPage> createState() => _GoatsReportPageState();
}

class _GoatsReportPageState extends State<GoatsReportPage> {
  List<Goat> _goats = [];
  List<Goat> _filteredGoats = [];
  String selectedBreed = 'All Breeds';
  String selectedGroup = 'All Groups';
  String selectedSource = 'All Sources';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoats();
  }

  // Getter methods for localized lists
  List<String> _getStages(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return [loc.does, loc.doelings, loc.bucks, loc.bucklings, loc.wethers, loc.kids];
  }

  List<String> _getBreeds(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return [loc.allBreeds, 'Alpine', 'Boer', 'Kiko', 'Nubian'];
  }

  List<String> _getGroups(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return [loc.allGroups, loc.milk];
  }

  List<String> _getSources(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return [loc.allSources, loc.bornOnFarm, loc.purchased, loc.other];
  }

  Future<void> _loadGoats() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? goatsJson = prefs.getString('goats');
      
      if (mounted) {
        setState(() {
          if (goatsJson != null) {
            try {
              final List<dynamic> decoded = jsonDecode(goatsJson);
              _goats = decoded.map((e) => Goat.fromJson(Map<String, dynamic>.from(e))).toList();
              _applyFilters();
            } catch (e) {
              debugPrint('Error parsing goats: $e');
              _goats = [];
              _filteredGoats = [];
            }
          } else {
            _goats = [];
            _filteredGoats = [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _goats = [];
          _filteredGoats = [];
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    final loc = AppLocalizations.of(context);
    if (loc == null) return;
    
    List<Goat> filtered = List.from(_goats);

    // Convert selectedBreed to English if it's "All Breeds"
    final englishAllBreeds = 'All Breeds';
    final currentBreed = selectedBreed == loc.allBreeds ? englishAllBreeds : selectedBreed;
    
    if (currentBreed != englishAllBreeds) {
      filtered = filtered.where((goat) => goat.breed == currentBreed).toList();
    }

    // Convert selectedGroup to English if it's "All Groups"
    final englishAllGroups = 'All Groups';
    final currentGroup = selectedGroup == loc.allGroups ? englishAllGroups : selectedGroup;
    
    if (currentGroup != englishAllGroups) {
      filtered = filtered.where((goat) => goat.group == currentGroup).toList();
    }

    // Handle source filtering
    if (selectedSource != loc.allSources) {
      filtered = filtered.where((goat) {
        final obtained = (goat.obtained ?? '').toLowerCase();
        if (selectedSource == loc.bornOnFarm) return obtained.contains('born');
        if (selectedSource == loc.purchased) return obtained.contains('purchased');
        if (selectedSource == loc.other) return obtained.contains('other') || obtained.contains('gift');
        return true;
      }).toList();
    }

    setState(() {
      _filteredGoats = filtered;
    });
  }

  String _getCorrectedStage(Goat goat) {
    final gender = (goat.gender ?? '').toLowerCase();
    final stage = (goat.goatStage ?? '').toLowerCase();
    
    // Handle English stage names that might be stored in the database
    if (gender == 'male') {
      switch (stage) {
        case 'kid':
        case 'kids':
          return 'kids';
        case 'buckling':
        case 'bucklings':
          return 'bucklings';
        case 'buck':
        case 'bucks':
          return 'bucks';
        case 'wether':
        case 'wethers':
          return 'wethers';
        default:
          return 'kids';
      }
    } else if (gender == 'female') {
      switch (stage) {
        case 'kid':
        case 'kids':
          return 'kids';
        case 'doeling':
        case 'doelings':
          return 'doelings';
        case 'doe':
        case 'does':
          return 'does';
        default:
          return 'kids';
      }
    }
    
    return 'kids';
  }

  int _countStage(BuildContext context, String stage) {
    final loc = AppLocalizations.of(context);
    if (loc == null) return 0;
    
    // Map localized stage names to their English equivalents
    final Map<String, String> stageMapping = {
      loc.does.toLowerCase(): 'does',
      loc.doelings.toLowerCase(): 'doelings',
      loc.bucks.toLowerCase(): 'bucks',
      loc.bucklings.toLowerCase(): 'bucklings',
      loc.wethers.toLowerCase(): 'wethers',
      loc.kids.toLowerCase(): 'kids',
    };
    
    // Get the English equivalent of the localized stage
    final englishStage = stageMapping[stage.toLowerCase()];
    
    if (englishStage == null) {
      return 0;
    }
    
    return _filteredGoats.where((g) {
      final correctedStage = _getCorrectedStage(g);
      // Compare with English stage name (what's stored in _getCorrectedStage)
      return correctedStage == englishStage;
    }).length;
  }

  Future<void> _exportGoatsPdf() async {
    final loc = AppLocalizations.of(context);
    if (loc == null) return;
    
    final stages = _getStages(context);
    
    try {
      // Check if there's data to export
      if (_filteredGoats.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.noGoatsDataToExport))
        );
        return;
      }

      final doc = pw.Document();

      // Load logo
      Uint8List? logoBytes;
      try {
        final ByteData data = await rootBundle.load('assets/images/goat.png');
        logoBytes = data.buffer.asUint8List();
      } catch (e) {
        debugPrint('Logo loading failed: $e');
      }

      final now = DateTime.now();
      final dateStr = '${now.month}/${now.day}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

      // Use context-aware stage counting
      final stageRows = stages.map((s) => [s, _countStage(context, s).toString()]);
      
      final male = _filteredGoats.where((g) => (g.gender ?? '').toLowerCase() == 'male').length;
      final female = _filteredGoats.where((g) => (g.gender ?? '').toLowerCase() == 'female').length;

      final maleKids = _filteredGoats.where((g) => 
        _getCorrectedStage(g) == 'kids' && 
        (g.gender ?? '').toLowerCase() == 'male'
      ).length;
      
      final femaleKids = _filteredGoats.where((g) => 
        _getCorrectedStage(g) == 'kids' && 
        (g.gender ?? '').toLowerCase() == 'female'
      ).length;

      // FIX: Changed 'context' parameter name to 'pdfContext' to avoid conflict
      doc.addPage(
        pw.Page(
          pageFormat: pdf.PdfPageFormat.a4,
          build: (pw.Context pdfContext) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  children: [
                    if (logoBytes != null) 
                      pw.Container(
                        width: 50,
                        height: 50,
                        child: pw.Image(pw.MemoryImage(logoBytes)),
                      ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            loc.goatsReport,
                            style: pw.TextStyle(
                              fontSize: 16, 
                              fontWeight: pw.FontWeight.bold,
                              color: pdf.PdfColors.green800,
                            ),
                          ),
                          pw.Text(
                            '${loc.date}: $dateStr',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                          pw.Text(
                            '${loc.breed}: $selectedBreed | ${loc.group}: $selectedGroup | ${loc.source}: $selectedSource',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Stages Summary
                pw.Text(
                  loc.stagesSummary,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: pdf.PdfColors.green700,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(color: pdf.PdfColors.grey300, width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: pdf.PdfColors.grey100),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(loc.stage, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(loc.count, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...stageRows.map((row) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(row[0]),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(row[1]),
                        ),
                      ],
                    )),
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: pdf.PdfColors.grey100),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(loc.total, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(_filteredGoats.length.toString(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Gender Summary
                pw.Text(
                  loc.genderSummary,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: pdf.PdfColors.green700,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(color: pdf.PdfColors.grey300, width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: pdf.PdfColors.grey100),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(loc.gender, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(loc.count, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(loc.male),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(male.toString()),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(loc.female),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(female.toString()),
                        ),
                      ],
                    ),
                  ],
                ),

                if (_countStage(context, loc.kids) > 0) ...[
                  pw.SizedBox(height: 15),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: pdf.PdfColors.grey400),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          loc.kids,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          '(${loc.male} = $maleKids, ${loc.female} = $femaleKids)',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      );

      // Save and share PDF
      final bytes = await doc.save();
      await Printing.sharePdf(
        bytes: bytes, 
        filename: 'goats_report_${now.millisecondsSinceEpoch}.pdf'
      );

    } catch (e) {
      debugPrint('PDF export error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.failedToExportPdf}: ${e.toString()}'))
      );
    }
  }

  void _showFilterDialog() {
    final loc = AppLocalizations.of(context);
    if (loc == null) return;
    
    final sources = _getSources(context);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with gradient orange line
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      loc.filterBySource,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF424242),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Gradient orange line
                  PreferredSize(
                    preferredSize: const Size.fromHeight(4),
                    child: Container(
                      height: 4,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                        ),
                      ),
                    ),
                  ),
                  
                  // ONLY SOURCE Selection
                  _buildFilterSection(
                    title: loc.source,
                    options: sources,
                    currentSelection: selectedSource,
                    onSelected: (value) {
                      setState(() {
                        selectedSource = value;
                      });
                      _applyFilters();
                      Navigator.pop(context);
                    },
                  ),

                  // Close Button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[700],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          loc.close,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterSection({
    required String title,
    required List<String> options,
    required String currentSelection,
    required Function(String) onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: options.map((option) => InkWell(
                onTap: () => onSelected(option),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: option == options.last 
                          ? BorderSide.none
                          : BorderSide(color: Colors.grey.shade200),
                    ),
                    color: currentSelection == option 
                        ? Colors.teal.withAlpha(25) // 10% opacity equivalent
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 16,
                            color: currentSelection == option 
                                ? Colors.teal[700]
                                : Colors.black87,
                            fontWeight: currentSelection == option 
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (currentSelection == option)
                        Icon(
                          Icons.check,
                          color: Colors.teal[700],
                          size: 20,
                        ),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  void _showGroupPicker() {
    final loc = AppLocalizations.of(context);
    if (loc == null) return;
    
    final groups = _getGroups(context);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient orange line
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    loc.selectGroup,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Gradient orange line
                PreferredSize(
                  preferredSize: const Size.fromHeight(4),
                  child: Container(
                    height: 4,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                      ),
                    ),
                  ),
                ),
                
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedGroup = group;
                          });
                          _applyFilters();
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: index == groups.length - 1
                                  ? BorderSide.none
                                  : BorderSide(color: Colors.grey.shade200),
                            ),
                            color: selectedGroup == group
                                ? Colors.teal.withAlpha(25) // 10% opacity equivalent
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  group,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: selectedGroup == group
                                        ? Colors.teal[700]
                                        : Colors.black87,
                                    fontWeight: selectedGroup == group
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (selectedGroup == group)
                                Icon(
                                  Icons.check,
                                  color: Colors.teal[700],
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[700],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        loc.close,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final stages = _getStages(context);
    final breeds = _getBreeds(context);
    
    final total = _filteredGoats.length;
    final maleCount = _filteredGoats.where((g) => (g.gender ?? '').toLowerCase() == 'male').length;
    final femaleCount = _filteredGoats.where((g) => (g.gender ?? '').toLowerCase() == 'female').length;

    final maleKids = _filteredGoats.where((g) => 
      _getCorrectedStage(g) == 'kids' && 
      (g.gender ?? '').toLowerCase() == 'male'
    ).length;
    
    final femaleKids = _filteredGoats.where((g) => 
      _getCorrectedStage(g) == 'kids' && 
      (g.gender ?? '').toLowerCase() == 'female'
    ).length;

    // FIX: Calculate kids count directly
    final kidsCountDirect = _filteredGoats.where((g) {
      final stage = _getCorrectedStage(g);
      return stage == 'kids';
    }).length;

    final malePercentage = total > 0 ? maleCount / total : 0.0;
    final femalePercentage = total > 0 ? femaleCount / total : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              selectedBreed,
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (String value) {
                setState(() {
                  selectedBreed = value;
                });
                _applyFilters();
              },
              itemBuilder: (BuildContext context) => breeds.map((breed) => 
                PopupMenuItem(value: breed, child: Text(breed))
              ).toList(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 24),
              offset: const Offset(0, 50),
            ),
          ],
        ),
        actions: [
          // PDF icon
          IconButton(
            tooltip: loc.exportPdf,
            onPressed: _exportGoatsPdf,
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 24),
          ),
          // Filter icon
          IconButton(
            tooltip: loc.filter,
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list, color: Colors.white, size: 24),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Group Selection Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _showGroupPicker,
                  child: Row(
                    children: [
                      Text(
                        selectedGroup,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: Colors.black87, size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                    ),
                  )
                : SafeArea(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Total Goats Card
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32),
                                borderRadius: BorderRadius.circular(4)
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      loc.goatsTotal, 
                                      style: const TextStyle(
                                        color: Colors.white, 
                                        fontSize: 18, 
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$total', 
                                    style: const TextStyle(
                                      color: Colors.white, 
                                      fontSize: 18, 
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Stages List
                            Column(
                              children: stages.map((stage) {
                                final count = _countStage(context, stage);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        stage,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        '$count',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF4CAF50),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 16),
                            
                            // Kids Details - FIXED syntax error
                            if (kidsCountDirect > 0) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.kids,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '(${loc.male} = $maleKids, ${loc.female} = $femaleKids)',
                                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Charts Section
                            Text(
                              loc.goatsByStage, 
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)
                            ),
                            const SizedBox(height: 12),

                            // Stage Chart
                            Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 200,
                                    height: 200,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF2196F3),
                                    ),
                                  ),
                                  Container(
                                    width: 110,
                                    height: 110,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '$total', 
                                            style: const TextStyle(
                                              fontSize: 20, 
                                              fontWeight: FontWeight.bold
                                            )
                                          ),
                                          Text(
                                            loc.total, 
                                            style: const TextStyle(fontSize: 14, color: Colors.grey)
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Gender Chart
                            Text(
                              loc.goatsByGender, 
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)
                            ),
                            const SizedBox(height: 12),

                            Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 200,
                                    height: 200,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey,
                                    ),
                                    child: CustomPaint(
                                      painter: GenderCirclePainter(
                                        malePercentage: malePercentage,
                                        femalePercentage: femalePercentage,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 110,
                                    height: 110,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '$total', 
                                            style: const TextStyle(
                                              fontSize: 20, 
                                              fontWeight: FontWeight.bold
                                            )
                                          ),
                                          Text(
                                            loc.total, 
                                            style: const TextStyle(fontSize: 14, color: Colors.grey)
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Gender Indicators - FIXED: Actually call this method
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildGenderIndicator(loc.male, maleCount, const Color(0xFF4CAF50)),
                                  _buildGenderIndicator(loc.female, femaleCount, const Color(0xFFFFA726)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderIndicator(String gender, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          gender,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class GenderCirclePainter extends CustomPainter {
  final double malePercentage;
  final double femalePercentage;

  GenderCirclePainter({
    required this.malePercentage,
    required this.femalePercentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final malePaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.fill;

    final femalePaint = Paint()
      ..color = const Color(0xFFFFA726)
      ..style = PaintingStyle.fill;

    if (malePercentage > 0) {
      final maleSweepAngle = 2 * 3.14159 * malePercentage;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159 / 2,
        maleSweepAngle,
        true,
        malePaint,
      );
    }

    if (femalePercentage > 0) {
      final femaleSweepAngle = 2 * 3.14159 * femalePercentage;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159 / 2 + (2 * 3.14159 * malePercentage),
        femaleSweepAngle,
        true,
        femalePaint,
      );
    }

    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.55, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}