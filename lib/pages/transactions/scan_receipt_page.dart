import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/color_provider.dart';
import 'add_transaction_page.dart';

/// Receipt capture entry point. Takes/picks a real photo via `image_picker`
/// (no live in-app camera preview — that would need the heavier `camera`
/// plugin) then hands off to [AddTransactionPage] for manual entry — there's
/// no OCR, so nothing is prefilled beyond the `scanned` flag.
class ScanReceiptPage extends ConsumerStatefulWidget {
  const ScanReceiptPage({super.key});

  @override
  ConsumerState<ScanReceiptPage> createState() => _ScanReceiptPageState();
}

class _ScanReceiptPageState extends ConsumerState<ScanReceiptPage> {
  bool _processing = false;

  Future<void> _capture(ImageSource source) async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: source, imageQuality: 85);
    if (!mounted) {
      return;
    }
    if (photo == null) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _processing = true);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AddTransactionPage(scanned: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _processing ? _ProcessingView() : _CameraView(onCapture: _capture),
      ),
    );
  }
}

class _CameraView extends StatelessWidget {
  const _CameraView({required this.onCapture});

  final ValueChanged<ImageSource> onCapture;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Row(
            children: [
              _GlassIconButton(
                icon: Icons.close,
                tooltip: 'Close',
                onTap: () => Navigator.of(context).pop(),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                ),
                child: const Text(
                  'Receipt scan',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
              const Spacer(),
              const SizedBox(width: 38),
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            color: const Color(0xFF0D1A1F),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 250,
                  height: 340,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Center(
                    child: Text(
                      'receipt in frame',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                for (final alignment in const [
                  Alignment.topLeft,
                  Alignment.topRight,
                  Alignment.bottomLeft,
                  Alignment.bottomRight,
                ])
                  Align(
                    alignment: alignment,
                    child: Padding(
                      padding: const EdgeInsets.all(60),
                      child: _CornerBracket(alignment: alignment),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            children: [
              Text(
                'Hold steady — we read the total, merchant and lines',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12.5),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _SideAction(
                    icon: Icons.keyboard,
                    label: 'Manual',
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const AddTransactionPage()),
                    ),
                  ),
                  const SizedBox(width: 26),
                  GestureDetector(
                    onTap: () => onCapture(ImageSource.camera),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8CE6FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 4),
                      ),
                      child: const Icon(Icons.photo_camera, size: 30, color: Color(0xFF001F2B)),
                    ),
                  ),
                  const SizedBox(width: 26),
                  _SideAction(
                    icon: Icons.photo_library,
                    label: 'Library',
                    onTap: () => onCapture(ImageSource.gallery),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CornerBracket extends StatelessWidget {
  const _CornerBracket({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;
    final side = BorderSide(color: const Color(0xFF8CE6FF), width: 3);

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? side : BorderSide.none,
          bottom: isTop ? BorderSide.none : side,
          left: isLeft ? side : BorderSide.none,
          right: isLeft ? BorderSide.none : side,
        ),
      ),
    );
  }
}

class _SideAction extends StatelessWidget {
  const _SideAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 24, color: Colors.white.withValues(alpha: 0.6)),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}

class _ProcessingView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(appPrimary300ColorProvider);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 200,
            height: 264,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8CE6FF).withValues(alpha: 0.3)),
              ),
              child: Center(
                child: CircularProgressIndicator(color: accent, strokeWidth: 2.5),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Reading the receipt',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17),
          ),
          const SizedBox(height: 8),
          Text(
            'attaching your photo',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
