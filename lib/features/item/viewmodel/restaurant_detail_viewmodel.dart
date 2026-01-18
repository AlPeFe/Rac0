import 'package:flutter/material.dart';
import 'package:raco/core/models/restaurant_model.dart';
import 'package:raco/core/services/restaurant_repository.dart';

class RestaurantDetailViewmodel extends ChangeNotifier {
  final RestaurantRepository _repository = RestaurantRepository();
  final String restaurantId;
  
  Restaurant? _restaurant;
  bool _isLoading = false;
  bool _isSaving = false;

  // Estado editable local
  bool _editedIsVisited = false;
  int? _editedRating;
  String _editedNotes = '';
  List<String> _editedTags = [];
  PriceRange? _editedPriceRange;

  Restaurant? get restaurant => _restaurant;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;

  // Getters para estado editable
  bool get editedIsVisited => _editedIsVisited;
  int? get editedRating => _editedRating;
  String get editedNotes => _editedNotes;
  List<String> get editedTags => _editedTags;
  PriceRange? get editedPriceRange => _editedPriceRange;

  // Verificar si hay cambios sin guardar
  bool get hasUnsavedChanges {
    if (_restaurant == null) return false;
    
    return _editedIsVisited != _restaurant!.isVisited ||
           _editedRating != _restaurant!.rating ||
           _editedNotes != (_restaurant!.notes ?? '') ||
           !_listEquals(_editedTags, _restaurant!.tags) ||
           _editedPriceRange != _restaurant!.priceRange;
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  RestaurantDetailViewmodel(this.restaurantId) {
    loadRestaurant();
  }

  Future<void> loadRestaurant() async {
    _isLoading = true;
    notifyListeners();

    try {
      _restaurant = await _repository.getRestaurantById(restaurantId);
      if (_restaurant != null) {
        // Inicializar estado editable con valores actuales
        _editedIsVisited = _restaurant!.isVisited;
        _editedRating = _restaurant!.rating;
        _editedNotes = _restaurant!.notes ?? '';
        _editedTags = List<String>.from(_restaurant!.tags);
        _editedPriceRange = _restaurant!.priceRange;
      }
    } catch (e) {
      debugPrint('Error loading restaurant: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Métodos para actualizar estado local (sin guardar)
  void setIsVisited(bool value) {
    _editedIsVisited = value;
    if (!value) {
      // Si desmarca visitado, limpiar rating y notas
      _editedRating = null;
      _editedNotes = '';
    }
    notifyListeners();
  }

  void setRating(int? value) {
    _editedRating = value;
    notifyListeners();
  }

  void setNotes(String value) {
    _editedNotes = value;
    notifyListeners();
  }

  void setTags(List<String> value) {
    _editedTags = value;
    notifyListeners();
  }

  void setPriceRange(PriceRange? value) {
    _editedPriceRange = value;
    notifyListeners();
  }

  void addTag(String tag) {
    if (tag.isNotEmpty && !_editedTags.contains(tag)) {
      _editedTags = [..._editedTags, tag];
      notifyListeners();
    }
  }

  void removeTag(String tag) {
    _editedTags = _editedTags.where((t) => t != tag).toList();
    notifyListeners();
  }

  // Descartar cambios
  void discardChanges() {
    if (_restaurant != null) {
      _editedIsVisited = _restaurant!.isVisited;
      _editedRating = _restaurant!.rating;
      _editedNotes = _restaurant!.notes ?? '';
      _editedTags = List<String>.from(_restaurant!.tags);
      _editedPriceRange = _restaurant!.priceRange;
      notifyListeners();
    }
  }

  // Guardar todos los cambios
  Future<bool> saveChanges() async {
    if (_restaurant == null) return false;

    _isSaving = true;
    notifyListeners();

    try {
      final updatedRestaurant = _restaurant!.copyWith(
        isVisited: _editedIsVisited,
        rating: _editedIsVisited ? _editedRating : null,
        notes: _editedIsVisited ? (_editedNotes.isEmpty ? null : _editedNotes) : null,
        tags: _editedTags,
        priceRange: _editedPriceRange,
        clearRating: !_editedIsVisited,
        clearNotes: !_editedIsVisited,
      );

      await _repository.updateRestaurant(updatedRestaurant);
      _restaurant = updatedRestaurant;
      
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving changes: $e');
      _isSaving = false;
      notifyListeners();
      return false;
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
