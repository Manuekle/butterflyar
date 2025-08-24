// qr_scan_screen.dart
import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' show sin, pi;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:butterflyar/models/butterfly_loader.dart';
import 'package:butterflyar/models/butterfly.dart';
import 'package:butterflyar/screens/animated_butterfly_view.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  MobileScannerController? _scannerController;
  late AnimationController _animationController;
  late Animation<double> _breatheAnimation;
  late Animation<double> _scanLineAnimation;

  bool _isScanning = true;
  bool _hasDetected = false;
  String? _lastScannedCode;
  bool _hasCameraPermission = false;
  bool _hasCameraHardware = false;
  bool _isCheckingPermission = true;
  bool _isFlashOn = false;
  DateTime? _lastScanTime;
  String? _cameraError;
  bool _isControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAnimation();
    _checkCameraPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && !_isCheckingPermission) {
      _recheckCameraPermission();
    }
  }

  void _initAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();

    // Animación de respiración para el marco principal
    _breatheAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Animación más suave para la línea de escaneo
    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeCameraController() async {
    if (_isControllerInitialized) return;

    try {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );

      _isControllerInitialized = true;

      if (mounted) {
        setState(() {
          _hasCameraHardware = true;
          _isCheckingPermission = false;
          _cameraError = null;
        });
      }
    } catch (error) {
      debugPrint('Error creating camera controller: $error');
      if (mounted) {
        setState(() {
          _hasCameraHardware = false;
          _cameraError = 'Error al inicializar la cámara: $error';
          _isCheckingPermission = false;
        });
        _showNoCameraDialog();
      }
    }
  }

  Future<void> _checkCameraPermission() async {
    PermissionStatus status = await Permission.camera.status;

    if (status.isGranted) {
      if (mounted) {
        setState(() {
          _hasCameraPermission = true;
        });
        await _initializeCameraController();
      }
      return;
    }

    if (status.isDenied) {
      final result = await Permission.camera.request();
      if (mounted) {
        setState(() {
          _hasCameraPermission = result.isGranted;
        });
        if (!result.isGranted) {
          setState(() {
            _isCheckingPermission = false;
          });
          _showPermissionDeniedDialog();
          return;
        } else {
          await _initializeCameraController();
        }
      }
      return;
    }

    if (status.isPermanentlyDenied) {
      if (mounted) {
        setState(() {
          _hasCameraPermission = false;
          _isCheckingPermission = false;
        });
        _showPermissionDeniedDialog();
      }
      return;
    }

    if (status.isRestricted) {
      if (mounted) {
        setState(() {
          _hasCameraPermission = false;
          _isCheckingPermission = false;
        });
        _showRestrictedDialog();
      }
      return;
    }

    final result = await Permission.camera.request();
    if (mounted) {
      setState(() {
        _hasCameraPermission = result.isGranted;
      });
      if (!result.isGranted) {
        setState(() {
          _isCheckingPermission = false;
        });
        _showPermissionDeniedDialog();
      } else {
        await _initializeCameraController();
      }
    }
  }

  void _showNoCameraDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              LucideIcons.cameraOff,
              color: Theme.of(context).colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text('Sin Cámara', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text(
          'Este dispositivo no tiene una cámara disponible.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showRestrictedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              LucideIcons.ban,
              color: Theme.of(context).colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text('Acceso Restringido', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text(
          'El acceso a la cámara está restringido en este dispositivo.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _recheckCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted && !_hasCameraPermission) {
      setState(() {
        _hasCameraPermission = true;
      });
      await _initializeCameraController();
    } else if (!status.isGranted && _hasCameraPermission) {
      setState(() {
        _hasCameraPermission = false;
      });
    }
  }

  void _showPermissionDeniedDialog() {
    if (Platform.isIOS) {
      _showCupertinoPermissionDialog();
    } else {
      _showMaterialPermissionDialog();
    }
  }

  void _showCupertinoPermissionDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Permiso de Cámara'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            'Para escanear códigos QR, necesitamos acceso a la cámara.',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Salir'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Configuración'),
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  void _showMaterialPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Permiso de Cámara', style: TextStyle(fontSize: 18)),
        content: const Text(
          'Para escanear códigos QR, necesitamos acceso a la cámara.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Salir'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Configuración'),
          ),
        ],
      ),
    );
  }

  Future<void> _onBarcodeDetect(BarcodeCapture capture) async {
    final now = DateTime.now();
    if (_lastScanTime != null &&
        now.difference(_lastScanTime!).inMilliseconds < 1000) {
      return;
    }

    if (_hasDetected || !_isScanning) return;

    final barcode = capture.barcodes.firstOrNull;
    final code = barcode?.rawValue;

    if (code == null || code.isEmpty) return;
    if (_lastScannedCode == code) return;

    _lastScanTime = now;

    setState(() {
      _hasDetected = true;
      _isScanning = false;
      _lastScannedCode = code;
    });

    try {
      final butterflies = await loadButterfliesFromAssets();
      final butterfly = _findButterflyByCode(butterflies, code);

      if (butterfly != null && mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                AnimatedButterflyView(butterfly: butterfly),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.elasticOut,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      } else {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          _showNotFoundDialog(code);
        }
      }
    } catch (error) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        _showErrorDialog(error.toString());
      }
    }
  }

  Butterfly? _findButterflyByCode(List<Butterfly> butterflies, String code) {
    try {
      return butterflies.firstWhere(
        (b) => b.id.toLowerCase() == code.toLowerCase(),
      );
    } catch (_) {}
    try {
      return butterflies.firstWhere(
        (b) =>
            b.name.toLowerCase().replaceAll(' ', '') ==
            code.toLowerCase().replaceAll(' ', ''),
      );
    } catch (_) {}
    try {
      return butterflies.firstWhere(
        (b) =>
            b.scientificName.toLowerCase().replaceAll(' ', '') ==
            code.toLowerCase().replaceAll(' ', ''),
      );
    } catch (_) {}
    return null;
  }

  void _showNotFoundDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Código no encontrado',
          style: TextStyle(fontSize: 18),
        ),
        content: Text(
          'No se encontró ninguna mariposa con el código: $code',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Salir'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScanner();
            },
            child: const Text('Escanear otro'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Error', style: TextStyle(fontSize: 18)),
        content: Text(
          'Ocurrió un error al buscar la mariposa:\n$error',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Aceptar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScanner();
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  void _resetScanner() {
    setState(() {
      _hasDetected = false;
      _isScanning = true;
      _lastScannedCode = null;
      _lastScanTime = null;
    });
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
    _scannerController?.toggleTorch();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_hasCameraHardware) {
      _scannerController?.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermission) {
      return _buildPermissionCheckingScreen();
    }

    if (!_hasCameraPermission) {
      return _buildNoPermissionScreen();
    }

    if (!_hasCameraHardware) {
      return _buildNoCameraScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Cámara
          MobileScanner(
            controller: _scannerController,
            onDetect: _onBarcodeDetect,
            fit: BoxFit.cover,
          ),

          // Overlay de escaneo minimalista
          _buildMinimalScanOverlay(),

          // Texto de instrucción simple
          _buildSimpleInstruction(),

          // Controles mínimos
          _buildMinimalControls(),

          // Overlay de carga
          if (_hasDetected) _buildMinimalLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildPermissionCheckingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      ),
    );
  }

  Widget _buildNoPermissionScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.camera, size: 64, color: Colors.white70),
              const SizedBox(height: 24),
              const Text(
                'Permiso de Cámara',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Necesitamos acceso a la cámara para escanear códigos QR',
                style: TextStyle(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _checkCameraPermission,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Permitir acceso'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoCameraScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.cameraOff,
                size: 64,
                color: Colors.white70,
              ),
              const SizedBox(height: 24),
              const Text(
                'Cámara no disponible',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Este dispositivo no tiene una cámara disponible',
                style: TextStyle(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          onPressed: _toggleFlash,
          icon: Icon(
            _isFlashOn ? LucideIcons.zap : LucideIcons.zapOff,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalScanOverlay() {
    return Center(
      child: AnimatedBuilder(
        animation: _breatheAnimation,
        builder: (context, child) {
          // Efecto de respiración sutil
          final breatheScale =
              1.0 + (sin(_breatheAnimation.value * 2 * pi) * 0.02);

          return Transform.scale(
            scale: breatheScale,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.8),
                  width: 2,
                ),
              ),
              //child: Stack(
              //children: [
              // Esquinas minimalistas
              // _buildMinimalCorners(),

              // Línea de escaneo sutil
              // if (_isScanning) _buildMinimalScanLine(),
              //],
              //),
            ),
          );
        },
      ),
    );
  }

  // Widget _buildMinimalCorners() {
  //   return Stack(
  //     children: [
  //       // Esquina superior izquierda
  //       const Positioned(
  //         top: -1,
  //         left: -1,
  //         child: _CornerWidget(isTopLeft: true),
  //       ),
  //       // Esquina superior derecha
  //       const Positioned(
  //         top: -1,
  //         right: -1,
  //         child: _CornerWidget(isTopRight: true),
  //       ),
  //       // Esquina inferior izquierda
  //       const Positioned(
  //         bottom: -1,
  //         left: -1,
  //         child: _CornerWidget(isBottomLeft: true),
  //       ),
  //       // Esquina inferior derecha
  //       const Positioned(
  //         bottom: -1,
  //         right: -1,
  //         child: _CornerWidget(isBottomRight: true),
  //       ),
  //     ],
  //   );
  // }

  // Widget _buildMinimalScanLine() {
  //   return AnimatedBuilder(
  //     animation: _scanLineAnimation,
  //     builder: (context, child) {
  //       final progress = sin(_scanLineAnimation.value * 2 * pi) * 0.5 + 0.5;

  //       return Positioned(
  //         left: 16,
  //         right: 16,
  //         top: 16 + (208 * progress),
  //         child: Container(
  //           height: 2,
  //           decoration: BoxDecoration(
  //             gradient: const LinearGradient(
  //               colors: [Colors.transparent, Colors.white, Colors.transparent],
  //             ),
  //             borderRadius: BorderRadius.circular(1),
  //             boxShadow: [
  //               BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 4),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildSimpleInstruction() {
    return Positioned(
      bottom: 160,
      left: 0,
      right: 0,
      child: Center(
        child: Text(
          _isScanning ? 'Escanea el código QR' : 'Procesando...',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalControls() {
    return Positioned(
      bottom: 60,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.x, color: Colors.white),
                iconSize: 20,
              ),
              const SizedBox(width: 20),
              IconButton(
                onPressed: _resetScanner,
                icon: const Icon(LucideIcons.refreshCw, color: Colors.white),
                iconSize: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            SizedBox(height: 24),
            Text(
              'Buscando...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerWidget extends StatelessWidget {
  const _CornerWidget({
    this.isTopLeft = false,
    this.isTopRight = false,
    this.isBottomLeft = false,
    this.isBottomRight = false,
  });

  final bool isTopLeft;
  final bool isTopRight;
  final bool isBottomLeft;
  final bool isBottomRight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border(
          top: isTopLeft || isTopRight
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
          left: isTopLeft || isBottomLeft
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
          right: isTopRight || isBottomRight
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
          bottom: isBottomLeft || isBottomRight
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: isTopLeft ? const Radius.circular(3) : Radius.zero,
          topRight: isTopRight ? const Radius.circular(3) : Radius.zero,
          bottomLeft: isBottomLeft ? const Radius.circular(3) : Radius.zero,
          bottomRight: isBottomRight ? const Radius.circular(3) : Radius.zero,
        ),
      ),
    );
  }
}
