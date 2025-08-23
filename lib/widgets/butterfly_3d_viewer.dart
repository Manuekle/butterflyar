// butterfly_3d_viewer.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class Butterfly3DViewer extends StatelessWidget {
  final String modelAssetPath;
  final String? title;
  final bool autoRotate;
  final bool cameraControls;
  final Color? backgroundColor;

  const Butterfly3DViewer({
    super.key,
    required this.modelAssetPath,
    this.title,
    this.autoRotate = true,
    this.cameraControls = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? Colors.black,
      appBar: AppBar(
        title: Text(title ?? '3D Mariposa'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: ModelViewer(
          // Asset local - completamente offline
          src: modelAssetPath,
          
          // Configuraciones de cámara y controles
          autoRotate: autoRotate,
          cameraControls: cameraControls,
          
          // Configuraciones visuales
          backgroundColor: backgroundColor ?? const Color(0xFF000000),
          
          // Configuraciones de carga
          loading: Loading.eager,
          
          // Configuraciones de renderizado
          autoPlay: true,
          
          // Configuraciones de interacción
          disableZoom: false,
          disablePan: false,
          disableTap: false,
          
          // Configuraciones de ambiente
          environmentImage: null, // Para mantenerlo simple y offline
          
          // Configuraciones adicionales para mejor rendimiento
          poster: null, // Sin poster para carga más rápida
          
          // Configuraciones de AR (opcional)
          ar: false, // Puedes habilitarlo si quieres AR
          arModes: const ['scene-viewer', 'webxr', 'quick-look'],
          
          // Configuraciones de sombras y luces
          shadowIntensity: 0.3,
          shadowSoftness: 0.4,
          
          // Configuraciones del modelo
          exposure: 1.0,
          
          // Callback de eventos
          onWebViewCreated: (controller) {
            debugPrint('ModelViewer WebView creado');
          },
          
          // Configuraciones de debug (opcional)
          debugLogging: true,
        ),
      ),
    );
  }
}

// Widget simplificado para usar en cualquier lugar
class SimpleButterfly3D extends StatelessWidget {
  final String modelAssetPath;
  final double? width;
  final double? height;
  final bool showControls;

  const SimpleButterfly3D({
    super.key,
    required this.modelAssetPath,
    this.width,
    this.height,
    this.showControls = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 300,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ModelViewer(
          src: modelAssetPath,
          autoRotate: true,
          cameraControls: showControls,
          backgroundColor: const Color(0xFF000000),
          loading: Loading.eager,
          autoPlay: true,
          disableZoom: !showControls,
          disablePan: !showControls,
        ),
      ),
    );
  }
}
