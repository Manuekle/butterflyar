// lib/screens/ar_experience_screen.dart
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

// AR imports
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:butterfliesar/models/butterfly.dart';
import 'package:butterfliesar/utils/ar_helpers.dart';

class ARExperienceScreen extends StatefulWidget {
  final Butterfly butterfly;
  const ARExperienceScreen({required this.butterfly, super.key});

  @override
  State<ARExperienceScreen> createState() => _ARExperienceScreenState();
}

class _ARExperienceScreenState extends State<ARExperienceScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // Audio and animations
  AudioPlayer? _audioPlayer;
  late AnimationController _slideController;

  // AR Controller for iOS
  ARKitController? _arkitController;

  // App states
  ARPlatformSupport _arSupport = ARPlatformSupport.modelViewer;
  bool _hasCameraPermission = false;
  bool _isARMode = true;
  bool _isModelSelected = false;
  bool _isModelLoaded = false;

  // Animation and model control variables
  Timer? _rotationTimer;
  Timer? _floatingTimer;
  double _modelRotation = 0.0;
  double _floatingOffset = 0.0;

  // AR node reference
  String? _currentARNodeName;

  late final Butterfly selectedButterfly = widget.butterfly;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    ARLogger.log('Inicializando aplicación AR...');

    await _detectARSupport();
    await _checkCameraPermission();
    _playAmbientSound();

    // Usar AR solo en iOS, Model Viewer en Android
    if (Platform.isIOS &&
        _arSupport == ARPlatformSupport.arkit &&
        _hasCameraPermission) {
      ARLogger.success('Dispositivo iOS listo para ARKit');
    } else if (Platform.isAndroid) {
      ARLogger.success('Usando Model Viewer en Android');
      setState(() => _isARMode = false);
    } else {
      ARLogger.log('Usando modo vista previa 3D');
      setState(() => _isARMode = false);
    }
  }

  Future<void> _detectARSupport() async {
    try {
      final support = await SimpleARSupport.detectARSupport();
      setState(() => _arSupport = support);
      ARLogger.log(
        'Soporte AR detectado: ${await SimpleARSupport.getARSupportInfo()}',
      );
    } catch (e) {
      ARLogger.error('Error detectando soporte AR', e);
      setState(() => _arSupport = ARPlatformSupport.none);
    }
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    setState(() => _hasCameraPermission = status.isGranted);
    ARLogger.log(
      'Permisos de cámara: ${status.isGranted ? 'concedidos' : 'denegados'}',
    );
  }

  Future<void> _playAmbientSound() async {
    try {
      final soundPath = selectedButterfly.ambientSound;
      if (soundPath?.isNotEmpty ?? false) {
        _audioPlayer ??= AudioPlayer();
        await _audioPlayer?.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer?.setVolume(0.3);

        final assetPath = soundPath!.startsWith('assets/')
            ? soundPath.substring(7)
            : soundPath;

        await _audioPlayer?.play(AssetSource(assetPath));
        ARLogger.log('Sonido ambiental iniciado');
      }
    } catch (e) {
      ARLogger.error('Error reproduciendo sonido ambiental', e);
    }
  }

  // ==================== AR MODEL LOADING ====================

  Future<void> _loadARModel() async {
    if (!mounted || _isModelLoaded) return;

    final modelPath = selectedButterfly.modelAsset;
    if (modelPath == null) {
      ARLogger.error('No hay modelo 3D disponible para esta mariposa');
      return;
    }

    ARLogger.log('Iniciando carga del modelo: $modelPath');

    try {
      if (Platform.isIOS && _arSupport == ARPlatformSupport.arkit) {
        await _loadARKitModel(modelPath);
      } else {
        // For Android or fallback, we'll use ModelViewer which is handled in the build method
        ARLogger.log('Usando ModelViewer para visualización 3D');
      }

      setState(() => _isModelLoaded = true);
      _startAutoAnimations();
      ARLogger.success('Modelo cargado exitosamente');
    } catch (e) {
      ARLogger.error('Error cargando modelo AR', e);
      _showErrorSnackbar();
    }
  }

  Future<void> _loadARKitModel(String modelPath) async {
    if (_arkitController == null) return;

    try {
      final config = ARModelConfig.butterfly;
      final nodeName = 'butterfly_${DateTime.now().millisecondsSinceEpoch}';

      // Create node using ARKit's basic API
      final node = ARKitReferenceNode(
        url: modelPath,
        scale: vector.Vector3.all(config.scale),
        position: vector.Vector3(
          config.position[0].toDouble(),
          config.position[1].toDouble(),
          config.position[2].toDouble(),
        ),
      );

      _arkitController?.add(node);
      _currentARNodeName = nodeName;
      ARLogger.success('Modelo ARKit cargado: $nodeName');
    } catch (e) {
      ARLogger.error('Error cargando modelo ARKit', e);
    }
  }

  // ==================== ANIMATIONS ====================

  void _startAutoAnimations() {
    _stopAutoAnimations();

    _rotationTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted && !_isModelSelected) {
        setState(() {
          _modelRotation += 0.02;
          if (_modelRotation > 2 * math.pi) _modelRotation = 0;
        });
        _updateModelRotation();
      }
    });

    _floatingTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted && !_isModelSelected) {
        setState(() => _floatingOffset += 0.05);
        _updateModelFloating();
      }
    });
  }

  void _stopAutoAnimations() {
    _rotationTimer?.cancel();
    _floatingTimer?.cancel();
  }

  void _updateModelRotation() {
    // Solo actualizar si tenemos un nodo AR cargado
    if (_currentARNodeName == null) return;

    try {
      switch (_arSupport) {
        case ARPlatformSupport.arkit:
          // ARKit maneja rotación de forma diferente
          break;
        default:
          break;
      }
    } catch (e) {
      ARLogger.error('Error actualizando rotación del modelo', e);
    }
  }

  void _updateModelFloating() {
    if (_currentARNodeName == null) return;

    // Calculate floating offset and apply to model position
    final floatingY = math.sin(_floatingOffset) * 0.05;

    // TODO: Apply floatingY to the model's position based on platform
    // This is a placeholder for future implementation
    debugPrint('Floating offset: $floatingY');
  }

  // ==================== USER INTERACTIONS ====================

  // This method is kept for future implementation of tap interactions
  // Currently not used in the UI but preserved for future features
  @visibleForTesting
  @protected
  void handleTapForTesting() {
    if (!mounted) return;
    setState(() => _isModelSelected = !_isModelSelected);
    try {
      // Haptic feedback is only available on physical devices
      HapticFeedback.lightImpact();
    } catch (e) {
      ARLogger.log('Haptic feedback not available: $e');
    }

    if (_isModelSelected) {
      _stopAutoAnimations();
      _showSelectionFeedback();
    } else {
      _startAutoAnimations();
    }
  }

  void _showSelectionFeedback() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Mariposa seleccionada - Usa gestos para interactuar',
          style: TextStyle(color: Colors.white),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  // This method is kept for future implementation of screen capture functionality
  // Currently not used in the UI but preserved for future features
  @visibleForTesting
  @protected
  Future<void> captureScreenForTesting() async {
    try {
      if (!mounted) return;

      // This is a placeholder for actual screen capture implementation
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.camera, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Captura ${_arSupport != ARPlatformSupport.none ? 'AR' : '3D'} simulada',
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ARLogger.error('Error capturando pantalla', e);
    }
  }

  void _showErrorSnackbar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Error cargando modelo 3D'),
        backgroundColor: Colors.red,
        action: SnackBarAction(label: 'Reintentar', onPressed: _loadARModel),
      ),
    );
  }

  // ==================== BUILD METHOD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          if (_arSupport == ARPlatformSupport.arkit && _isARMode)
            _buildARKitView()
          else
            _buildModelViewer(),

          // Back button
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // AR/3D toggle
          if (_arSupport == ARPlatformSupport.arkit)
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: Icon(
                  _isARMode ? LucideIcons.box : LucideIcons.move3d,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isARMode = !_isARMode;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  // ==================== AR VIEWS ====================

  Widget _buildARKitView() {
    if (!_hasCameraPermission) {
      return _buildNoPermissionView();
    }

    return ARKitSceneView(
      onARKitViewCreated: (ARKitController controller) {
        _arkitController = controller;
        _loadARModel();
      },
      enableTapRecognizer: true,
      enablePanRecognizer: true,
      enablePinchRecognizer: true,
      enableRotationRecognizer: true,
      showFeaturePoints: true,
    );
  }

  Widget _buildModelViewer() {
    final modelPath = selectedButterfly.modelAsset;

    if (modelPath == null) {
      return const Center(child: Text('No hay modelo 3D disponible'));
    }

    return ModelViewer(
      backgroundColor: Colors.transparent,
      src: modelPath,
      alt: 'Modelo 3D de ${selectedButterfly.name}',
      ar: false,
      autoRotate: true,
      cameraControls: true,
      autoPlay: true,
      loading: Loading.eager,
    );
  }

  Widget _buildNoPermissionView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Se requiere permiso de cámara',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Por favor, otorga permiso de cámara para usar la realidad aumentada.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => openAppSettings(),
              child: const Text('Abrir configuración'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== LIFECYCLE ====================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    switch (state) {
      case AppLifecycleState.resumed:
        ARLogger.log('App resumed - rechecking permissions');
        _checkCameraPermission();
        break;
      case AppLifecycleState.paused:
        ARLogger.log('App paused - stopping animations');
        _stopAutoAnimations();
        _audioPlayer?.pause();
        break;
      case AppLifecycleState.detached:
        ARLogger.log('App detached - cleanup');
        _audioPlayer?.stop();
        break;
      case AppLifecycleState.inactive:
        ARLogger.log('App inactive - pausing animations');
        _stopAutoAnimations();
        break;
      case AppLifecycleState.hidden:
        ARLogger.log('App hidden - cleaning up resources');
        _stopAutoAnimations();
        _audioPlayer?.pause();
        break;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Restart audio if needed when dependencies change
    if (mounted && (_audioPlayer?.state != PlayerState.playing)) {
      _playAmbientSound();
    }
  }

  @override
  void dispose() {
    _stopAutoAnimations();
    _slideController.dispose();
    _audioPlayer?.dispose();
    _arkitController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
