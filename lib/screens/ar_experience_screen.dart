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

// Imports condicionales para AR - Solo ARKit, sin ARCore
import 'package:arkit_plugin/arkit_plugin.dart'
    if (dart.library.html) 'package:flutter/foundation.dart';
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
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

  // Variables para animaciones y control del modelo
  Timer? _rotationTimer;
  Timer? _floatingTimer;
  double _modelRotation = 0.0;
  double _floatingOffset = 0.0;

  // Referencias a nodos AR
  String? _currentARNodeName;

  late final Butterfly selectedButterfly = widget.butterfly;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuart),
        );

    _slideController.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    ARLogger.log('Inicializando aplicación AR...');

    await _detectARSupport();
    await _checkCameraPermission();
    _playAmbientSound();

    // AR solo disponible en iOS con ARKit
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
      // Check current status
      var status = await Permission.camera.status;
      
      // If not granted, request permission
      if (!status.isGranted) {
        status = await Permission.camera.request();
      }
      
      // Update state and log
      setState(() => _hasCameraPermission = status.isGranted);
      ARLogger.log(
        'Estado de permisos de cámara: ${status.toString().split('.').last}',
      );
      
      // If permission is permanently denied, show settings dialog
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
        ARLogger.log('Cargando modelo en modo preview 3D');
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

      // Crear nodo usando la API básica de ARKit
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
      if (_arSupport == ARPlatformSupport.arkit) {
        // ARKit maneja rotación de forma diferente
        // La rotación automática se maneja en el ModelViewer para otros casos
      }
    } catch (e) {
      ARLogger.error('Error actualizando rotación del modelo', e);
    }
  }

  void _updateModelFloating() {
    // Implementar animación de flotación según la plataforma
    if (_currentARNodeName == null) return;

    final floatingY = math.sin(_floatingOffset) * 0.05;
    // Actualizar posición Y del modelo según plataforma
  }

  // ==================== USER INTERACTIONS ====================

  void _handleTap() {
    setState(() => _isModelSelected = !_isModelSelected);
    HapticFeedback.lightImpact();

    if (_isModelSelected) {
      _stopAutoAnimations();
      _showSelectionFeedback();
    } else {
      _startAutoAnimations();
    }
  }

  void _showSelectionFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Mariposa seleccionada - Usa gestos para interactuar',
          style: TextStyle(color: Colors.white),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _captureScreen() async {
    try {
      HapticFeedback.lightImpact();

      // Aquí podrías implementar captura real según la plataforma
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(LucideIcons.camera, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Captura ${_arSupport == ARPlatformSupport.arkit ? 'AR' : '3D'} simulada',
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
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
        action: SnackBarAction(label: 'Reintentar', onPressed: _loadARModel),
      ),
    );
  }

  // ==================== AR VIEW BUILDERS ====================

  Widget _buildARView() {
    if (!_hasCameraPermission) {
      return _buildNoPermissionView();
    }

    if (Platform.isIOS && _arSupport == ARPlatformSupport.arkit) {
      return _buildARKitView();
    } else {
      return _buildModelViewerView();
    }
  }

  Widget _buildARKitView() {
    return ARKitSceneView(
      onARKitViewCreated: (controller) {
        _arkitController = controller;
        ARLogger.success('Vista ARKit creada');
        _loadARModel();
      },
      showFeaturePoints: true,
      showWorldOrigin: false,
      enableTapRecognizer: true,
    );
  }

  Widget _buildModelViewerView() {
    final modelPath = selectedButterfly.modelAsset;

    if (modelPath == null) {
      return _buildStaticView();
    }

    return ModelViewer(
      backgroundColor: Colors.transparent,
      src: modelPath,
      alt: "Modelo 3D de ${selectedButterfly.name}",
      ar: false,
      autoRotate: true,
      cameraControls: true,
      autoPlay: true,
      loading: Loading.eager,
      disableZoom: false,
      minCameraOrbit: "auto auto 1m",
      maxCameraOrbit: "auto auto 20m",
      cameraOrbit: "0deg 75deg 6m",
      fieldOfView: "25deg",
      minFieldOfView: "15deg",
      maxFieldOfView: "60deg",
    );
  }

  Widget _buildStaticView() {
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
              children: [
                // Mostrar modelo 3D si está disponible
                if (selectedButterfly.modelAsset != null)
                  Expanded(
                    child: ModelViewer(
                      backgroundColor: Colors.transparent,
                      src: selectedButterfly.modelAsset!,
                      alt: "Modelo 3D de ${selectedButterfly.name}",
                      ar: false,
                      autoRotate: true,
                      cameraControls: true,
                      autoPlay: true,
                      loading: Loading.eager,
                      disableZoom: false,
                      minCameraOrbit: "auto auto 1m",
                      maxCameraOrbit: "auto auto 20m",
                      cameraOrbit: "0deg 75deg 6m",
                      fieldOfView: "25deg",
                      minFieldOfView: "15deg",
                      maxFieldOfView: "60deg",
                    ),
                  )
                else
                  Column(
                    children: [
                      Icon(
                        _arSupport == ARPlatformSupport.none
                            ? Icons.phone_android
                            : LucideIcons.box,
                        size: 64,
                        color: Colors.white,
                      ),
                      SizedBox(height: 16),
                      Text(
                        _arSupport == ARPlatformSupport.none
                            ? 'Vista previa 3D'
                            : 'Modelo 3D',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _arSupport == ARPlatformSupport.arkit
                            ? 'Toca el botón AR para realidad aumentada'
                            : 'AR no soportado en este dispositivo',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
              ],
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
          SizedBox(height: 16),
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
            FutureBuilder<PermissionStatus>(
              future: Permission.camera.status,
              builder: (context, snapshot) {
                final status = snapshot.data;
                
                if (status == null || status.isGranted) {
                  return const SizedBox.shrink();
                }
                
                return Column(
                  children: [
                    if (status.isPermanentlyDenied) ...[
                      const Text(
                        'El permiso fue denegado permanentemente. Por favor, habilítalo manualmente en la configuración del dispositivo.',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.settings, size: 20),
                        label: const Text('Abrir Configuración'),
                        onPressed: () => openAppSettings(),
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt, size: 20),
                        label: const Text('Conceder Permiso'),
                        onPressed: () async {
                          final newStatus = await Permission.camera.request();
                          if (newStatus.isGranted && mounted) {
                            setState(() => _hasCameraPermission = true);
                            _loadARModel();
                          }
                        },
                      ),
                    ],
                  ],
                );
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
                offset: Offset(0, 2),
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
        color: isDark ? Color(0xFF1E2936) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con imagen y nombres
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
                      SizedBox(width: 16),
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
                            SizedBox(height: 4),
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
                  SizedBox(height: 24),

                  // Descripción
                  Text(
                    'Descripción',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    selectedButterfly.description,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  SizedBox(height: 24),

                  // Info técnica AR
                  FutureBuilder<String>(
                    future: SimpleARSupport.getARSupportInfo(),
                    builder: (context, snapshot) {
                      return Container(
                        padding: EdgeInsets.all(16),
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
                                SizedBox(width: 8),
                                Text(
                                  'Estado AR',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              snapshot.data ?? 'Verificando...',
                              style: theme.textTheme.bodyMedium,
                            ),
                            if (_arSupport == ARPlatformSupport.arkit) ...[
                              SizedBox(height: 8),
                              Text(
                                'Toca la mariposa para seleccionarla y usar gestos',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 16),
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
            // Main AR/3D Content
            Platform.isIOS && _arSupport == ARPlatformSupport.arkit && _isARMode
                ? _buildARView()
                : _buildStaticView(),

            // Top Navigation Controls
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 8,
              child: IconButton(
                icon: Icon(
                  LucideIcons.chevronLeft,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Atrás',
              ),
            ),

            // AR Mode Toggle (solo si AR está soportado en iOS)
            if (Platform.isIOS && _arSupport == ARPlatformSupport.arkit)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 8,
                child: _buildFloatingButton(
                  icon: _isARMode ? LucideIcons.image : LucideIcons.box,
                  onPressed: () {
                    setState(() => _isARMode = !_isARMode);
                    HapticFeedback.selectionClick();
                    ARLogger.log(
                      'Cambiado a modo: ${_isARMode ? 'AR' : '3D Preview'}',
                    );
                  },
                  tooltip: _isARMode ? 'Vista previa' : 'Vista AR',
                ),
              ),

            // AR Controls (floating buttons)
            if (Platform.isIOS &&
                _arSupport == ARPlatformSupport.arkit &&
                _isARMode)
              Positioned(
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
                    SizedBox(height: 16),
                    _buildFloatingButton(
                      icon: LucideIcons.camera,
                      onPressed: _captureScreen,
                      tooltip: 'Capturar',
                    ),
                  ],
                ),
              ),

            // Loading Indicator for AR
            if (Platform.isIOS &&
                _arSupport == ARPlatformSupport.arkit &&
                _isARMode &&
                !_isModelLoaded)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: SlideTransition(
                    position: _slide,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      margin: EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              LucideIcons.smartphone,
                              size: 24,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Busca una superficie plana',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Mueve tu dispositivo lentamente',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 12),
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
              ),

            // Model Selection Indicator
            if (_isModelSelected &&
                Platform.isIOS &&
                _arSupport == ARPlatformSupport.arkit &&
                _isARMode)
              Positioned(
                top: MediaQuery.of(context).padding.top + 80,
                left: 16,
                right: 16,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.hand, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Mariposa seleccionada - Interactúa con gestos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
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

    // Cleanup AR controllers
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
    // Reiniciar audio si es necesario cuando cambian las dependencias
    if (mounted && (_audioPlayer?.state != PlayerState.playing)) {
      _playAmbientSound();
    }
  }
}
