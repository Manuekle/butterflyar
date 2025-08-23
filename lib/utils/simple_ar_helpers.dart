// lib/utils/simple_ar_helpers.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Enum para diferentes tipos de soporte AR
enum ARPlatformSupport {
  arkit, // iOS ARKit
  arcore, // Android ARCore
  webAR, // Web AR (futuro)
  none, // Sin soporte AR
}

/// Clase simplificada para manejar detección AR
class SimpleARSupport {
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

      // iOS: verificar soporte ARKit (iOS 11+ con procesador A9+)
      if (Platform.isIOS) {
        try {
          final deviceInfo = DeviceInfoPlugin();
          final iosInfo = await deviceInfo.iosInfo;

          // Verificar versión mínima iOS 11 y modelos compatibles
          final systemVersion = iosInfo.systemVersion;
          final majorVersion =
              int.tryParse(systemVersion.split('.').first) ?? 0;

          // ARKit requiere iOS 11+ y procesador A9+
          // Simplificamos asumiendo que dispositivos recientes tienen soporte
          if (majorVersion >= 11) {
            _cachedSupport = ARPlatformSupport.arkit;
          } else {
            _cachedSupport = ARPlatformSupport.none;
          }
        } catch (e) {
          debugPrint('Error checking iOS ARKit support: $e');
          // Fallback: asumir soporte si es iOS moderno
          _cachedSupport = ARPlatformSupport.arkit;
        }
      }
      // Android: verificar soporte ARCore
      else if (Platform.isAndroid) {
        try {
          final deviceInfo = DeviceInfoPlugin();
          final androidInfo = await deviceInfo.androidInfo;

          // ARCore requiere Android 7.0+ (API 24+) en la mayoría de dispositivos
          if (androidInfo.version.sdkInt >= 24) {
            _cachedSupport = ARPlatformSupport.arcore;
          } else {
            _cachedSupport = ARPlatformSupport.none;
          }
        } catch (e) {
          debugPrint('Error checking Android ARCore support: $e');
          // Fallback: asumir soporte si es Android moderno
          _cachedSupport = ARPlatformSupport.arcore;
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
    return support != ARPlatformSupport.none &&
        support != ARPlatformSupport.webAR;
  }

  /// Obtiene información legible sobre el soporte AR
  static Future<String> getARSupportInfo() async {
    final support = await detectARSupport();
    switch (support) {
      case ARPlatformSupport.arkit:
        return 'ARKit compatible (iOS 11+)';
      case ARPlatformSupport.arcore:
        return 'ARCore compatible (Android 7.0+)';
      case ARPlatformSupport.webAR:
        return 'Web AR (limitado)';
      case ARPlatformSupport.none:
        return 'AR no soportado en este dispositivo';
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

/// Clase helper para trabajar con vectores de ARKit
class ARKitVector3Helper {
  static dynamic createVector3(double x, double y, double z) {
    // Esto será reemplazado por la importación real de ARKit
    return {'x': x, 'y': y, 'z': z};
  }
}

/// Clase helper para trabajar con vectores de ARCore
class ArCoreVector3Helper {
  static dynamic createVector3(double x, double y, double z) {
    // Esto será reemplazado por la importación real de ARCore
    return {'x': x, 'y': y, 'z': z};
  }
}
