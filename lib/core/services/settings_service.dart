import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:raco/core/services/database_service.dart';

enum SortOption {
  dateDesc,
  dateAsc,
  nameAsc,
  nameDesc,
  ratingDesc,
  ratingAsc,
  priceAsc,
  priceDesc;

  String get label {
    switch (this) {
      case SortOption.dateDesc:
        return 'Más recientes';
      case SortOption.dateAsc:
        return 'Más antiguos';
      case SortOption.nameAsc:
        return 'Nombre (A-Z)';
      case SortOption.nameDesc:
        return 'Nombre (Z-A)';
      case SortOption.ratingDesc:
        return 'Mejor valorados';
      case SortOption.ratingAsc:
        return 'Peor valorados';
      case SortOption.priceAsc:
        return 'Precio (menor a mayor)';
      case SortOption.priceDesc:
        return 'Precio (mayor a menor)';
    }
  }

  IconData get icon {
    switch (this) {
      case SortOption.dateDesc:
      case SortOption.dateAsc:
        return Icons.calendar_today;
      case SortOption.nameAsc:
      case SortOption.nameDesc:
        return Icons.sort_by_alpha;
      case SortOption.ratingDesc:
      case SortOption.ratingAsc:
        return Icons.star;
      case SortOption.priceAsc:
      case SortOption.priceDesc:
        return Icons.euro;
    }
  }
}

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  final DatabaseService _databaseService = DatabaseService();
  
  ThemeMode _themeMode = ThemeMode.system;
  SortOption _sortOption = SortOption.dateDesc;
  bool _isInitialized = false;

  factory SettingsService() {
    return _instance;
  }

  SettingsService._internal();

  ThemeMode get themeMode => _themeMode;
  SortOption get sortOption => _sortOption;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;
    
    final db = await _databaseService.database;
    
    // Cargar tema
    final themeResult = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['theme_mode'],
    );
    if (themeResult.isNotEmpty) {
      final value = themeResult.first['value'] as String;
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ThemeMode.system,
      );
    }

    // Cargar ordenación
    final sortResult = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['sort_option'],
    );
    if (sortResult.isNotEmpty) {
      final value = sortResult.first['value'] as String;
      _sortOption = SortOption.values.firstWhere(
        (e) => e.name == value,
        orElse: () => SortOption.dateDesc,
      );
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    
    final db = await _databaseService.database;
    await db.insert(
      'app_settings',
      {'key': 'theme_mode', 'value': mode.name},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setSortOption(SortOption option) async {
    _sortOption = option;
    notifyListeners();
    
    final db = await _databaseService.database;
    await db.insert(
      'app_settings',
      {'key': 'sort_option', 'value': option.name},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
