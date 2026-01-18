import 'package:flutter/material.dart';
import 'package:raco/core/models/restaurant_model.dart';
import 'package:raco/core/services/restaurant_repository.dart';
import 'package:raco/core/services/settings_service.dart';
import 'package:raco/core/widgets/filter_sheet.dart';

class VisitedViewmodel extends ChangeNotifier {
  final RestaurantRepository _repository = RestaurantRepository();
  final SettingsService _settings = SettingsService();
  List<Restaurant> _items = [];
  List<Restaurant> _filteredItems = [];
  bool _isLoading = false;
  String _searchQuery = '';
  bool _showOnlyFavorites = false;
  SortOption _sortOption = SortOption.dateDesc;
  RestaurantFilters _filters = const RestaurantFilters();

  List<Restaurant> get items => _filteredItems;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  bool get showOnlyFavorites => _showOnlyFavorites;
  SortOption get sortOption => _sortOption;
  RestaurantFilters get filters => _filters;
  
  /// Obtiene todas las categorías únicas de los restaurantes
  List<String> get availableTags {
    final tags = <String>{};
    for (final restaurant in _items) {
      tags.addAll(restaurant.tags);
    }
    return tags.toList()..sort();
  }

  VisitedViewmodel() {
    _sortOption = _settings.sortOption;
    loadItems();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilterAndSort();
    notifyListeners();
  }

  void setShowOnlyFavorites(bool value) {
    _showOnlyFavorites = value;
    _applyFilterAndSort();
    notifyListeners();
  }

  void setSortOption(SortOption option) {
    _sortOption = option;
    _applyFilterAndSort();
    notifyListeners();
  }

  void setFilters(RestaurantFilters filters) {
    _filters = filters;
    _applyFilterAndSort();
    notifyListeners();
  }

  void clearFilters() {
    _filters = const RestaurantFilters();
    _applyFilterAndSort();
    notifyListeners();
  }

  void _applyFilterAndSort() {
    List<Restaurant> result = List.from(_items);
    
    // Filtrar por favoritos
    if (_showOnlyFavorites) {
      result = result.where((r) => r.isFavorite).toList();
    }
    
    // Aplicar filtros avanzados
    if (_filters.hasActiveFilters) {
      result = result.where((r) => _filters.matches(r)).toList();
    }
    
    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      result = result.where((restaurant) {
        final nameMatch = restaurant.name.toLowerCase().contains(_searchQuery);
        final tagsMatch = restaurant.tags.any(
          (tag) => tag.toLowerCase().contains(_searchQuery),
        );
        final addressMatch = restaurant.address.toLowerCase().contains(_searchQuery);
        return nameMatch || tagsMatch || addressMatch;
      }).toList();
    }
    
    // Ordenar
    result.sort((a, b) {
      switch (_sortOption) {
        case SortOption.dateDesc:
          return b.addedAt.compareTo(a.addedAt);
        case SortOption.dateAsc:
          return a.addedAt.compareTo(b.addedAt);
        case SortOption.nameAsc:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case SortOption.nameDesc:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case SortOption.ratingDesc:
          return (b.rating ?? 0).compareTo(a.rating ?? 0);
        case SortOption.ratingAsc:
          return (a.rating ?? 0).compareTo(b.rating ?? 0);
        case SortOption.priceAsc:
          return (a.priceRange?.index ?? 99).compareTo(b.priceRange?.index ?? 99);
        case SortOption.priceDesc:
          return (b.priceRange?.index ?? -1).compareTo(a.priceRange?.index ?? -1);
      }
    });
    
    _filteredItems = result;
  }

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _repository.getVisitedRestaurants();
      _applyFilterAndSort();
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
