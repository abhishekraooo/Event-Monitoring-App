// lib/features/coordinator/scanner/qr_scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for haptic feedback
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  bool _codeDetected =
      false; // NEW: State to track if code is detected for UI feedback

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (BarcodeCapture capture) async {
              print("Scanner raw value: ${capture.barcodes.first.rawValue}");

              if (!_isProcessing) {
                _isProcessing = true;
                final String? code = capture.barcodes.first.rawValue;

                if (code != null) {
                  // --- NEW: Provide immediate feedback ---
                  HapticFeedback.heavyImpact(); // Vibrate the device
                  setState(() {
                    _codeDetected = true; // Change border color to green
                  });

                  // Wait a moment so the user can see the green border
                  await Future.delayed(const Duration(milliseconds: 500));

                  // Pop the screen and return the scanned code
                  if (mounted) {
                    Navigator.of(context).pop(code);
                  }
                } else {
                  _isProcessing = false;
                }
              }
            },
          ),
          // UPDATED: The overlay now changes color on detection
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: _codeDetected
                    ? Colors.green
                    : Colors.white, // Conditional color
                width: 4,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
