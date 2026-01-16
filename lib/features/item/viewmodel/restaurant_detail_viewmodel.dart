import 'package:flutter/material.dart';
import 'package:raco/core/models/restaurant_model.dart';
import 'package:raco/core/services/restaurant_repository.dart';

class RestaurantDetailViewmodel extends ChangeNotifier {
  final RestaurantRepository _repository = RestaurantRepository();
  final String restaurantId;
  
  Restaurant? _restaurant;
  bool _isLoading = false;

  Restaurant? get restaurant => _restaurant;
  bool get isLoading => _isLoading;

  RestaurantDetailViewmodel(this.restaurantId) {
    loadRestaurant();
  }

  Future<void> loadRestaurant() async {
    _isLoading = true;
    notifyListeners();

    try {
      _restaurant = await _repository.getRestaurantById(restaurantId);
    } catch (e) {
      debugPrint('Error loading restaurant: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleVisited(bool isVisited) async {
    if (_restaurant == null) return;

    try {
      await _repository.markAsVisited(restaurantId, isVisited);
      await loadRestaurant();
    } catch (e) {
      debugPrint('Error toggling visited: $e');
    }
  }

  Future<void> updateRating(int rating) async {
    if (_restaurant == null) return;

    try {
      final updatedRestaurant = _restaurant!.copyWith(rating: rating);
      await _repository.updateRestaurant(updatedRestaurant);
      await loadRestaurant();
    } catch (e) {
      debugPrint('Error updating rating: $e');
    }
  }

  Future<void> deleteRestaurant() async {
    try {
      await _repository.deleteRestaurant(restaurantId);
    } catch (e) {
      debugPrint('Error deleting restaurant: $e');
    }
  }
}
