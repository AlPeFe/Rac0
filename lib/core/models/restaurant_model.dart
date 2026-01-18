/// Enum para representar el rango de precios
enum PriceRange {
  low,    // €
  medium, // €€
  high,   // €€€
  veryHigh; // €€€€

  String get display {
    switch (this) {
      case PriceRange.low:
        return '€';
      case PriceRange.medium:
        return '€€';
      case PriceRange.high:
        return '€€€';
      case PriceRange.veryHigh:
        return '€€€€';
    }
  }

  String get label {
    switch (this) {
      case PriceRange.low:
        return 'Económico';
      case PriceRange.medium:
        return 'Moderado';
      case PriceRange.high:
        return 'Caro';
      case PriceRange.veryHigh:
        return 'Muy caro';
    }
  }

  static PriceRange? fromInt(int? value) {
    if (value == null) return null;
    if (value < 0 || value >= PriceRange.values.length) return null;
    return PriceRange.values[value];
  }
}

class Restaurant {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> tags;
  final DateTime addedAt;
  final bool isVisited;
  final bool isFavorite;
  final int? rating; // 1-5, null si no hay valoración
  final String? notes; // Notas del usuario
  final PriceRange? priceRange; // Rango de precios

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.tags,
    required this.addedAt,
    this.isVisited = false,
    this.isFavorite = false,
    this.rating,
    this.notes,
    this.priceRange,
  }) : assert(rating == null || (rating >= 1 && rating <= 5),
             'Rating debe estar entre 1 y 5');


  factory Restaurant.fromMap(Map<String, dynamic> map) {
    return Restaurant(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      tags: (map['tags'] as String).split(',').where((t) => t.isNotEmpty).toList(),
      addedAt: DateTime.parse(map['added_at'] as String),
      isVisited: (map['is_visited'] as int) == 1,
      isFavorite: (map['is_favorite'] as int?) == 1,
      rating: map['rating'] as int?,
      notes: map['notes'] as String?,
      priceRange: PriceRange.fromInt(map['price_range'] as int?),
    );
  }

  // Convertir a mapa (útil para SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'tags': tags.join(','),
      'added_at': addedAt.toIso8601String(),
      'is_visited': isVisited ? 1 : 0,
      'is_favorite': isFavorite ? 1 : 0,
      'rating': rating,
      'notes': notes,
      'price_range': priceRange?.index,
    };
  }

  // Constructor para crear desde JSON (útil para backup/restore)
  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      tags: List<String>.from(json['tags'] as List),
      addedAt: DateTime.parse(json['addedAt'] as String),
      isVisited: json['isVisited'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
      rating: json['rating'] as int?,
      notes: json['notes'] as String?,
      priceRange: PriceRange.fromInt(json['priceRange'] as int?),
    );
  }

  // Convertir a JSON (útil para backup/restore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'tags': tags,
      'addedAt': addedAt.toIso8601String(),
      'isVisited': isVisited,
      'isFavorite': isFavorite,
      'rating': rating,
      'notes': notes,
      'priceRange': priceRange?.index,
    };
  }

  // CopyWith para inmutabilidad
  Restaurant copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    List<String>? tags,
    DateTime? addedAt,
    bool? isVisited,
    bool? isFavorite,
    int? rating,
    String? notes,
    PriceRange? priceRange,
    bool clearRating = false,
    bool clearNotes = false,
    bool clearPriceRange = false,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      tags: tags ?? this.tags,
      addedAt: addedAt ?? this.addedAt,
      isVisited: isVisited ?? this.isVisited,
      isFavorite: isFavorite ?? this.isFavorite,
      rating: clearRating ? null : (rating ?? this.rating),
      notes: clearNotes ? null : (notes ?? this.notes),
      priceRange: clearPriceRange ? null : (priceRange ?? this.priceRange),
    );
  }

  @override
  String toString() {
    return 'Restaurant(id: $id, name: $name, address: $address, lat: $latitude, lng: $longitude, tags: $tags, addedAt: $addedAt, isVisited: $isVisited, isFavorite: $isFavorite, rating: $rating, notes: $notes, priceRange: $priceRange)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Restaurant &&
      other.id == id &&
      other.name == name &&
      other.address == address &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.tags.length == tags.length &&
      other.addedAt == addedAt &&
      other.isVisited == isVisited &&
      other.isFavorite == isFavorite &&
      other.rating == rating &&
      other.notes == notes &&
      other.priceRange == priceRange;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      address,
      latitude,
      longitude,
      Object.hashAll(tags),
      addedAt,
      isVisited,
      isFavorite,
      rating,
      notes,
      priceRange,
    );
  }
}
