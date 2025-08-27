class Butterfly {
  final String id;
  final String name;
  final String scientificName;
  final String description;
  final String imageAsset;
  final String? modelAssetAndroid;
  final String? modelAssetIOS;
  final String? ambientSound;

  Butterfly({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.imageAsset,
    this.description = '',
    this.modelAssetAndroid,
    this.modelAssetIOS,
    this.ambientSound,
  });

  // Helper method to create a copy with some fields overridden
  Butterfly copyWith({
    String? id,
    String? name,
    String? scientificName,
    String? description,
    String? imageAsset,
    String? modelAssetAndroid,
    String? modelAssetIOS,
    String? ambientSound,
  }) {
    return Butterfly(
      id: id ?? this.id,
      name: name ?? this.name,
      scientificName: scientificName ?? this.scientificName,
      description: description ?? this.description,
      imageAsset: imageAsset ?? this.imageAsset,
      modelAssetAndroid: modelAssetAndroid ?? this.modelAssetAndroid,
      modelAssetIOS: modelAssetIOS ?? this.modelAssetIOS,
      ambientSound: ambientSound ?? this.ambientSound,
    );
  }

  // Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'scientificName': scientificName,
      'imageAsset': imageAsset,
      'modelAssetAndroid': modelAssetAndroid,
      'modelAssetIOS': modelAssetIOS,
      'ambientSound': ambientSound,
    };
  }

  // Create from JSON map
  factory Butterfly.fromJson(Map<String, dynamic> json) {
    return Butterfly(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      scientificName: json['scientificName'] as String? ?? '',
      imageAsset: json['imageAsset'] as String? ?? '',
      modelAssetAndroid: json['modelAssetAndroid'] as String?,
      modelAssetIOS: json['modelAssetIOS'] as String?,
      ambientSound: json['ambientSound'] as String?,
    );
  }
}
