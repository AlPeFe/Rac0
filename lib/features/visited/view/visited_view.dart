import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:raco/features/visited/viewmodel/visited_viewmodel.dart';
import 'package:raco/core/widgets/restaurant_card.dart';
import 'package:raco/core/widgets/search_bar_widget.dart';
import 'package:raco/core/models/restaurant_model.dart';

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
      body: SafeArea(
        child: Consumer<VisitedViewmodel>(
          builder: (context, viewModel, child) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SearchBarWidget(
                        onChanged: viewModel.setSearchQuery,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          FilterChip(
                            label: const Text('Solo favoritos'),
                            selected: viewModel.showOnlyFavorites,
                            onSelected: viewModel.setShowOnlyFavorites,
                            avatar: Icon(
                              viewModel.showOnlyFavorites
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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

  Widget _buildContent(BuildContext context, VisitedViewmodel viewModel) {
    if (viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (viewModel.items.isEmpty) {
      return Center(
        child: Text(
          viewModel.showOnlyFavorites
              ? 'No favorite restaurants'
              : viewModel.searchQuery.isEmpty
                  ? 'No visited restaurants'
                  : 'No results for "${viewModel.searchQuery}"',
        ),
      );
    }

    return ListView.builder(
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
    );
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