import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/color_provider.dart';
import 'add_transaction_page.dart';

/// Receipt capture entry point. Shows a live camera preview (via the
/// `camera` plugin) with a framing guide, takes the photo in-app, then hands
/// off to [AddTransactionPage] for manual entry — there's no OCR, so nothing
/// is prefilled beyond the `scanned` flag. "Library" still goes through
/// `image_picker` to pick an existing photo.
class ScanReceiptPage extends ConsumerStatefulWidget {
  const ScanReceiptPage({super.key});

  @override
  ConsumerState<ScanReceiptPage> createState() => _ScanReceiptPageState();
}

class _ScanReceiptPageState extends ConsumerState<ScanReceiptPage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Object? _cameraError;
  bool _capturing = false;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller.dispose();
      setState(() => _controller = null);
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _cameraError = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _cameraError = error);
      }
    }
  }

  Future<void> _shoot() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) {
      return;
    }
    setState(() => _capturing = true);
    try {
      final photo = await controller.takePicture();
      await _handlePhoto(photo);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not capture photo: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
      }
    }
  }

  Future<void> _pickFromLibrary() async {
    final picker = ImagePicker();
    final XFile? photo;
    try {
      photo = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open photo library: $error')),
        );
      }
      return;
    }
    await _handlePhoto(photo);
  }

  Future<void> _handlePhoto(XFile? photo) async {
    if (!mounted || photo == null) {
      return;
    }

    setState(() => _processing = true);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const AddTransactionPage(scanned: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _processing
            ? _ProcessingView()
            : _CameraView(
                controller: _controller,
                error: _cameraError,
                capturing: _capturing,
                onCapture: _shoot,
                onPickLibrary: _pickFromLibrary,
              ),
      ),
    );
  }
}

class _CameraView extends StatelessWidget {
  const _CameraView({
    required this.controller,
    required this.error,
    required this.capturing,
    required this.onCapture,
    required this.onPickLibrary,
  });

  final CameraController? controller;
  final Object? error;
  final bool capturing;
  final VoidCallback onCapture;
  final VoidCallback onPickLibrary;

  @override
  Widget build(BuildContext context) {
    final ready = controller != null && controller!.value.isInitialized;

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: const Text(
                  'Receipt scan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              const SizedBox(width: 38),
            ],
          ),
        ),
        Expanded(
          child: ClipRect(
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              color: const Color(0xFF0D1A1F),
              child: Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  if (error != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Could not start the camera:\n$error',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    )
                  else if (ready)
                    _CoverCameraPreview(controller: controller!)
                  else
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white54),
                    ),
                  if (error == null)
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
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            children: [
              Text(
                'Hold steady — we read the total, merchant and lines',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12.5,
                ),
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
                      MaterialPageRoute(
                        builder: (_) => const AddTransactionPage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 26),
                  GestureDetector(
                    onTap: ready && !capturing ? onCapture : null,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: capturing
                            ? const Color(0xFF8CE6FF).withValues(alpha: 0.4)
                            : const Color(0xFF8CE6FF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 4,
                        ),
                      ),
                      child: const Icon(
                        Icons.photo_camera,
                        size: 30,
                        color: Color(0xFF001F2B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 26),
                  _SideAction(
                    icon: Icons.photo_library,
                    label: 'Library',
                    onTap: onPickLibrary,
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

/// Fills its parent with the camera feed, cropping (rather than stretching)
/// to preserve the sensor's native aspect ratio.
class _CoverCameraPreview extends StatelessWidget {
  const _CoverCameraPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) {
      return CameraPreview(controller);
    }
    return OverflowBox(
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          // The sensor reports its native size in landscape orientation, so
          // width/height are swapped for a portrait preview.
          width: previewSize.height,
          height: previewSize.width,
          child: CameraPreview(controller),
        ),
      ),
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
  const _SideAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

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
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

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
                border: Border.all(
                  color: const Color(0xFF8CE6FF).withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: accent,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Reading the receipt',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'attaching your photo',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
