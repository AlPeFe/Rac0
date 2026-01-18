import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:raco/features/item/viewmodel/restaurant_detail_viewmodel.dart';
import 'package:raco/core/services/map_launcher_service.dart';
import 'package:raco/core/models/restaurant_model.dart';

class RestaurantDetailView extends StatefulWidget {
  final String restaurantId;

  const RestaurantDetailView({
    super.key,
    required this.restaurantId,
  });

  @override
  State<RestaurantDetailView> createState() => _RestaurantDetailViewState();
}

class _RestaurantDetailViewState extends State<RestaurantDetailView> {
  final _notesController = TextEditingController();
  final _tagController = TextEditingController();
  bool _notesInitialized = false;

  @override
  void dispose() {
    _notesController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop(RestaurantDetailViewmodel viewModel) async {
    if (viewModel.hasUnsavedChanges) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cambios sin guardar'),
          content: const Text(
            '¿Estás seguro de que quieres salir? Los cambios no guardados se perderán.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Salir sin guardar'),
            ),
          ],
        ),
      );
      return result ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RestaurantDetailViewmodel(widget.restaurantId),
      child: Consumer<RestaurantDetailViewmodel>(
        builder: (context, viewModel, child) {
          // Inicializar el controlador de notas cuando se carga el restaurante
          if (!_notesInitialized && viewModel.restaurant != null) {
            _notesController.text = viewModel.editedNotes;
            _notesInitialized = true;
          }

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              final shouldPop = await _onWillPop(viewModel);
              if (shouldPop && context.mounted) {
                context.pop(viewModel.hasUnsavedChanges ? true : false);
              }
            },
            child: Scaffold(
              body: _buildBody(context, viewModel),
              bottomNavigationBar: viewModel.restaurant != null
                  ? _buildBottomBar(context, viewModel)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, RestaurantDetailViewmodel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final restaurant = viewModel.restaurant;
    if (restaurant == null) {
      return const Center(child: Text('Restaurante no encontrado'));
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _onWillPop(viewModel);
              if (shouldPop && context.mounted) {
                context.pop(false);
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteDialog(context, viewModel),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              restaurant.name,
              style: const TextStyle(
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 3.0,
                    color: Colors.black45,
                  ),
                ],
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: const Icon(
                Icons.restaurant,
                size: 80,
                color: Colors.white54,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dirección
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        restaurant.address,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Botón abrir en mapa
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openInMaps(
                      context,
                      latitude: restaurant.latitude,
                      longitude: restaurant.longitude,
                      address: restaurant.address,
                      name: restaurant.name,
                    ),
                    icon: const Icon(Icons.map),
                    label: const Text('Abrir en Google Maps'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Categorías editables
                _buildTagsSection(context, viewModel),
                const SizedBox(height: 24),

                // Rango de precios
                _buildPriceRangeSection(context, viewModel),
                const SizedBox(height: 24),

                // Estado visitado
                _buildVisitedSection(context, viewModel),
                const SizedBox(height: 16),

                // Rating (solo si está marcado como visitado)
                if (viewModel.editedIsVisited) ...[
                  _buildRatingSection(context, viewModel),
                  const SizedBox(height: 16),
                ],

                // Notas (solo si está marcado como visitado)
                if (viewModel.editedIsVisited) ...[
                  _buildNotesSection(context, viewModel),
                  const SizedBox(height: 16),
                ],

                // Fecha de añadido
                const SizedBox(height: 8),
                Text(
                  'Añadido el ${_formatDate(restaurant.addedAt)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 80), // Espacio para el botón inferior
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection(BuildContext context, RestaurantDetailViewmodel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categorías',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...viewModel.editedTags.map((tag) {
              return Chip(
                label: Text(tag),
                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => viewModel.removeTag(tag),
              );
            }),
            // Botón para añadir nueva categoría
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: const Text('Añadir'),
              onPressed: () => _showAddTagDialog(context, viewModel),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceRangeSection(BuildContext context, RestaurantDetailViewmodel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rango de precios',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ...PriceRange.values.map((price) {
                  final isSelected = viewModel.editedPriceRange == price;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(price.display),
                        selected: isSelected,
                        onSelected: (selected) {
                          viewModel.setPriceRange(selected ? price : null);
                        },
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        if (viewModel.editedPriceRange != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              viewModel.editedPriceRange!.label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVisitedSection(BuildContext context, RestaurantDetailViewmodel viewModel) {
    return Card(
      child: SwitchListTile(
        title: const Text('Visitado'),
        subtitle: Text(
          viewModel.editedIsVisited
              ? 'Has visitado este restaurante'
              : 'Aún no visitado',
        ),
        value: viewModel.editedIsVisited,
        onChanged: (value) {
          viewModel.setIsVisited(value);
          if (!value) {
            _notesController.clear();
          }
        },
      ),
    );
  }

  Widget _buildRatingSection(BuildContext context, RestaurantDetailViewmodel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tu valoración',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return IconButton(
                  icon: Icon(
                    starValue <= (viewModel.editedRating ?? 0)
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () {
                    viewModel.setRating(starValue);
                  },
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection(BuildContext context, RestaurantDetailViewmodel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Añade tus notas sobre este restaurante...',
                border: InputBorder.none,
              ),
              maxLines: 4,
              onChanged: (value) {
                viewModel.setNotes(value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, RestaurantDetailViewmodel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Indicador de cambios
            if (viewModel.hasUnsavedChanges)
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cambios sin guardar',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              const Spacer(),
            
            // Botón guardar
            ElevatedButton.icon(
              onPressed: viewModel.hasUnsavedChanges && !viewModel.isSaving
                  ? () => _saveChanges(context, viewModel)
                  : null,
              icon: viewModel.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(viewModel.isSaving ? 'Guardando...' : 'Guardar'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges(BuildContext context, RestaurantDetailViewmodel viewModel) async {
    final success = await viewModel.saveChanges();
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cambios guardados correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar los cambios'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showAddTagDialog(BuildContext context, RestaurantDetailViewmodel viewModel) async {
    _tagController.clear();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir categoría'),
        content: TextField(
          controller: _tagController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ej: Italiana, Mexicana, Sushi...',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              viewModel.addTag(value.trim());
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (_tagController.text.trim().isNotEmpty) {
                viewModel.addTag(_tagController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, RestaurantDetailViewmodel viewModel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar restaurante'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar este restaurante?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await viewModel.deleteRestaurant();
      if (context.mounted) {
        context.pop(true);
      }
    }
  }

  Future<void> _openInMaps(
    BuildContext context, {
    required double latitude,
    required double longitude,
    required String address,
    required String name,
  }) async {
    final option = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.navigation),
              title: const Text('Navegar (Conducir)'),
              subtitle: const Text('Abrir navegación a esta ubicación'),
              onTap: () => Navigator.pop(context, 'navigate'),
            ),
            ListTile(
              leading: const Icon(Icons.place),
              title: const Text('Ver en mapa (Coordenadas)'),
              subtitle: Text('$latitude, $longitude'),
              onTap: () => Navigator.pop(context, 'coordinates'),
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Buscar por dirección'),
              subtitle: Text(address),
              onTap: () => Navigator.pop(context, 'address'),
            ),
          ],
        ),
      ),
    );

    if (option == null) return;

    bool success = false;

    switch (option) {
      case 'navigate':
        success = await MapLauncherService.openMapsForNavigation(
          latitude: latitude,
          longitude: longitude,
          address: address,
        );
        break;
      case 'coordinates':
        success = await MapLauncherService.openMapsWithCoordinates(
          latitude: latitude,
          longitude: longitude,
          label: name,
        );
        break;
      case 'address':
        success = await MapLauncherService.openMapsWithAddress(
          address: address,
        );
        break;
    }

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir Google Maps'),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
