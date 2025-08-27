// lib/screens/ar_experience_screen.dart
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart' as vector;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import 'package:butterflyar/models/butterfly.dart';
import 'package:butterflyar/utils/ar_helpers.dart';

class ARExperienceScreen extends StatefulWidget {
  final Butterfly butterfly;
  const ARExperienceScreen({required this.butterfly, super.key});

  @override
  State<ARExperienceScreen> createState() => _ARExperienceScreenState();
}

class _ARExperienceScreenState extends State<ARExperienceScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Audio y animaciones
  AudioPlayer? _audioPlayer;
  late AnimationController _slideController;
  late Animation<Offset> _slide;

  // Controller AR solo para iOS
  ARKitController? _arkitController;

  // Estados de la aplicación
  ARPlatformSupport _arSupport = ARPlatformSupport.none;
  bool _hasCameraPermission = false;
  bool _isARMode = true;
  bool _isDayBackground = true;
  bool _isModelSelected = false;
  bool _showingInfo = false;
  bool _isModelLoaded = false;
  bool _planeDetected = false;

  // Variables para animaciones y control del modelo
  Timer? _rotationTimer;
  Timer? _floatingTimer;
  double _modelRotation = 0.0;
  double _floatingOffset = 0.0;

  // Referencias a nodos AR
  String? _currentARNodeName;
  ARKitNode? _butterflyNode;

  late final Butterfly selectedButterfly = widget.butterfly;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAudio();
    _initAnimations();
    _initializeApp();
  }

  void _initAudio() {
    _audioPlayer ??= AudioPlayer();
  }

  void _initAnimations() {
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuart),
        );
    _slideController.forward();
  }

  Future<void> _initializeApp() async {
    ARLogger.log('Inicializando aplicación AR...');

    await _detectARSupport();
    await _checkCameraPermission();
    await _playAmbientSound();

    if (Platform.isIOS &&
        _arSupport == ARPlatformSupport.arkit &&
        _hasCameraPermission) {
      ARLogger.success('Dispositivo iOS listo para AR');
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
    try {
      var status = await Permission.camera.status;

      if (!status.isGranted) {
        status = await Permission.camera.request();
      }

      setState(() => _hasCameraPermission = status.isGranted);
      ARLogger.log(
        'Estado de permisos de cámara: ${status.toString().split('.').last}',
      );

      if (status.isPermanentlyDenied) {
        if (mounted) {
          _showPermissionSettingsDialog();
        }
      }
    } catch (e) {
      ARLogger.error('Error verificando permisos de cámara', e);
      setState(() => _hasCameraPermission = false);
    }
  }

  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Permiso de Cámara Requerido'),
        content: const Text(
          'Para usar la función de RA, necesitamos acceso a la cámara. '
          'Por favor, habilita el permiso en la configuración de la aplicación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Abrir Configuración'),
          ),
        ],
      ),
    );
  }

  Future<void> _playAmbientSound() async {
    try {
      final soundPath = selectedButterfly.ambientSound;
      if (soundPath?.isNotEmpty ?? false) {
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

  // Esta función ahora solo es llamada para reintentar la carga.
  // La carga inicial se hará cuando se detecte un plano.
  Future<void> _loadButterflyModel() async {
    // La lógica de carga inicial se movió a _onAddAnchor
  }

  // ==================== ANIMATIONS ====================

  void _startButterflyAnimations() {
    _stopAutoAnimations();

    _rotationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted && !_isModelSelected && _butterflyNode != null) {
        _modelRotation += 0.05;
        if (_modelRotation > 2 * math.pi) _modelRotation = 0;

        final yRotation = math.sin(_modelRotation) * 0.3;
        _butterflyNode?.eulerAngles = vector.Vector3(0, yRotation, 0);
      }
    });

    _floatingTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (mounted && !_isModelSelected && _butterflyNode != null) {
        _floatingOffset += 0.08;

        final floatingY = math.sin(_floatingOffset) * 0.05;
        final baseY = _planeDetected ? 0.1 : 0;

        _butterflyNode?.position = vector.Vector3(
          _butterflyNode!.position.x,
          baseY + floatingY,
          _butterflyNode!.position.z,
        );
      }
    });
  }

  void _stopAutoAnimations() {
    _rotationTimer?.cancel();
    _floatingTimer?.cancel();
  }

  // ==================== USER INTERACTIONS ====================

  void _handleTap() {
    if (!_isARMode) return;
    setState(() => _isModelSelected = !_isModelSelected);
    HapticFeedback.lightImpact();

    if (_isModelSelected) {
      _stopAutoAnimations();
      _highlightButterfly();
    } else {
      _startButterflyAnimations();
      _removeHighlight();
    }
  }

  void _highlightButterfly() {
    if (_butterflyNode != null) {
      _butterflyNode?.scale = vector.Vector3.all(0.12);
    }
  }

  void _removeHighlight() {
    if (_butterflyNode != null) {
      _butterflyNode?.scale = vector.Vector3.all(0.1);
    }
  }

  Future<void> _captureScreen() async {
    try {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.camera, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Captura AR guardada'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
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
        action: SnackBarAction(
          label: 'Reintentar',
          onPressed: _isARMode ? () {} : () {},
        ),
      ),
    );
  }

  void _showSuccessSnackbar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Mariposa cargada! Toca para interactuar'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ==================== AR VIEW BUILDERS ====================

  Widget _buildARView() {
    return ARKitSceneView(
      onARKitViewCreated: (controller) {
        _arkitController = controller;
        ARLogger.success('Vista ARKit creada');
        controller.onAddNodeForAnchor = _onAddAnchor;
        controller.onUpdateNodeForAnchor = _onUpdateAnchor;
      },
      showFeaturePoints: false,
      showWorldOrigin: false,
      planeDetection: ARPlaneDetection.horizontal,
      autoenablesDefaultLighting: true,
      debug: false,
    );
  }

  // LÓGICA PRINCIPAL: CARGAR EL MODELO CUANDO SE DETECTE EL PLANO
  void _onAddAnchor(ARKitAnchor anchor) {
    if (anchor is ARKitPlaneAnchor && _butterflyNode == null) {
      setState(() => _planeDetected = true);
      ARLogger.log('✅ Plano horizontal detectado');

      if (selectedButterfly.modelAssetIOS == null ||
          selectedButterfly.modelAssetIOS!.isEmpty) {
        ARLogger.error('Ruta de modelo iOS no válida o vacía');
        _showErrorSnackbar();
        return;
      }

      final nodeName = 'butterfly_${DateTime.now().millisecondsSinceEpoch}';

      // Crear un nodo que cargue el modelo 3D desde la carpeta de assets
      _butterflyNode = ARKitReferenceNode(
        url: selectedButterfly.modelAssetIOS!,
        scale: vector.Vector3.all(0.1),
        position: vector.Vector3(
          anchor.center.x,
          anchor.center.y +
              0.1, // Un pequeño offset para que no quede justo en la superficie
          anchor.center.z,
        ),
        eulerAngles: vector.Vector3(0, 0, 0),
        name: nodeName,
      );

      _arkitController?.add(_butterflyNode!);
      _currentARNodeName = nodeName;
      setState(() => _isModelLoaded = true);
      _startButterflyAnimations();

      ARLogger.success('✅ Mariposa cargada y colocada exitosamente');
      _showSuccessSnackbar();
    }
  }

  void _onUpdateAnchor(ARKitAnchor anchor) {
    if (anchor is ARKitPlaneAnchor && _butterflyNode != null) {
      _butterflyNode?.position = vector.Vector3(
        anchor.center.x,
        anchor.center.y + 0.1,
        anchor.center.z,
      );
    }
  }

  Widget _buildStaticView() {
    final modelPath = selectedButterfly.modelAssetAndroid;

    final Widget modelContent = modelPath != null && modelPath.isNotEmpty
        ? Expanded(
            child: ModelViewer(
              backgroundColor: Colors.transparent,
              src: modelPath,
              alt: "Modelo 3D de ${selectedButterfly.name}",
              ar: false,
              autoRotate: true,
              cameraControls: true,
              autoPlay: true,
              loading: Loading.eager,
              disableZoom: false,
            ),
          )
        : Column(
            children: [
              Icon(
                _arSupport == ARPlatformSupport.none
                    ? Icons.phone_android
                    : LucideIcons.box,
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                _arSupport == ARPlatformSupport.none
                    ? 'Vista previa 3D'
                    : 'Modelo 3D',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _arSupport == ARPlatformSupport.arkit
                    ? 'Toca el botón AR para realidad aumentada'
                    : 'AR no soportado en este dispositivo',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          );

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            _isDayBackground
                ? 'assets/backgrounds/day.png'
                : 'assets/backgrounds/night.png',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [modelContent],
            ),
          ),
          _buildStaticViewControls(),
        ],
      ),
    );
  }

  Widget _buildStaticViewControls() {
    return Positioned(
      bottom: 24,
      right: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFloatingButton(
            icon: LucideIcons.info,
            onPressed: _showInfo,
            tooltip: 'Información',
          ),
          const SizedBox(height: 16),
          _buildFloatingButton(
            icon: _isDayBackground ? LucideIcons.sun : LucideIcons.moon,
            onPressed: () {
              setState(() => _isDayBackground = !_isDayBackground);
              HapticFeedback.lightImpact();
            },
            tooltip: _isDayBackground ? 'Modo noche' : 'Modo día',
          ),
        ],
      ),
    );
  }

  Widget _buildNoPermissionView() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.camera, size: 48, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              'Permiso de cámara requerido',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Necesitamos acceso a tu cámara para mostrar la experiencia de realidad aumentada.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt, size: 20),
              label: const Text('Conceder Permiso'),
              onPressed: () async {
                final newStatus = await Permission.camera.request();
                if (newStatus.isGranted && mounted) {
                  setState(() => _hasCameraPermission = true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==================== UI COMPONENTS ====================

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.black87, size: 22),
        ),
      ),
    );
  }

  void _showInfo() {
    setState(() => _showingInfo = true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildInfoSheet(),
    ).then((_) => setState(() => _showingInfo = false));
  }

  Widget _buildInfoSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2936) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: AssetImage(selectedButterfly.imageAsset),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedButterfly.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedButterfly.scientificName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Descripción',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedButterfly.description,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _arSupport == ARPlatformSupport.arkit
                                  ? LucideIcons.smartphone
                                  : LucideIcons.box,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Estado AR',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _arSupport == ARPlatformSupport.arkit
                              ? 'ARKit disponible - Experiencia completa'
                              : 'Modo vista previa 3D',
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (_isModelLoaded) ...[
                          const SizedBox(height: 8),
                          Text(
                            '✅ Modelo cargado correctamente',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MAIN BUILD ====================

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            if (!_hasCameraPermission)
              _buildNoPermissionView()
            else
              Platform.isIOS &&
                      _isARMode &&
                      _arSupport == ARPlatformSupport.arkit
                  ? _buildARView()
                  : _buildStaticView(),

            _buildTopControls(),

            if (Platform.isIOS &&
                _isARMode &&
                _arSupport == ARPlatformSupport.arkit)
              _buildARControls(),

            if (Platform.isIOS &&
                _isARMode &&
                _arSupport == ARPlatformSupport.arkit &&
                !_isModelLoaded)
              _buildARInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 8,
      right: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              LucideIcons.chevronLeft,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Atrás',
          ),
          if (Platform.isIOS && _arSupport == ARPlatformSupport.arkit)
            _buildFloatingButton(
              icon: _isARMode ? LucideIcons.image : LucideIcons.box,
              onPressed: () {
                setState(() => _isARMode = !_isARMode);
                HapticFeedback.selectionClick();
              },
              tooltip: _isARMode ? 'Vista previa' : 'Vista AR',
            ),
        ],
      ),
    );
  }

  Widget _buildARControls() {
    return Positioned(
      bottom: 24,
      right: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFloatingButton(
            icon: LucideIcons.info,
            onPressed: _showInfo,
            tooltip: 'Información',
          ),
          const SizedBox(height: 16),
          _buildFloatingButton(
            icon: LucideIcons.camera,
            onPressed: _captureScreen,
            tooltip: 'Capturar',
          ),
        ],
      ),
    );
  }

  Widget _buildARInstructions() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Center(
        child: SlideTransition(
          position: _slide,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.92),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.search,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  _planeDetected
                      ? 'Cargando mariposa...'
                      : 'Busca una superficie plana',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  _planeDetected
                      ? 'Preparando experiencia AR...'
                      : 'Mueve tu dispositivo lentamente',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== LIFECYCLE ====================

  @override
  void dispose() {
    ARLogger.log('Cerrando experiencia AR');
    _stopAutoAnimations();
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    _slideController.dispose();
    _arkitController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        ARLogger.log('App resumed - rechecking permissions');
        _checkCameraPermission();
        if (_arkitController != null && !_isModelLoaded) {
          _loadButterflyModel();
        }
        _playAmbientSound();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        ARLogger.log('App paused/inactive - stopping animations and audio');
        _stopAutoAnimations();
        _audioPlayer?.pause();
        break;
      case AppLifecycleState.detached:
        ARLogger.log('App detached - cleanup');
        _audioPlayer?.stop();
        break;
    }
  }
}
