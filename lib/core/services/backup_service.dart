import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:raco/core/models/restaurant_model.dart';
import 'package:raco/core/services/restaurant_repository.dart';

class BackupService {
  final RestaurantRepository _repository = RestaurantRepository();

  /// Exporta todos los restaurantes a un archivo JSON y lo comparte
  Future<bool> exportBackup(BuildContext context) async {
    try {
      final restaurants = await _repository.getAllRestaurants();
      
      final backupData = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'count': restaurants.length,
        'restaurants': restaurants.map((r) => r.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      
      // Guardar archivo temporal
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/raco_backup_$timestamp.json');
      await file.writeAsString(jsonString);

      // Compartir archivo
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Backup de Raco',
        text: 'Backup de ${restaurants.length} restaurantes',
      );

      return true;
    } catch (e) {
      debugPrint('Error exporting backup: $e');
      return false;
    }
  }

  /// Importa restaurantes desde un archivo JSON
  Future<BackupImportResult> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return BackupImportResult(
          success: false,
          message: 'No se seleccionó ningún archivo',
        );
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validar estructura
      if (!backupData.containsKey('restaurants')) {
        return BackupImportResult(
          success: false,
          message: 'El archivo no tiene el formato correcto',
        );
      }

      final restaurantsList = backupData['restaurants'] as List;
      int imported = 0;
      int skipped = 0;
      int errors = 0;

      for (final restaurantJson in restaurantsList) {
        try {
          final restaurant = Restaurant.fromJson(restaurantJson as Map<String, dynamic>);
          
          // Verificar si ya existe
          final existing = await _repository.getRestaurantById(restaurant.id);
          if (existing != null) {
            skipped++;
            continue;
          }

          await _repository.insertRestaurant(restaurant);
          imported++;
        } catch (e) {
          debugPrint('Error importing restaurant: $e');
          errors++;
        }
      }

      return BackupImportResult(
        success: true,
        message: 'Importación completada',
        imported: imported,
        skipped: skipped,
        errors: errors,
      );
    } catch (e) {
      debugPrint('Error importing backup: $e');
      return BackupImportResult(
        success: false,
        message: 'Error al leer el archivo: $e',
      );
    }
  }

  /// Importa restaurantes reemplazando los existentes
  Future<BackupImportResult> importBackupWithReplace() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return BackupImportResult(
          success: false,
          message: 'No se seleccionó ningún archivo',
        );
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      if (!backupData.containsKey('restaurants')) {
        return BackupImportResult(
          success: false,
          message: 'El archivo no tiene el formato correcto',
        );
      }

      final restaurantsList = backupData['restaurants'] as List;
      int imported = 0;
      int updated = 0;
      int errors = 0;

      for (final restaurantJson in restaurantsList) {
        try {
          final restaurant = Restaurant.fromJson(restaurantJson as Map<String, dynamic>);
          
          final existing = await _repository.getRestaurantById(restaurant.id);
          if (existing != null) {
            await _repository.updateRestaurant(restaurant);
            updated++;
          } else {
            await _repository.insertRestaurant(restaurant);
            imported++;
          }
        } catch (e) {
          debugPrint('Error importing restaurant: $e');
          errors++;
        }
      }

      return BackupImportResult(
        success: true,
        message: 'Importación completada',
        imported: imported,
        updated: updated,
        errors: errors,
      );
    } catch (e) {
      debugPrint('Error importing backup: $e');
      return BackupImportResult(
        success: false,
        message: 'Error al leer el archivo: $e',
      );
    }
  }
}

class BackupImportResult {
  final bool success;
  final String message;
  final int imported;
  final int skipped;
  final int updated;
  final int errors;

  BackupImportResult({
    required this.success,
    required this.message,
    this.imported = 0,
    this.skipped = 0,
    this.updated = 0,
    this.errors = 0,
  });
}
