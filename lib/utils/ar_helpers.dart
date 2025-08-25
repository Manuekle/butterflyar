// lib/utils/ar_helpers.dart - Versión para ARKit (iOS) y Model Viewer (Android)
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Enum para diferentes tipos de soporte AR
enum ARPlatformSupport {
  arkit, // iOS ARKit
  modelViewer, // Android Model Viewer
  none, // Sin soporte AR
}

/// Clase para manejar la detección de AR
class SimpleARSupport {
  static ARPlatformSupport _cachedSupport = ARPlatformSupport.none;
  static bool _hasChecked = false;

  /// Detecta qué tipo de AR es compatible en el dispositivo actual
  static Future<ARPlatformSupport> detectARSupport() async {
    if (_hasChecked) return _cachedSupport;

    try {
      // Web: sin soporte AR nativo
      if (kIsWeb) {
        _cachedSupport = ARPlatformSupport.none;
        return _cachedSupport;
      }
      
      // iOS: verificar soporte ARKit (iOS 11+ y dispositivo compatible)
      if (Platform.isIOS) {
        try {
          final deviceInfo = DeviceInfoPlugin();
          final iosInfo = await deviceInfo.iosInfo;
          final systemVersion = iosInfo.systemVersion;
          final majorVersion = int.tryParse(systemVersion.split('.').first) ?? 0;
          
          // Verificar versión mínima de iOS (11.0+)
          if (majorVersion < 11) {
            debugPrint('ARKit requires iOS 11.0 or later. Current version: $systemVersion');
            _cachedSupport = ARPlatformSupport.none;
            return _cachedSupport;
          }
          
          // Verificar si el dispositivo es compatible con ARKit
          // ARKit requiere un dispositivo con chip A9 o posterior (iPhone 6s/SE/7/8/X, iPad 2017 o posterior)
          final deviceName = iosInfo.utsname.machine.toLowerCase();
          final isCompatibleDevice = deviceName.contains(RegExp(
            r'iphone(8|9|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|[6-9]s|[6-9]splus|[xrsm]|se|se2|se3)|ipad([5-9]|1[0-9]|20|[6-9]th|[6-9]thgen|[6-9]thgeneration|air[3-9]|pro[1-9]|mini[5-9])|ipod7',
            caseSensitive: false,
          ));
          
          if (!isCompatibleDevice) {
            debugPrint('Device not compatible with ARKit: $deviceName');
            _cachedSupport = ARPlatformSupport.none;
            return _cachedSupport;
          }
          
          _cachedSupport = ARPlatformSupport.arkit;
          debugPrint('ARKit is supported on this device ($deviceName, iOS $systemVersion)');
        } catch (e) {
          debugPrint('Error checking iOS ARKit support: $e');
          _cachedSupport = ARPlatformSupport.none;
        }
      }
      // Android: Usar Model Viewer
      else if (Platform.isAndroid) {
        _cachedSupport = ARPlatformSupport.modelViewer;
      }
    } catch (e) {
      debugPrint('Error detecting AR support: $e');
      _cachedSupport = ARPlatformSupport.none;
    }

    _hasChecked = true;
    return _cachedSupport;
  }

  /// Obtiene información legible sobre el soporte AR
  static Future<String> getARSupportInfo() async {
    final support = await detectARSupport();
    switch (support) {
      case ARPlatformSupport.arkit:
        return 'ARKit (iOS)';
      case ARPlatformSupport.modelViewer:
        return '3D Model Viewer (Android)';
      case ARPlatformSupport.none:
        return 'No compatible';
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
