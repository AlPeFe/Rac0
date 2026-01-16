import 'package:flutter/material.dart';
import 'package:raco/core/models/restaurant_model.dart';
import 'package:raco/core/services/restaurant_repository.dart';
import 'package:uuid/uuid.dart';

class CreateRestaurantViewmodel extends ChangeNotifier {
  final RestaurantRepository _repository = RestaurantRepository();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<bool> createRestaurant({
    required String name,
    required String address,
    required List<String> tags,
    bool isVisited = false,
    int? rating,
    String? notes,
    double latitude = 0.0,
    double longitude = 0.0,
  }) async {
    if (name.isEmpty || address.isEmpty) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final restaurant = Restaurant(
        id: const Uuid().v4(),
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        tags: tags,
        addedAt: DateTime.now(),
        isVisited: isVisited,
        rating: rating,
        notes: notes,
      );

      await _repository.insertRestaurant(restaurant);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error creating restaurant: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
