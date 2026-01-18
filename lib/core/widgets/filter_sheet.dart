import 'package:flutter/material.dart';
import 'package:raco/core/models/restaurant_model.dart';

/// Clase para representar los filtros activos
class RestaurantFilters {
  final Set<String> selectedTags;
  final Set<PriceRange> selectedPriceRanges;
  final int? minRating;

  const RestaurantFilters({
    this.selectedTags = const {},
    this.selectedPriceRanges = const {},
    this.minRating,
  });

  bool get hasActiveFilters =>
      selectedTags.isNotEmpty ||
      selectedPriceRanges.isNotEmpty ||
      minRating != null;

  int get activeFilterCount {
    int count = 0;
    if (selectedTags.isNotEmpty) count++;
    if (selectedPriceRanges.isNotEmpty) count++;
    if (minRating != null) count++;
    return count;
  }

  RestaurantFilters copyWith({
    Set<String>? selectedTags,
    Set<PriceRange>? selectedPriceRanges,
    int? minRating,
    bool clearMinRating = false,
  }) {
    return RestaurantFilters(
      selectedTags: selectedTags ?? this.selectedTags,
      selectedPriceRanges: selectedPriceRanges ?? this.selectedPriceRanges,
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
    );
  }

  RestaurantFilters clear() {
    return const RestaurantFilters();
  }

  /// Comprueba si un restaurante pasa todos los filtros
  bool matches(Restaurant restaurant) {
    // Filtro por categorías
    if (selectedTags.isNotEmpty) {
      final hasMatchingTag = restaurant.tags.any(
        (tag) => selectedTags.contains(tag.toLowerCase()),
      );
      if (!hasMatchingTag) return false;
    }

    // Filtro por rango de precio
    if (selectedPriceRanges.isNotEmpty) {
      if (restaurant.priceRange == null) return false;
      if (!selectedPriceRanges.contains(restaurant.priceRange)) return false;
    }

    // Filtro por rating mínimo
    if (minRating != null) {
      if (restaurant.rating == null) return false;
      if (restaurant.rating! < minRating!) return false;
    }

    return true;
  }
}

/// Widget para mostrar el sheet de filtros
class FilterSheet extends StatefulWidget {
  final RestaurantFilters currentFilters;
  final List<String> availableTags;
  final bool showRatingFilter;
  final ValueChanged<RestaurantFilters> onFiltersChanged;

  const FilterSheet({
    super.key,
    required this.currentFilters,
    required this.availableTags,
    required this.onFiltersChanged,
    this.showRatingFilter = true,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late Set<String> _selectedTags;
  late Set<PriceRange> _selectedPriceRanges;
  late int? _minRating;

  @override
  void initState() {
    super.initState();
    _selectedTags = Set.from(widget.currentFilters.selectedTags);
    _selectedPriceRanges = Set.from(widget.currentFilters.selectedPriceRanges);
    _minRating = widget.currentFilters.minRating;
  }

  void _applyFilters() {
    widget.onFiltersChanged(RestaurantFilters(
      selectedTags: _selectedTags,
      selectedPriceRanges: _selectedPriceRanges,
      minRating: _minRating,
    ));
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _selectedTags = {};
      _selectedPriceRanges = {};
      _minRating = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasFilters = _selectedTags.isNotEmpty ||
        _selectedPriceRanges.isNotEmpty ||
        _minRating != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: hasFilters ? _clearFilters : null,
                    child: const Text('Limpiar'),
                  ),
                  const Text(
                    'Filtros',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _applyFilters,
                    child: const Text('Aplicar'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            
            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Filtro por categorías
                  if (widget.availableTags.isNotEmpty) ...[
                    _buildSectionTitle('Categorías'),
                    const SizedBox(height: 8),
                    _buildTagsFilter(),
                    const SizedBox(height: 24),
                  ],

                  // Filtro por precio
                  _buildSectionTitle('Rango de precio'),
                  const SizedBox(height: 8),
                  _buildPriceFilter(),
                  const SizedBox(height: 24),

                  // Filtro por rating
                  if (widget.showRatingFilter) ...[
                    _buildSectionTitle('Valoración mínima'),
                    const SizedBox(height: 8),
                    _buildRatingFilter(),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildTagsFilter() {
    final sortedTags = List<String>.from(widget.availableTags)..sort();
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sortedTags.map((tag) {
        final isSelected = _selectedTags.contains(tag.toLowerCase());
        return FilterChip(
          label: Text(tag),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedTags.add(tag.toLowerCase());
              } else {
                _selectedTags.remove(tag.toLowerCase());
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildPriceFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PriceRange.values.map((price) {
        final isSelected = _selectedPriceRanges.contains(price);
        return FilterChip(
          label: Text('${price.display} - ${price.label}'),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedPriceRanges.add(price);
              } else {
                _selectedPriceRanges.remove(price);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botones de rating
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Opción "Cualquiera"
            FilterChip(
              label: const Text('Cualquiera'),
              selected: _minRating == null,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _minRating = null);
                }
              },
            ),
            // Opciones de rating mínimo
            ...List.generate(5, (index) {
              final rating = index + 1;
              final isSelected = _minRating == rating;
              return FilterChip(
                avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
                label: Text('$rating+'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _minRating = selected ? rating : null;
                  });
                },
              );
            }),
          ],
        ),
        if (_minRating != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Mostrando restaurantes con $_minRating estrellas o más',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }
}

/// Widget chip que muestra el estado de los filtros
class FilterChipButton extends StatelessWidget {
  final RestaurantFilters filters;
  final VoidCallback onTap;

  const FilterChipButton({
    super.key,
    required this.filters,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilters = filters.hasActiveFilters;
    
    return ActionChip(
      avatar: Icon(
        Icons.filter_list,
        size: 18,
        color: hasFilters ? Theme.of(context).colorScheme.primary : null,
      ),
      label: Text(
        hasFilters ? 'Filtros (${filters.activeFilterCount})' : 'Filtros',
      ),
      onPressed: onTap,
      backgroundColor: hasFilters 
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)
          : null,
    );
  }
}
