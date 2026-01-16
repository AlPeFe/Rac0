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
  final int? rating; // 1-10, null si no hay valoración
  final String? notes; // Notas del usuario

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
  }) : assert(rating == null || (rating >= 1 && rating <= 10),
             'Rating debe estar entre 1 y 10');


  factory Restaurant.fromMap(Map<String, dynamic> map) {
    return Restaurant(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      tags: (map['tags'] as String).split(','),
      addedAt: DateTime.parse(map['added_at'] as String),
      isVisited: (map['is_visited'] as int) == 1,
      isFavorite: (map['is_favorite'] as int?) == 1,
      rating: map['rating'] as int?,
      notes: map['notes'] as String?,
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
    };
  }

  // Constructor para crear desde JSON (útil para API)
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
    );
  }

  // Convertir a JSON (útil para API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'tags': tags,
      'added_at': addedAt.toIso8601String(),
      'is_visited': isVisited,
      'is_favorite': isFavorite,
      'rating': rating,
      'notes': notes,
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
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'Restaurant(id: $id, name: $name, address: $address, lat: $latitude, lng: $longitude, tags: $tags, addedAt: $addedAt, isVisited: $isVisited, isFavorite: $isFavorite, rating: $rating, notes: $notes)';
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
      other.notes == notes;
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
    );
  }
}