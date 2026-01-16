import 'package:flutter/material.dart';
import 'package:raco/core/models/restaurant_model.dart';
import 'package:raco/core/services/restaurant_repository.dart';

class HomeViewmodel extends ChangeNotifier {
  final RestaurantRepository _repository = RestaurantRepository();
  List<Restaurant> _items = [];
  List<Restaurant> _filteredItems = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Restaurant> get items => _filteredItems;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  HomeViewmodel() {
    loadItems();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredItems = List.from(_items);
    } else {
      _filteredItems = _items.where((restaurant) {
        final nameMatch = restaurant.name.toLowerCase().contains(_searchQuery);
        final tagsMatch = restaurant.tags.any(
          (tag) => tag.toLowerCase().contains(_searchQuery),
        );
        return nameMatch || tagsMatch;
      }).toList();
    }
  }

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _repository.getUnvisitedRestaurants();
      
      // Si no hay datos, insertar datos de ejemplo
      if (_items.isEmpty) {
        await _insertSampleData();
        _items = await _repository.getUnvisitedRestaurants();
      }
      _applyFilter();
    } catch (e) {
      debugPrint('Error loading items: $e');
      _items = [];
      _filteredItems = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _insertSampleData() async {
    final restaurantNames = [
      "La Tagliatella", "Goiko Grill", "Taco Bell", "Five Guys", "Wagamama",
      "Nando's", "Pizza Hut", "Domino's Pizza", "Papa John's", "Burger King",
      "McDonald's", "KFC", "Subway", "Panda Express", "Chipotle",
      "The Cheesecake Factory", "Olive Garden", "Red Lobster", "Applebee's", "TGI Friday's",
      "Outback Steakhouse", "P.F. Chang's", "Buffalo Wild Wings", "Chili's", "Denny's",
      "IHOP", "Waffle House", "Cracker Barrel", "Bob Evans", "Perkins",
      "El Pollo Loco", "Del Taco", "Jack in the Box", "Carl's Jr.", "Hardee's",
      "Wendy's", "Arby's", "Sonic Drive-In", "Dairy Queen", "Culver's",
      "In-N-Out Burger", "Shake Shack", "Whataburger", "White Castle", "Steak 'n Shake",
      "Portillo's", "Raising Cane's", "Zaxby's", "Wingstop", "Popeyes",
      "Church's Chicken", "Bojangles", "Chick-fil-A", "Jersey Mike's", "Jimmy John's",
      "Firehouse Subs", "Potbelly", "Panera Bread", "Au Bon Pain", "Corner Bakery",
      "Jason's Deli", "McAlister's Deli", "Newk's Eatery", "Noodles & Company", "Fazoli's",
      "Sbarro", "Cicis Pizza", "Little Caesars", "Marco's Pizza", "Round Table Pizza",
      "California Pizza Kitchen", "BJ's Restaurant", "Uno Pizzeria", "Giordano's", "Lou Malnati's",
      "Portofino", "Trattoria Italiana", "Casa Madrid", "El Rincón Mexicano", "Tokyo Ramen",
      "Seoul Kitchen", "Bangkok Street", "Mumbai Spice", "Mediterranean Grill", "Greek Taverna",
      "French Bistro", "German Haus", "British Pub", "Irish Tavern", "Scottish Inn",
      "Nordic Kitchen", "Polish Deli", "Russian Tea Room", "Turkish Delight", "Lebanese House",
      "Moroccan Palace", "Ethiopian Kitchen", "South African Grill", "Brazilian Steakhouse", "Argentinian Parrilla"
    ];

    final tagOptions = [
      ["Italian", "Pizza", "Pasta"],
      ["Japanese", "Sushi", "Ramen"],
      ["Mexican", "Tacos", "Burritos"],
      ["American", "Burgers", "Fries"],
      ["Chinese", "Noodles", "Dim Sum"],
      ["Indian", "Curry", "Tandoori"],
      ["Thai", "Pad Thai", "Curry"],
      ["Mediterranean", "Kebab", "Falafel"],
      ["Spanish", "Tapas", "Paella"],
      ["French", "Croissant", "Fine Dining"],
      ["Korean", "BBQ", "Kimchi"],
      ["Vietnamese", "Pho", "Banh Mi"],
      ["Greek", "Gyros", "Souvlaki"],
      ["Fast Food", "Quick Service", "Takeaway"],
      ["Seafood", "Fish", "Shellfish"],
    ];

    final addresses = [
      "123 Main St", "456 Oak Ave", "789 Pine Rd", "321 Elm Blvd", "654 Maple Dr",
      "987 Cedar Ln", "147 Birch Way", "258 Walnut Ct", "369 Cherry Pl", "741 Spruce Ter"
    ];

    final cities = [
      "Madrid", "Barcelona", "Valencia", "Sevilla", "Bilbao",
      "Málaga", "Granada", "Alicante", "Zaragoza", "Murcia"
    ];

    final List<Restaurant> sampleRestaurants = [];
    
    for (int i = 0; i < 100; i++) {
      final isVisited = i % 3 == 0; // ~33% visitados
      final isFavorite = isVisited && i % 6 == 0; // ~16% de visitados son favoritos
      
      sampleRestaurants.add(Restaurant(
        id: (i + 1).toString(),
        name: restaurantNames[i % restaurantNames.length],
        address: "${addresses[i % addresses.length]}, ${cities[i % cities.length]}",
        latitude: 40.4168 + (i * 0.01) - 0.5, // Variación alrededor de Madrid
        longitude: -3.7038 + (i * 0.01) - 0.5,
        tags: tagOptions[i % tagOptions.length],
        addedAt: DateTime.now().subtract(Duration(days: i)),
        isVisited: isVisited,
        isFavorite: isFavorite,
        rating: isVisited ? (i % 5) + 1 : null,
        notes: isVisited ? "Nota de prueba #${i + 1}" : null,
      ));
    }

    for (var restaurant in sampleRestaurants) {
      await _repository.insertRestaurant(restaurant);
    }
  }

  Future<void> addRestaurant(Restaurant restaurant) async {
    await _repository.insertRestaurant(restaurant);
    await loadItems();
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