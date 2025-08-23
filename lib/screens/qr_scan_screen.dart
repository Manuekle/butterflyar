// qr_scan_screen.dart
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:butterfliesar/models/butterfly_loader.dart';
import 'package:butterfliesar/models/butterfly.dart';
import 'package:butterfliesar/screens/animated_butterfly_view.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  MobileScannerController? _scannerController;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _slideAnimation;

  bool _isScanning = true;
  bool _hasDetected = false;
  String? _lastScannedCode;
  bool _hasCameraPermission = false;
  bool _hasCameraHardware = false;
  bool _isCheckingPermission = true;
  bool _isFlashOn = false;
  DateTime? _lastScanTime;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAnimation();
    _checkCameraAvailability();
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
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );
  }

  Future<void> _checkCameraAvailability() async {
    try {
      // Primero verificar permisos
      await _checkCameraPermission();

      if (_hasCameraPermission) {
        // Luego verificar si hay cámara disponible
        await _checkCameraHardware();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _cameraError = error.toString();
          _hasCameraHardware = false;
          _isCheckingPermission = false;
        });
      }
    }
  }

  Future<void> _checkCameraHardware() async {
    // Liberar recursos de la cámara si ya existe un controlador
    final controller = _scannerController;
    if (controller != null) {
      try {
        await controller.stop();
        await controller.dispose();
      } catch (e) {
        debugPrint('Error al liberar recursos de la cámara: $e');
      }
    }

    try {
      // Inicializar el controlador con configuración mínima inicial
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );

      // Función para verificar si la cámara está lista
      Future<bool> isCameraReady() async {
        try {
          final controller = _scannerController;
          if (controller == null) return false;
          // Intentar acceder a una propiedad del controlador
          await controller.toggleTorch();
          await controller.toggleTorch();
          return true;
        } catch (e) {
          debugPrint('Error verificando cámara: $e');
          return false;
        }
      }

      // Intentar con la cámara trasera primero
      bool cameraReady = false;
      
      try {
        final controller = _scannerController;
        if (controller != null) {
          await controller.start();
          // Esperar un momento para que la cámara se inicialice
          await Future.delayed(const Duration(milliseconds: 800));
          cameraReady = await isCameraReady();
        }
      } catch (e) {
        debugPrint('Error con cámara trasera: $e');
      }

      // Si falla, intentar con la cámara frontal
      if (!cameraReady && mounted) {
        setState(() {
          _cameraError = 'Probando con cámara frontal...';
        });
        
        try {
          final controller = _scannerController;
          if (controller != null) {
            await controller.stop();
            await controller.dispose();
          }
          
          _scannerController = MobileScannerController(
            detectionSpeed: DetectionSpeed.normal,
            facing: CameraFacing.front,
            torchEnabled: false,
          );
          
          final newController = _scannerController;
          if (newController != null) {
            await newController.start();
            await Future.delayed(const Duration(milliseconds: 800));
            cameraReady = await isCameraReady();
          }
        } catch (e) {
          debugPrint('Error con cámara frontal: $e');
        }
      }

      if (!cameraReady) {
        throw Exception('No se pudo inicializar ninguna cámara');
      }

      if (mounted) {
        setState(() {
          _hasCameraHardware = true;
          _isCheckingPermission = false;
          _cameraError = null;
        });
      }
    } catch (error) {
      debugPrint('Error initializing camera: $error');
      if (mounted) {
        setState(() {
          _hasCameraHardware = false;
          _cameraError =
              'No se pudo acceder a la cámara. Asegúrate de que la aplicación tenga los permisos necesarios.';
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
      }
    }
  }

  void _showNoCameraDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              LucideIcons.cameraOff,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            const Text('Sin Cámara'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Este dispositivo no tiene una cámara disponible o no se pudo acceder a ella.',
            ),
            if (_cameraError != null) ...[
              const SizedBox(height: 12),
              const Text(
                'Detalles técnicos:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _cameraError!,
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                ),
              ),
            ],
          ],
        ),
        actions: [
          // Botón Entendido
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              splashFactory: NoSplash.splashFactory,
            ),
            child: Text(
              'Entendido',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          // Botón Reintentar
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _checkCameraAvailability();
            },
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              splashFactory: NoSplash.splashFactory,
            ),
            child: const Text(
              'Reintentar',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(LucideIcons.ban, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 12),
            const Text('Acceso Restringido'),
          ],
        ),
        content: const Text(
          'El acceso a la cámara está restringido en este dispositivo. '
          'Esto puede deberse a controles parentales u otras restricciones del sistema.',
        ),
        actions: [
          // Botón Entendido
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              splashFactory: NoSplash.splashFactory,
            ),
            child: Text(
              'Entendido',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
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
      await _checkCameraHardware();
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
            'Para escanear códigos QR, necesitamos acceso a la cámara. '
            'Ve a Configuración para activar los permisos.',
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(LucideIcons.camera, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            const Text('Permiso de Cámara'),
          ],
        ),
        content: const Text(
          'Para escanear códigos QR, necesitamos acceso a la cámara. '
          'Ve a configuración para activar los permisos de la aplicación.',
        ),
        actions: [
          // Botón Salir
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              splashFactory: NoSplash.splashFactory,
            ),
            child: Text(
              'Salir',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          // Botón Configuración
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                width: 1,
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              splashFactory: NoSplash.splashFactory,
            ),
            child: const Text(
              'Abrir Configuración',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onBarcodeDetect(BarcodeCapture capture) async {
    // Prevenir escaneos muy rápidos
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

    // Haptic feedback
    if (Platform.isIOS) {
      // HapticFeedback.lightImpact();
    }

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(LucideIcons.searchX, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            const Text('Código no encontrado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('No se encontró ninguna mariposa con el código:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Botón Salir
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              splashFactory: NoSplash.splashFactory,
            ),
            child: Text(
              'Salir',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          // Botón Escanear otro
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScanner();
            },
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              splashFactory: NoSplash.splashFactory,
            ),
            child: const Text(
              'Escanear otro',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(LucideIcons.triangleAlert, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            const Text('Error'),
          ],
        ),
        content: Text('Ocurrió un error al buscar la mariposa:\n$error'),
        actions: [
          // Botón Aceptar
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              splashFactory: NoSplash.splashFactory,
            ),
            child: Text(
              'Aceptar',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          // Botón Reintentar
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScanner();
            },
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              splashFactory: NoSplash.splashFactory,
            ),
            child: const Text(
              'Reintentar',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
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

          // Overlay de escaneo
          _buildScanOverlay(),

          // Instrucciones
          _buildInstructions(),

          // Controles inferiores
          _buildBottomControls(),

          // Overlay de carga
          if (_hasDetected) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildPermissionCheckingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  if (Platform.isIOS)
                    const CupertinoActivityIndicator(
                      color: Colors.white,
                      radius: 20,
                    )
                  else
                    const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Verificando cámara...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPermissionScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,

        leading: IconButton(
          icon: const Icon(
            LucideIcons.chevronLeft,
            size: 22,
            color: Colors.white,
          ),
          tooltip: 'Atrás',
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.camera,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Permiso de Cámara Requerido',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Para escanear códigos QR, necesitamos acceso a la cámara de tu dispositivo.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Column(
                      children: [
                        // Botón Reintentar
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _checkCameraAvailability,
                            borderRadius: BorderRadius.circular(12),
                            highlightColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            child: Ink(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 24,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    LucideIcons.refreshCw,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Reintentar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Botón Configuración
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: openAppSettings,
                            borderRadius: BorderRadius.circular(12),
                            highlightColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            child: Ink(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 24,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    LucideIcons.settings,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Abrir Configuración',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, size: 22),
          tooltip: 'Atrás',
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.cameraOff,
                      size: 64,
                      color: Colors.red.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Cámara No Disponible',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Este dispositivo no tiene una cámara disponible o no se pudo acceder a ella para escanear códigos QR.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _checkCameraAvailability,
                            icon: const Icon(LucideIcons.refreshCw),
                            label: const Text('Verificar Nuevamente'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(LucideIcons.arrowLeft),
                            label: const Text('Volver'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black.withValues(alpha: 0.3),
      elevation: 0,
      automaticallyImplyLeading: false,

      leading: IconButton(
        icon: const Icon(LucideIcons.chevronLeft, size: 22),
        tooltip: 'Atrás',
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onPressed: () => Navigator.of(context).pop(),
      ),

      actions: [
        IconButton(
          onPressed: _toggleFlash,
          icon: Icon(_isFlashOn ? LucideIcons.zap : LucideIcons.zapOff),
          tooltip: _isFlashOn ? 'Apagar flash' : 'Encender flash',
          style: IconButton.styleFrom(
            backgroundColor: _isFlashOn
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.transparent,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildScanOverlay() {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  // Marco principal
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),

                  // Esquinas animadas
                  ...List.generate(4, (index) => _buildAnimatedCorner(index)),

                  // Línea de escaneo
                  if (_isScanning) _buildScanLine(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedCorner(int index) {
    const size = 24.0;
    const thickness = 4.0;
    late final Alignment alignment;
    late final Widget child;

    switch (index) {
      case 0:
        alignment = Alignment.topLeft;
        child = Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white, width: thickness),
              left: BorderSide(color: Colors.white, width: thickness),
            ),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(4)),
          ),
        );
        break;
      case 1:
        alignment = Alignment.topRight;
        child = Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white, width: thickness),
              right: BorderSide(color: Colors.white, width: thickness),
            ),
            borderRadius: BorderRadius.only(topRight: Radius.circular(4)),
          ),
        );
        break;
      case 2:
        alignment = Alignment.bottomLeft;
        child = Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white, width: thickness),
              left: BorderSide(color: Colors.white, width: thickness),
            ),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(4)),
          ),
        );
        break;
      case 3:
        alignment = Alignment.bottomRight;
        child = Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white, width: thickness),
              right: BorderSide(color: Colors.white, width: thickness),
            ),
            borderRadius: BorderRadius.only(bottomRight: Radius.circular(4)),
          ),
        );
        break;
    }

    return Positioned.fill(
      child: Align(alignment: alignment, child: child),
    );
  }

  Widget _buildScanLine() {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Positioned(
          left: 20,
          right: 20,
          top: 20 + (240 * (_slideAnimation.value + 1) / 2),
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white,
                  Colors.white,
                  Colors.transparent,
                ],
                stops: const [0.0, 0.2, 0.8, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstructions() {
    return Positioned(
      bottom: 200,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isScanning ? LucideIcons.qrCode : LucideIcons.hourglass,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              _isScanning
                  ? 'Enfoca el código QR dentro del marco'
                  : 'Procesando código...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _isScanning
                  ? 'Asegúrate de tener buena iluminación'
                  : 'Por favor espera...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.x, color: Colors.white),
                tooltip: 'Cerrar',
              ),
              const SizedBox(width: 20),
              IconButton(
                onPressed: _resetScanner,
                icon: const Icon(LucideIcons.refreshCw, color: Colors.white),
                tooltip: 'Reiniciar escáner',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (Platform.isIOS)
                const CupertinoActivityIndicator(
                  color: Colors.white,
                  radius: 24,
                )
              else
                const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              const SizedBox(height: 20),
              const Text(
                'Buscando mariposa...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Por favor espera',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
