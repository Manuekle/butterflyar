import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'butterfly.dart';

/// Carga todas las mariposas desde el archivo JSON centralizado
Future<List<Butterfly>> loadButterfliesFromAssets() async {
  try {
    debugPrint('🦋 Cargando mariposas desde el archivo JSON...');
    final String jsonString = await rootBundle.loadString(
      'lib/data/butterflies.json',
    );
    final Map<String, dynamic> jsonData = json.decode(jsonString);

    if (jsonData['butterflies'] == null) {
      debugPrint('❌ No se encontró la clave "butterflies" en el JSON');
      return [];
    }

    final List<dynamic> butterfliesJson = jsonData['butterflies'] as List;
    final List<Butterfly> butterflies = butterfliesJson.map((json) {
      return Butterfly(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Nombre desconocido',
        scientificName: json['scientificName'] as String? ?? '',
        description: json['description'] as String? ?? '',
        imageAsset: json['imageAsset'] as String? ?? '',
        modelAsset: json['modelAsset'] as String?,
        ambientSound: json['ambientSound'] as String?,
      );
    }).toList();

    debugPrint('✅ Se cargaron ${butterflies.length} especies de mariposas');
    return butterflies;
  } catch (e, stackTrace) {
    debugPrint('❌ Error al cargar las mariposas: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
}

/// Función de compatibilidad para código existente
@Deprecated('Use loadButterfliesFromAssets instead')
Future<List<Butterfly>> loadButterflies() async {
  return loadButterfliesFromAssets();
}
