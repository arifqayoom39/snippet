import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snippet/theme/pallete.dart';
import 'package:snippet/common/rounded_button.dart';

class UpiPaymentPage extends ConsumerStatefulWidget {
  final WidgetRef ref;
  
  const UpiPaymentPage({
    Key? key,
    required this.ref,
  }) : super(key: key);

  @override
  ConsumerState<UpiPaymentPage> createState() => _UpiPaymentPageState();
}

class _UpiPaymentPageState extends ConsumerState<UpiPaymentPage> {
  final TextEditingController _upiIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  bool _showQR = false;
  bool _isGenerating = false;
  String _upiString = '';
  
  @override
  void dispose() {
    _upiIdController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
  
  void _generateQRCode() {
    if (_upiIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('UPI ID is required')),
      );
      return;
    }
    
    setState(() {
      _isGenerating = true;
    });
    
    // Simulate processing
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _upiString = "upi://pay?pa=${_upiIdController.text}" + 
                    "&pn=${Uri.encodeComponent(_nameController.text)}" +
                    (_amountController.text.isNotEmpty ? "&am=${_amountController.text}" : "") +
                    (_noteController.text.isNotEmpty ? "&tn=${Uri.encodeComponent(_noteController.text)}" : "");
        _showQR = true;
        _isGenerating = false;
      });
    });
  }

  void _shareUpiDetails() {
    // Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR code shared successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.backgroundColor,
      appBar: AppBar(
        backgroundColor: Pallete.backgroundColor,
        title: Text(
          'UPI Payment',
          style: TextStyle(
            color: Pallete.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Pallete.iconColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_showQR) ...[
              Text(
                'Generate a UPI payment QR code',
                style: TextStyle(
                  color: Pallete.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _upiIdController,
                decoration: InputDecoration(
                  labelText: 'UPI ID (required)',
                  labelStyle: TextStyle(color: Pallete.greyColor),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Pallete.greyColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Pallete.blueColor),
                  ),
                ),
                style: TextStyle(color: Pallete.textColor),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name (optional)',
                  labelStyle: TextStyle(color: Pallete.greyColor),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Pallete.greyColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Pallete.blueColor),
                  ),
                ),
                style: TextStyle(color: Pallete.textColor),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (optional)',
                  labelStyle: TextStyle(color: Pallete.greyColor),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Pallete.greyColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Pallete.blueColor),
                  ),
                ),
                style: TextStyle(color: Pallete.textColor),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Note (optional)',
                  labelStyle: TextStyle(color: Pallete.greyColor),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Pallete.greyColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Pallete.blueColor),
                  ),
                ),
                style: TextStyle(color: Pallete.textColor),
              ),
              const SizedBox(height: 32),
              RoundedButton(
                onTap: _generateQRCode,
                label: 'Generate QR Code',
                isLoading: _isGenerating,
              ),
            ] else ...[
              Align(
                alignment: Alignment.center,
                child: Column(
                  children: [
                    // QR Code container
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Pallete.greyColor),
                      ),
                      child: CustomPaint(
                        painter: SimpleQRPainter(
                          data: _upiString,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'UPI: ${_upiIdController.text}',
                      style: TextStyle(
                        color: Pallete.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_nameController.text.isNotEmpty)
                      Text(
                        'Name: ${_nameController.text}',
                        style: TextStyle(color: Pallete.textColor),
                      ),
                    if (_amountController.text.isNotEmpty)
                      Text(
                        'Amount: ₹${_amountController.text}',
                        style: TextStyle(color: Pallete.textColor),
                      ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _shareUpiDetails,
                          icon: Icon(Icons.share, color: Pallete.textColor),
                          label: Text('Share', style: TextStyle(color: Pallete.textColor)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Pallete.backgroundColor,
                            side: BorderSide(color: Pallete.greyColor),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showQR = false;
                            });
                          },
                          icon: Icon(Icons.edit, color: Pallete.textColor),
                          label: Text('Edit', style: TextStyle(color: Pallete.textColor)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Pallete.backgroundColor,
                            side: BorderSide(color: Pallete.greyColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// A simple QR painter that creates a visual representation
class SimpleQRPainter extends CustomPainter {
  final String data;
  
  SimpleQRPainter({required this.data});
  
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;
    
    // Draw outer frame
    canvas.drawRect(
      Rect.fromLTWH(10, 10, size.width - 20, size.height - 20),
      paint,
    );
    
    // Draw position detection patterns (corners)
    _drawPositionDetection(canvas, 30, 30, 30, paint);
    _drawPositionDetection(canvas, size.width - 60, 30, 30, paint);
    _drawPositionDetection(canvas, 30, size.height - 60, 30, paint);
    
    // Draw some random "data" dots based on the input string
    final int seedValue = data.codeUnits.fold(0, (prev, element) => prev + element);
    final random = _SeededRandom(seedValue);
    
    for (int i = 0; i < 100; i++) {
      final x = 70 + random.nextDouble() * (size.width - 140);
      final y = 70 + random.nextDouble() * (size.height - 140);
      
      canvas.drawRect(
        Rect.fromLTWH(x, y, 5, 5),
        paint,
      );
    }
  }
  
  void _drawPositionDetection(Canvas canvas, double x, double y, double size, Paint paint) {
    // Outer square
    canvas.drawRect(
      Rect.fromLTWH(x, y, size, size),
      paint,
    );
    
    // Inner square (white)
    final Paint whitePaint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(x + 5, y + 5, size - 10, size - 10),
      whitePaint,
    );
    
    // Center square
    canvas.drawRect(
      Rect.fromLTWH(x + 10, y + 10, size - 20, size - 20),
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// A simple seeded random number generator
class _SeededRandom {
  int _seed;
  
  _SeededRandom(this._seed);
  
  double nextDouble() {
    _seed = (_seed * 9301 + 49297) % 233280;
    return _seed / 233280.0;
  }
}
