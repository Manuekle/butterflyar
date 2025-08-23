// safe_model_viewer.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class SafeModelViewer extends StatefulWidget {
  final String modelAssetPath;
  final String? title;
  final bool autoRotate;
  final bool cameraControls;
  final Color? backgroundColor;

  const SafeModelViewer({
    super.key,
    required this.modelAssetPath,
    this.title,
    this.autoRotate = true,
    this.cameraControls = true,
    this.backgroundColor,
  });

  @override
  State<SafeModelViewer> createState() => _SafeModelViewerState();
}

class _SafeModelViewerState extends State<SafeModelViewer> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    // Agregar delay para evitar inicializaciones múltiples
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _handleWebViewCreated(dynamic controller) {
    debugPrint('SafeModelViewer: WebView creado exitosamente');
    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasError = false;
      });
    }
  }

  void _handleError(String error) {
    debugPrint('SafeModelViewer Error: $error');
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = error;
        _isLoading = false;
      });
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error cargando modelo 3D',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isLoading = true;
                });
                // Reintentar después de un delay
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
            ),
            SizedBox(height: 16),
            Text(
              'Cargando modelo 3D...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'El mensaje "localhost" es normal',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor ?? Colors.black,
      appBar: AppBar(
        title: Text(widget.title ?? '3D Mariposa'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: _hasError
          ? _buildErrorWidget()
          : _isLoading
              ? _buildLoadingWidget()
              : _buildModelViewer(),
    );
  }

  Widget _buildModelViewer() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: ModelViewer(
        // Asset local
        src: widget.modelAssetPath,
        
        // Configuraciones básicas
        autoRotate: widget.autoRotate,
        cameraControls: widget.cameraControls,
        backgroundColor: widget.backgroundColor ?? const Color(0xFF000000),
        
        // Configuraciones de carga optimizadas
        loading: Loading.eager,
        autoPlay: true,
        
        // Sin dependencias externas
        environmentImage: null,
        poster: null,
        
        // AR deshabilitado para evitar conflictos
        ar: false,
        
        // Configuraciones de rendimiento
        shadowIntensity: 0.2,
        shadowSoftness: 0.3,
        exposure: 1.0,
        
        // Callbacks
        onWebViewCreated: _handleWebViewCreated,
        
        // Debug solo en desarrollo
        debugLogging: kDebugMode,
        
        // Configuraciones de interacción
        disableZoom: false,
        disablePan: false,
        disableTap: false,
      ),
    );
  }
}

// Widget embebido simplificado y seguro
class SafeEmbeddedModel extends StatefulWidget {
  final String modelAssetPath;
  final double? width;
  final double? height;
  final bool showControls;

  const SafeEmbeddedModel({
    super.key,
    required this.modelAssetPath,
    this.width,
    this.height,
    this.showControls = true,
  });

  @override
  State<SafeEmbeddedModel> createState() => _SafeEmbeddedModelState();
}

class _SafeEmbeddedModelState extends State<SafeEmbeddedModel> {
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Delay para evitar múltiples inicializaciones
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 300,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _hasError
            ? _buildEmbeddedError()
            : _isLoading
                ? _buildEmbeddedLoading()
                : _buildEmbeddedModel(),
      ),
    );
  }

  Widget _buildEmbeddedError() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, color: Colors.red, size: 32),
          SizedBox(height: 8),
          Text(
            'Error cargando modelo',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmbeddedLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
            strokeWidth: 2,
          ),
          SizedBox(height: 8),
          Text(
            'Cargando...',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmbeddedModel() {
    return ModelViewer(
      src: widget.modelAssetPath,
      autoRotate: true,
      cameraControls: widget.showControls,
      backgroundColor: const Color(0xFF000000),
      loading: Loading.eager,
      autoPlay: true,
      disableZoom: !widget.showControls,
      disablePan: !widget.showControls,
      environmentImage: null,
      poster: null,
      ar: false,
      debugLogging: false, // Sin logs en widgets embebidos
      onWebViewCreated: (controller) {
        debugPrint('SafeEmbeddedModel: WebView creado');
        if (mounted) {
          setState(() {
            _hasError = false;
          });
        }
      },
    );
  }
}
