import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raco/core/services/settings_service.dart';
import 'package:raco/core/services/backup_service.dart';
import 'package:raco/core/services/restaurant_repository.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final BackupService _backupService = BackupService();
  final RestaurantRepository _repository = RestaurantRepository();
  RestaurantStats? _stats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final stats = await _repository.getStats();
      setState(() {
        _stats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() => _isLoadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: Consumer<SettingsService>(
        builder: (context, settings, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Sección de estadísticas
              _buildSectionTitle('Estadísticas'),
              _buildStatsCard(),
              const SizedBox(height: 24),

              // Sección de apariencia
              _buildSectionTitle('Apariencia'),
              _buildThemeSelector(settings),
              const SizedBox(height: 24),

              // Sección de ordenación
              _buildSectionTitle('Ordenación por defecto'),
              _buildSortSelector(settings),
              const SizedBox(height: 24),

              // Sección de datos
              _buildSectionTitle('Datos'),
              _buildBackupSection(),
              const SizedBox(height: 24),

              // Información de la app
              _buildSectionTitle('Acerca de'),
              _buildAboutCard(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    if (_isLoadingStats) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_stats == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Error al cargar estadísticas'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contadores principales
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.restaurant,
                    label: 'Total',
                    value: _stats!.total.toString(),
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.pending_actions,
                    label: 'Pendientes',
                    value: _stats!.pending.toString(),
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.check_circle,
                    label: 'Visitados',
                    value: _stats!.visited.toString(),
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.favorite,
                    label: 'Favoritos',
                    value: _stats!.favorites.toString(),
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            if (_stats!.averageRating != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'Valoración media: ${_stats!.averageRating!.toStringAsFixed(1)} / 5',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ],
            if (_stats!.topTags.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Categorías más usadas:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _stats!.topTags.map((entry) {
                  return Chip(
                    label: Text('${entry.key} (${entry.value})'),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSelector(SettingsService settings) {
    return Card(
      child: RadioGroup<ThemeMode>(
        groupValue: settings.themeMode,
        onChanged: (value) => settings.setThemeMode(value!),
        child: Column(
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Sistema'),
              subtitle: const Text('Sigue la configuración del dispositivo'),
              value: ThemeMode.system,
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Claro'),
              value: ThemeMode.light,
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Oscuro'),
              value: ThemeMode.dark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortSelector(SettingsService settings) {
    return Card(
      child: RadioGroup<SortOption>(
        groupValue: settings.sortOption,
        onChanged: (value) => settings.setSortOption(value!),
        child: Column(
          children: SortOption.values.map((option) {
            return RadioListTile<SortOption>(
              title: Text(option.label),
              secondary: Icon(option.icon),
              value: option,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBackupSection() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Exportar datos'),
            subtitle: const Text('Guardar todos los restaurantes en un archivo'),
            onTap: _exportBackup,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Importar datos'),
            subtitle: const Text('Añadir restaurantes desde un archivo'),
            onTap: _importBackup,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Importar y reemplazar'),
            subtitle: const Text('Actualizar restaurantes existentes'),
            onTap: _importBackupWithReplace,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Raco'),
            subtitle: const Text('Versión 1.0.0'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: const Text('Tu lista de restaurantes'),
            subtitle: const Text('Guarda los lugares que quieres visitar y recuerda si te gustaron'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup() async {
    final success = await _backupService.exportBackup(context);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Backup exportado correctamente'
                : 'Error al exportar el backup',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _importBackup() async {
    final result = await _backupService.importBackup();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? 'Importados: ${result.imported}, Omitidos: ${result.skipped}, Errores: ${result.errors}'
                : result.message,
          ),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
      if (result.success) {
        _loadStats();
      }
    }
  }

  Future<void> _importBackupWithReplace() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importar y reemplazar'),
        content: const Text(
          'Esta acción actualizará los restaurantes existentes con los datos del archivo. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _backupService.importBackupWithReplace();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? 'Nuevos: ${result.imported}, Actualizados: ${result.updated}, Errores: ${result.errors}'
                : result.message,
          ),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
      if (result.success) {
        _loadStats();
      }
    }
  }
}
