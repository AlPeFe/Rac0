import 'package:raco/core/models/restaurant_model.dart';
import 'package:raco/core/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

class RestaurantRepository {
  final DatabaseService _databaseService = DatabaseService();

  // Obtener todos los restaurantes
  Future<List<Restaurant>> getAllRestaurants() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('restaurants');
    return List.generate(maps.length, (i) {
      return Restaurant.fromMap(maps[i]);
    });
  }

  // Obtener restaurantes visitados
  Future<List<Restaurant>> getVisitedRestaurants() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'restaurants',
      where: 'is_visited = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) {
      return Restaurant.fromMap(maps[i]);
    });
  }

  // Obtener restaurantes no visitados
  Future<List<Restaurant>> getUnvisitedRestaurants() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'restaurants',
      where: 'is_visited = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) {
      return Restaurant.fromMap(maps[i]);
    });
  }

  // Obtener un restaurante por ID
  Future<Restaurant?> getRestaurantById(String id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'restaurants',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Restaurant.fromMap(maps.first);
  }

  // Insertar un nuevo restaurante
  Future<void> insertRestaurant(Restaurant restaurant) async {
    final db = await _databaseService.database;
    await db.insert(
      'restaurants',
      restaurant.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Actualizar un restaurante existente
  Future<void> updateRestaurant(Restaurant restaurant) async {
    final db = await _databaseService.database;
    await db.update(
      'restaurants',
      restaurant.toMap(),
      where: 'id = ?',
      whereArgs: [restaurant.id],
    );
  }

  // Eliminar un restaurante
  Future<void> deleteRestaurant(String id) async {
    final db = await _databaseService.database;
    await db.delete(
      'restaurants',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Marcar un restaurante como visitado
  Future<void> markAsVisited(String id, bool isVisited) async {
    final db = await _databaseService.database;
    await db.update(
      'restaurants',
      {'is_visited': isVisited ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Marcar un restaurante como favorito
  Future<void> markAsFavorite(String id, bool isFavorite) async {
    final db = await _databaseService.database;
    await db.update(
      'restaurants',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Obtener restaurantes favoritos visitados
  Future<List<Restaurant>> getFavoriteVisitedRestaurants() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'restaurants',
      where: 'is_visited = ? AND is_favorite = ?',
      whereArgs: [1, 1],
    );
    return List.generate(maps.length, (i) {
      return Restaurant.fromMap(maps[i]);
    });
  }

  // Actualizar la valoración de un restaurante
  Future<void> updateRating(String id, int? rating) async {
    final db = await _databaseService.database;
    await db.update(
      'restaurants',
      {'rating': rating},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Actualizar las notas de un restaurante
  Future<void> updateNotes(String id, String? notes) async {
    final db = await _databaseService.database;
    await db.update(
      'restaurants',
      {'notes': notes},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Buscar restaurantes por nombre o dirección
  Future<List<Restaurant>> searchRestaurants(String query) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'restaurants',
      where: 'name LIKE ? OR address LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) {
      return Restaurant.fromMap(maps[i]);
    });
  }

  // Obtener restaurantes por etiqueta
  Future<List<Restaurant>> getRestaurantsByTag(String tag) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'restaurants',
      where: 'tags LIKE ?',
      whereArgs: ['%$tag%'],
    );
    return List.generate(maps.length, (i) {
      return Restaurant.fromMap(maps[i]);
    });
  }

  // Limpiar toda la tabla
  Future<void> clearAllRestaurants() async {
    final db = await _databaseService.database;
    await db.delete('restaurants');
  }

  // Obtener estadísticas
  Future<RestaurantStats> getStats() async {
    final db = await _databaseService.database;
    
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM restaurants');
    final total = Sqflite.firstIntValue(totalResult) ?? 0;
    
    final visitedResult = await db.rawQuery('SELECT COUNT(*) as count FROM restaurants WHERE is_visited = 1');
    final visited = Sqflite.firstIntValue(visitedResult) ?? 0;
    
    final pendingResult = await db.rawQuery('SELECT COUNT(*) as count FROM restaurants WHERE is_visited = 0');
    final pending = Sqflite.firstIntValue(pendingResult) ?? 0;
    
    final favoritesResult = await db.rawQuery('SELECT COUNT(*) as count FROM restaurants WHERE is_favorite = 1');
    final favorites = Sqflite.firstIntValue(favoritesResult) ?? 0;
    
    final avgRatingResult = await db.rawQuery('SELECT AVG(rating) as avg FROM restaurants WHERE rating IS NOT NULL');
    final avgRating = avgRatingResult.first['avg'] as double?;
    
    // Categorías más usadas
    final allRestaurants = await getAllRestaurants();
    final tagCount = <String, int>{};
    for (final r in allRestaurants) {
      for (final tag in r.tags) {
        if (tag.isNotEmpty) {
          tagCount[tag] = (tagCount[tag] ?? 0) + 1;
        }
      }
    }
    final topTags = tagCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Distribución de precios
    final priceDistribution = <int, int>{};
    for (final r in allRestaurants) {
      if (r.priceRange != null) {
        priceDistribution[r.priceRange!.index] = 
          (priceDistribution[r.priceRange!.index] ?? 0) + 1;
      }
    }
    
    return RestaurantStats(
      total: total,
      visited: visited,
      pending: pending,
      favorites: favorites,
      averageRating: avgRating,
      topTags: topTags.take(5).map((e) => MapEntry(e.key, e.value)).toList(),
      priceDistribution: priceDistribution,
    );
  }
}

class RestaurantStats {
  final int total;
  final int visited;
  final int pending;
  final int favorites;
  final double? averageRating;
  final List<MapEntry<String, int>> topTags;
  final Map<int, int> priceDistribution;

  RestaurantStats({
    required this.total,
    required this.visited,
    required this.pending,
    required this.favorites,
    this.averageRating,
    required this.topTags,
    required this.priceDistribution,
  });
}
