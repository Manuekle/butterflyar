import 'package:flutter/foundation.dart';
import '../models/butterfly.dart';
import '../models/butterfly_loader.dart';

class ButterflyProvider with ChangeNotifier {
  List<Butterfly> _butterflies = [];
  bool _isLoading = false;
  String? _error;
  bool _hasInitialized = false;

  // Getters
  List<Butterfly> get butterflies => List.unmodifiable(_butterflies);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasInitialized => _hasInitialized;
  bool get isEmpty => _butterflies.isEmpty;
  int get count => _butterflies.length;

  // Cargar mariposas desde assets
  Future<void> loadButterflies() async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      debugPrint('🦋 Cargando mariposas desde assets...');
      final loadedButterflies = await loadButterfliesFromAssets();

      _butterflies = loadedButterflies;
      _hasInitialized = true;

      debugPrint('🦋 Cargadas ${_butterflies.length} especies de mariposas');

      // Log de especies cargadas en modo debug
      if (kDebugMode) {
        for (final butterfly in _butterflies) {
          debugPrint('  - ${butterfly.name} (${butterfly.scientificName})');
        }
      }
    } catch (e, stackTrace) {
      final errorMessage = 'Error al cargar las especies: $e';
      _setError(errorMessage);

      debugPrint('❌ $errorMessage');
      if (kDebugMode) {
        debugPrint('Stack trace: $stackTrace');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Recargar mariposas (forzar recarga)
  Future<void> reloadButterflies() async {
    _hasInitialized = false;
    await loadButterflies();
  }

  // Obtener mariposa por ID
  Butterfly? getButterflyById(String id) {
    if (_butterflies.isEmpty) return null;

    try {
      return _butterflies.firstWhere(
        (butterfly) => butterfly.id.toLowerCase() == id.toLowerCase(),
      );
    } catch (e) {
      debugPrint('🔍 Mariposa no encontrada con ID: $id');
      return null;
    }
  }

  // Buscar mariposas por nombre
  List<Butterfly> searchByName(String query) {
    if (query.isEmpty) return butterflies;

    final lowerQuery = query.toLowerCase();
    return _butterflies.where((butterfly) {
      return butterfly.name.toLowerCase().contains(lowerQuery) ||
          butterfly.scientificName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Obtener mariposas que tienen modelo 3D
  List<Butterfly> get butterfliesWithModels {
    return _butterflies.where((b) => b.modelAsset?.isNotEmpty == true).toList();
  }

  // Obtener mariposas que tienen sonido ambiente
  List<Butterfly> get butterfliesWithSound {
    return _butterflies
        .where((b) => b.ambientSound?.isNotEmpty == true)
        .toList();
  }

  // Obtener una mariposa aleatoria
  Butterfly? getRandomButterfly() {
    if (_butterflies.isEmpty) return null;

    final randomIndex =
        (butterflies.length *
                (DateTime.now().millisecondsSinceEpoch % 1000) /
                1000)
            .floor();
    return _butterflies[randomIndex];
  }

  // Validar que una mariposa tiene los recursos necesarios para AR
  bool isButterflyARReady(String id) {
    final butterfly = getButterflyById(id);
    if (butterfly == null) return false;

    return butterfly.modelAsset?.isNotEmpty == true &&
        butterfly.imageAsset.isNotEmpty;
  }

  // Obtener estadísticas
  Map<String, dynamic> getStatistics() {
    return {
      'total': _butterflies.length,
      'withModels': butterfliesWithModels.length,
      'withSound': butterfliesWithSound.length,
      'arReady': _butterflies
          .where(
            (b) => b.modelAsset?.isNotEmpty == true && b.imageAsset.isNotEmpty,
          )
          .length,
    };
  }

  // Métodos privados para manejo de estado
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  // Reinicializar el provider
  void reset() {
    _butterflies.clear();
    _isLoading = false;
    _error = null;
    _hasInitialized = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _butterflies.clear();
    super.dispose();
  }
}
