// Feature: scan a QR code. Shows the camera; when a code is read it is
// stored in the Inbox (see receive_card.dart) and its card is opened.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../l10n/generated/app_localizations.dart';
import 'receive_card.dart';

/// Builds the camera view; calls `onScanned` with each QR code's text.
typedef ScannerBuilder =
    Widget Function(BuildContext context, ValueChanged<String> onScanned);

/// The camera scanner. Tests replace it with a fake that "scans" fixed text,
/// since there is no camera in a test.
final scannerBuilderProvider = Provider<ScannerBuilder>(
  (ref) =>
      (context, onScanned) => _CameraScanner(onScanned: onScanned),
);

/// Full-screen QR scanner.
class ScanScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

/// Ignores further codes while one is being handled.
class _ScanScreenState extends ConsumerState<ScanScreen> {
  bool _busy = false;

  /// Text of the last code that was rejected or cancelled. The camera keeps
  /// seeing a code while it is in view, so without this the message or the
  /// duplicate question would repeat many times a second.
  String? _lastRejected;

  /// Stores the scanned contact and opens it in the Inbox.
  Future<void> _onScanned(String text) async {
    if (_busy || text == _lastRejected) return;
    _busy = true;
    final id = await receiveScanned(context, ref, text);
    _busy = false;
    if (!mounted) return;
    if (id == null) {
      _lastRejected = text;
      return;
    }
    context.go('/inbox/$id');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scanner = ref.watch(scannerBuilderProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scanQr)),
      body: Stack(
        children: [
          Positioned.fill(child: scanner(context, _onScanned)),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.black54,
              child: SafeArea(
                top: false,
                child: Text(
                  l10n.scanHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Live camera preview that reports QR codes (mobile_scanner).
class _CameraScanner extends StatefulWidget {
  const _CameraScanner({required this.onScanned});

  /// Called with each detected QR code's text.
  final ValueChanged<String> onScanned;

  @override
  State<_CameraScanner> createState() => _CameraScannerState();
}

/// Owns the camera controller so the camera is released on leave.
class _CameraScannerState extends State<_CameraScanner> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MobileScanner(
    controller: _controller,
    onDetect: (capture) {
      for (final code in capture.barcodes) {
        final text = code.rawValue;
        if (text != null && text.isNotEmpty) {
          widget.onScanned(text);
          return;
        }
      }
    },
    errorBuilder: (context, _) => Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          AppLocalizations.of(context).cameraError,
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
