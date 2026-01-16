import 'package:flutter/material.dart';
import 'package:raco/core/models/restaurant_model.dart';
import 'package:raco/core/services/restaurant_repository.dart';

class VisitedViewmodel extends ChangeNotifier {
  final RestaurantRepository _repository = RestaurantRepository();
  List<Restaurant> _items = [];
  List<Restaurant> _filteredItems = [];
  bool _isLoading = false;
  String _searchQuery = '';
  bool _showOnlyFavorites = false;

  List<Restaurant> get items => _filteredItems;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  bool get showOnlyFavorites => _showOnlyFavorites;

  VisitedViewmodel() {
    loadItems();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilter();
    notifyListeners();
  }

  void setShowOnlyFavorites(bool value) {
    _showOnlyFavorites = value;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    List<Restaurant> result = List.from(_items);
    
    if (_showOnlyFavorites) {
      result = result.where((r) => r.isFavorite).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      result = result.where((restaurant) {
        final nameMatch = restaurant.name.toLowerCase().contains(_searchQuery);
        final tagsMatch = restaurant.tags.any(
          (tag) => tag.toLowerCase().contains(_searchQuery),
        );
        return nameMatch || tagsMatch;
      }).toList();
    }
    
    _filteredItems = result;
  }

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _repository.getVisitedRestaurants();
      _applyFilter();
    } catch (e) {
      debugPrint('Error loading visited items: $e');
      _items = [];
      _filteredItems = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateRestaurant(Restaurant restaurant) async {
    await _repository.updateRestaurant(restaurant);
    await loadItems();
  }

  Future<void> deleteRestaurant(String id) async {
    await _repository.deleteRestaurant(id);
    await loadItems();
  }

  Future<void> toggleVisited(String id, bool isVisited) async {
    await _repository.markAsVisited(id, isVisited);
    await loadItems();
  }

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    await _repository.markAsFavorite(id, isFavorite);
    await loadItems();
  }
}
