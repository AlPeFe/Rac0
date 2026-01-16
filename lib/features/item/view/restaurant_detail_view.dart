import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:raco/features/item/viewmodel/restaurant_detail_viewmodel.dart';
import 'package:raco/core/services/map_launcher_service.dart';

class RestaurantDetailView extends StatelessWidget {
  final String restaurantId;

  const RestaurantDetailView({
    super.key,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RestaurantDetailViewmodel(restaurantId),
      child: Scaffold(
        body: Consumer<RestaurantDetailViewmodel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final restaurant = viewModel.restaurant;
            if (restaurant == null) {
              return const Center(child: Text('Restaurant not found'));
            }

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(false),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        // TODO: Navigate to edit screen
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Restaurant'),
                            content: const Text(
                                'Are you sure you want to delete this restaurant?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
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
                      },
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
                            Theme.of(context).primaryColor.withOpacity(0.7),
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
                        // Address
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

                        // Navigate to Map Button
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
                            label: const Text('Open in Google Maps'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Tags
                        if (restaurant.tags.isNotEmpty) ...[
                          const Text(
                            'Categories',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: restaurant.tags.map((tag) {
                              return Chip(
                                label: Text(tag),
                                backgroundColor: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Visited Status
                        Card(
                          child: SwitchListTile(
                            title: const Text('Visited'),
                            subtitle: Text(
                              restaurant.isVisited
                                  ? 'You have been here'
                                  : 'Not visited yet',
                            ),
                            value: restaurant.isVisited,
                            onChanged: (value) async {
                              await viewModel.toggleVisited(value);
                              if (context.mounted) {
                                context.pop(true);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Rating
                        if (restaurant.isVisited) ...[
                          const Text(
                            'Your Rating',
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
                                      starValue <= (restaurant.rating ?? 0)
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 32,
                                    ),
                                    onPressed: () async {
                                      await viewModel.updateRating(starValue);
                                    },
                                  );
                                }),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Notes
                        if (restaurant.isVisited) ...[
                          const Text(
                            'Notes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                restaurant.notes?.isEmpty ?? true
                                    ? 'No notes yet'
                                    : restaurant.notes!,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Added date
                        const SizedBox(height: 8),
                        Text(
                          'Added on ${_formatDate(restaurant.addedAt)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openInMaps(
    BuildContext context, {
    required double latitude,
    required double longitude,
    required String address,
    required String name,
  }) async {
    // Mostrar opciones al usuario
    final option = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.navigation),
              title: const Text('Navigate (Driving)'),
              subtitle: const Text('Open navigation to this location'),
              onTap: () => Navigator.pop(context, 'navigate'),
            ),
            ListTile(
              leading: const Icon(Icons.place),
              title: const Text('View on Map (Coordinates)'),
              subtitle: Text('$latitude, $longitude'),
              onTap: () => Navigator.pop(context, 'coordinates'),
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Search by Address'),
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
          content: Text('Could not open Google Maps'),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
