import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Full-screen barcode & QR scanner. Pops with the first non-empty [String] value.
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key, required this.t});

  final String Function(String) t;

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  late final MobileScannerController _controller;
  bool _didPop = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_didPop || !mounted) return;
    for (final b in capture.barcodes) {
      final v = b.rawValue ?? b.displayValue;
      if (v != null && v.trim().isNotEmpty) {
        _didPop = true;
        await _controller.stop();
        if (mounted) Navigator.of(context).pop<String>(v.trim());
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(t('food_scan_title')),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, _) {
              if (state.torchState == TorchState.unavailable) {
                return const SizedBox.shrink();
              }
              final on = state.torchState == TorchState.on ||
                  state.torchState == TorchState.auto;
              return IconButton(
                tooltip: t('food_scan_torch'),
                onPressed: () => _controller.toggleTorch(),
                icon: Icon(on ? Icons.flash_on_rounded : Icons.flash_off_rounded),
              );
            },
          ),
          IconButton(
            tooltip: t('food_cancel'),
            onPressed: () => Navigator.of(context).pop<String?>(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, MobileScannerException _) =>
                _ScanErrorMessage(
              message: t('food_scan_permission_denied'),
              buttonLabel: t('food_cancel'),
              onClose: () => Navigator.of(context).pop<String?>(),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
              child: Text(
                t('food_scan_hint'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanErrorMessage extends StatelessWidget {
  const _ScanErrorMessage({
    required this.message,
    required this.buttonLabel,
    required this.onClose,
  });

  final String message;
  final String buttonLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam_off_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade300, fontSize: 15),
                ),
                const SizedBox(height: 24),
                FilledButton.tonal(
                  onPressed: onClose,
                  child: Text(buttonLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
