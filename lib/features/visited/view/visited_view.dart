import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:raco/features/visited/viewmodel/visited_viewmodel.dart';
import 'package:raco/core/widgets/restaurant_card.dart';
import 'package:raco/core/widgets/search_bar_widget.dart';
import 'package:raco/core/widgets/filter_sheet.dart';
import 'package:raco/core/models/restaurant_model.dart';
import 'package:raco/core/services/settings_service.dart';

class VisitedView extends StatelessWidget {
  const VisitedView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VisitedViewmodel(),
      child: const _VisitedViewContent(),
    );
  }
}

class _VisitedViewContent extends StatelessWidget {
  const _VisitedViewContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<VisitedViewmodel>(
          builder: (context, viewModel, child) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      SearchBarWidget(
                        onChanged: viewModel.setSearchQuery,
                      ),
                      const SizedBox(height: 8),
                      _buildFilterRow(context, viewModel),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildContent(context, viewModel),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context, VisitedViewmodel viewModel) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Chip de favoritos
          FilterChip(
            label: const Text('Favoritos'),
            selected: viewModel.showOnlyFavorites,
            onSelected: viewModel.setShowOnlyFavorites,
            avatar: Icon(
              viewModel.showOnlyFavorites
                  ? Icons.favorite
                  : Icons.favorite_border,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          // Botón de ordenación
          ActionChip(
            avatar: Icon(viewModel.sortOption.icon, size: 18),
            label: Text(viewModel.sortOption.label),
            onPressed: () => _showSortOptions(context, viewModel),
          ),
          const SizedBox(width: 8),
          // Botón de filtros avanzados
          FilterChipButton(
            filters: viewModel.filters,
            onTap: () => _showFilterSheet(context, viewModel),
          ),
          // Mostrar botón para limpiar filtros
          if (viewModel.filters.hasActiveFilters) ...[
            const SizedBox(width: 8),
            InputChip(
              label: const Text('Limpiar'),
              onPressed: viewModel.clearFilters,
              avatar: const Icon(Icons.close, size: 16),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, VisitedViewmodel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterSheet(
        currentFilters: viewModel.filters,
        availableTags: viewModel.availableTags,
        showRatingFilter: true, // Mostrar filtro de rating en visitados
        onFiltersChanged: viewModel.setFilters,
      ),
    );
  }

  void _showSortOptions(BuildContext context, VisitedViewmodel viewModel) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Ordenar por',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...SortOption.values.map((option) {
              final isSelected = option == viewModel.sortOption;
              return ListTile(
                leading: Icon(option.icon),
                title: Text(option.label),
                trailing: isSelected ? const Icon(Icons.check) : null,
                selected: isSelected,
                onTap: () {
                  viewModel.setSortOption(option);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, VisitedViewmodel viewModel) {
    if (viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (viewModel.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getEmptyIcon(viewModel),
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(viewModel),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (viewModel.filters.hasActiveFilters || viewModel.showOnlyFavorites) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  viewModel.clearFilters();
                  viewModel.setShowOnlyFavorites(false);
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Limpiar filtros'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.loadItems,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: viewModel.items.length,
        itemBuilder: (context, index) {
          final restaurant = viewModel.items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RestaurantCard(
              restaurant: restaurant,
              onTap: () async {
                final result = await context.push<bool>('/restaurant/${restaurant.id}');
                if (result == true && context.mounted) {
                  viewModel.loadItems();
                }
              },
              onLongPress: () => _showDeleteDialog(context, viewModel, restaurant),
              onFavoriteTap: () => viewModel.toggleFavorite(restaurant.id, !restaurant.isFavorite),
            ),
          );
        },
      ),
    );
  }

  IconData _getEmptyIcon(VisitedViewmodel viewModel) {
    if (viewModel.filters.hasActiveFilters) {
      return Icons.filter_list_off;
    } else if (viewModel.showOnlyFavorites) {
      return Icons.favorite;
    }
    return Icons.check_circle;
  }

  String _getEmptyMessage(VisitedViewmodel viewModel) {
    final hasFilters = viewModel.filters.hasActiveFilters;
    final hasFavoriteFilter = viewModel.showOnlyFavorites;
    final hasSearch = viewModel.searchQuery.isNotEmpty;

    if (hasFilters && hasSearch) {
      return 'No hay resultados para "${viewModel.searchQuery}" con los filtros aplicados';
    } else if (hasFavoriteFilter && hasSearch) {
      return 'No hay favoritos que coincidan con "${viewModel.searchQuery}"';
    } else if (hasFilters) {
      return 'No hay restaurantes que coincidan con los filtros';
    } else if (hasFavoriteFilter) {
      return 'No hay restaurantes favoritos';
    } else if (hasSearch) {
      return 'No hay resultados para "${viewModel.searchQuery}"';
    }
    return 'No hay restaurantes visitados';
  }

  void _showDeleteDialog(BuildContext context, VisitedViewmodel viewModel, Restaurant restaurant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar restaurante'),
        content: Text('¿Estás seguro de que quieres eliminar "${restaurant.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              viewModel.deleteRestaurant(restaurant.id);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
