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
}
