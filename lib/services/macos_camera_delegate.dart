import 'package:camera_macos/camera_macos.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

/// Lets `image_picker`'s `ImageSource.camera` work on macOS.
///
/// `image_picker_macos` has no built-in camera implementation — it requires
/// an explicit [ImagePickerCameraDelegate] to be set on
/// [ImagePickerPlatform.instance], or `ImageSource.camera` throws a
/// [StateError]. This delegate fulfils that by pushing [_MacosCameraCapturePage]
/// on the app's root navigator and using `camera_macos` to drive the capture.
class MacosCameraDelegate implements ImagePickerCameraDelegate {
  const MacosCameraDelegate(this.navigatorKey);

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Future<XFile?> takePhoto({
    ImagePickerCameraDelegateOptions options =
        const ImagePickerCameraDelegateOptions(),
  }) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return null;
    }
    return navigator.push<XFile?>(
      MaterialPageRoute(builder: (_) => const _MacosCameraCapturePage()),
    );
  }

  @override
  Future<XFile?> takeVideo({
    ImagePickerCameraDelegateOptions options =
        const ImagePickerCameraDelegateOptions(),
  }) {
    throw UnimplementedError('This app never records video.');
  }
}

class _MacosCameraCapturePage extends StatefulWidget {
  const _MacosCameraCapturePage();

  @override
  State<_MacosCameraCapturePage> createState() =>
      _MacosCameraCapturePageState();
}

class _MacosCameraCapturePageState extends State<_MacosCameraCapturePage> {
  CameraMacOSController? _controller;
  bool _capturing = false;
  Object? _initError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (_initError != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not start the camera:\n$_initError',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
            else
              Positioned.fill(
                child: CameraMacOSView(
                  cameraMode: CameraMacOSMode.photo,
                  pictureFormat: PictureFormat.jpg,
                  fit: BoxFit.cover,
                  onCameraInizialized: (controller) {
                    setState(() => _controller = controller);
                  },
                  onCameraLoading: (_) =>
                      const Center(child: CircularProgressIndicator()),
                ),
              ),
            Positioned(
              top: 12,
              left: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: Center(
                child: GestureDetector(
                  onTap: _controller == null || _capturing ? null : _capture,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _capturing ? Colors.grey : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      if (!mounted) {
        return;
      }
      final bytes = file?.bytes;
      if (bytes == null) {
        setState(() => _capturing = false);
        return;
      }
      Navigator.of(
        context,
      ).pop(XFile.fromData(bytes, name: 'receipt.jpg', mimeType: 'image/jpeg'));
    } catch (error) {
      if (mounted) {
        setState(() {
          _capturing = false;
          _initError = error;
        });
      }
    }
  }
}
