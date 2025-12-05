import 'package:flutter/material.dart';

class PregnanciesPage extends StatelessWidget {
  const PregnanciesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Pregnancies Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: SizedBox(height: 4, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFFF9800)))),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Pregnancies Report', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SizedBox(height: 6),
                    Text('Tap on each row to see goat details!', style: TextStyle(color: Color(0xFFFF9800), fontWeight: FontWeight.w600)),
                    SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(side: BorderSide(color: Color(0xFF4CAF50)), borderRadius: BorderRadius.zero),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(child: Text('Tag No.', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold))),
                            Expanded(child: Text('Delivery', textAlign: TextAlign.center)),
                            Expanded(child: Text('Remaining', textAlign: TextAlign.right, style: TextStyle(color: Color(0xFFFFA726), fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    // Empty placeholder for list
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
