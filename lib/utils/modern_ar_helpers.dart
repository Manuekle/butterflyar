// lib/utils/modern_ar_helpers.dart
import 'dart:io';
import 'package:flutter/foundation.dart';

// Imports condicionales para evitar errores en plataformas no soportadas

/// Enum para diferentes tipos de soporte AR
enum ARPlatformSupport {
  arkit, // iOS ARKit
  arcore, // Android ARCore
  webAR, // Web AR (futuro)
  none, // Sin soporte AR
}

/// Clase para manejar la detección y configuración AR por plataforma
class ModernARSupport {
  static ARPlatformSupport _cachedSupport = ARPlatformSupport.none;
  static bool _hasChecked = false;

  /// Detecta qué tipo de AR es compatible en el dispositivo actual
  static Future<ARPlatformSupport> detectARSupport() async {
    if (_hasChecked) return _cachedSupport;

    try {
      // Web: sin soporte AR nativo por ahora
      if (kIsWeb) {
        _cachedSupport = ARPlatformSupport.webAR;
        _hasChecked = true;
        return _cachedSupport;
      }

      // iOS: verificar soporte ARKit
      if (Platform.isIOS) {
        try {
          // ARKit está disponible en iOS 11+ en dispositivos A9+
          // Asumimos soporte si es iOS (verificación más específica requiere platform channels)
          _cachedSupport = ARPlatformSupport.arkit;
        } catch (e) {
          debugPrint('Error checking ARKit availability: $e');
          _cachedSupport = ARPlatformSupport.none;
        }
      }
      // Android: verificar soporte ARCore
      else if (Platform.isAndroid) {
        try {
          // Para ARCore, intentamos crear un controlador para verificar soporte
          // Si falla, asumimos que no hay soporte
          _cachedSupport = ARPlatformSupport.arcore;
        } catch (e) {
          debugPrint('Error checking ARCore availability: $e');
          _cachedSupport = ARPlatformSupport.none;
        }
      }
      // Otras plataformas: sin soporte
      else {
        _cachedSupport = ARPlatformSupport.none;
      }

      _hasChecked = true;
      return _cachedSupport;
    } catch (e) {
      debugPrint('Error detecting AR support: $e');
      _cachedSupport = ARPlatformSupport.none;
      _hasChecked = true;
      return _cachedSupport;
    }
  }

  /// Verifica si el dispositivo tiene soporte AR
  static Future<bool> hasARSupport() async {
    final support = await detectARSupport();
    return support != ARPlatformSupport.none;
  }

  /// Obtiene información legible sobre el soporte AR
  static Future<String> getARSupportInfo() async {
    final support = await detectARSupport();
    switch (support) {
      case ARPlatformSupport.arkit:
        return 'ARKit compatible (iOS)';
      case ARPlatformSupport.arcore:
        return 'ARCore compatible (Android)';
      case ARPlatformSupport.webAR:
        return 'Web AR (limitado)';
      case ARPlatformSupport.none:
        return 'AR no soportado';
    }
  }

  /// Resetea el cache para volver a verificar soporte
  static void resetCache() {
    _hasChecked = false;
    _cachedSupport = ARPlatformSupport.none;
  }
}

/// Configuraciones por defecto para modelos 3D
class ARModelConfig {
  final double scale;
  final List<double> position; // [x, y, z]
  final List<double> rotation; // [x, y, z] en radianes

  const ARModelConfig({
    this.scale = 0.05,
    this.position = const [0, 0, -0.5],
    this.rotation = const [0, 0, 0],
  });

  /// Configuración optimizada para mariposas
  static const ARModelConfig butterfly = ARModelConfig(
    scale: 0.03,
    position: [0, -0.2, -0.8],
    rotation: [0, 0, 0],
  );

  /// Configuración para modelos más grandes
  static const ARModelConfig large = ARModelConfig(
    scale: 0.1,
    position: [0, -0.5, -1.0],
    rotation: [0, 0, 0],
  );
}

/// Utilidad para logs AR
class ARLogger {
  static final bool _debugMode = kDebugMode;

  static void log(String message) {
    if (_debugMode) {
      debugPrint('[AR] $message');
    }
  }

  static void error(String message, [Object? error]) {
    debugPrint('[AR ERROR] $message');
    if (error != null) {
      debugPrint('[AR ERROR] Details: $error');
    }
  }

  static void success(String message) {
    if (_debugMode) {
      debugPrint('[AR SUCCESS] $message');
    }
  }
}
