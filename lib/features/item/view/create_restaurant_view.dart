import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:raco/features/item/viewmodel/create_restaurant_viewmodel.dart';
import 'package:raco/core/models/restaurant_model.dart';

class CreateRestaurantView extends StatefulWidget {
  const CreateRestaurantView({super.key});

  @override
  State<CreateRestaurantView> createState() => _CreateRestaurantViewState();
}

class _CreateRestaurantViewState extends State<CreateRestaurantView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _tagsController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isVisited = false;
  int? _rating;
  PriceRange? _priceRange;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _tagsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreateRestaurantViewmodel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Añadir restaurante'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: SafeArea(
          child: Consumer<CreateRestaurantViewmodel>(
            builder: (context, viewModel, child) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del restaurante',
                          hintText: 'Introduce el nombre',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.restaurant),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor introduce un nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Dirección',
                          hintText: 'Introduce la dirección',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor introduce una dirección';
                          }
                          return null;
                        },
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Categorías',
                          hintText: 'Ej: Italiana, Pizza, Pasta',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label),
                          helperText: 'Separa las categorías con comas',
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Rango de precios
                      const Text(
                        'Rango de precios',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: PriceRange.values.map((price) {
                          final isSelected = _priceRange == price;
                          return ChoiceChip(
                            label: Text(price.display),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _priceRange = selected ? price : null;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      if (_priceRange != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _priceRange!.label,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Marcar como visitado'),
                        subtitle: const Text('¿Ya has ido a este restaurante?'),
                        value: _isVisited,
                        onChanged: (value) {
                          setState(() {
                            _isVisited = value;
                            if (!value) {
                              _rating = null;
                            }
                          });
                        },
                      ),
                      if (_isVisited) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Valoración',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final starValue = index + 1;
                            return IconButton(
                              icon: Icon(
                                starValue <= (_rating ?? 0)
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 32,
                              ),
                              onPressed: () {
                                setState(() {
                                  _rating = starValue;
                                });
                              },
                            );
                          }),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Notas',
                            hintText: 'Añade tus comentarios sobre este restaurante',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note),
                          ),
                          maxLines: 3,
                        ),
                      ],
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: (viewModel.isLoading || _isSubmitting)
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  if (_isSubmitting) return;
                                  setState(() {
                                    _isSubmitting = true;
                                  });

                                  final tags = _tagsController.text
                                      .split(',')
                                      .map((e) => e.trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList();

                                  final success =
                                      await viewModel.createRestaurant(
                                    name: _nameController.text,
                                    address: _addressController.text,
                                    tags: tags,
                                    isVisited: _isVisited,
                                    rating: _rating,
                                    notes: _notesController.text.isEmpty
                                        ? null
                                        : _notesController.text,
                                    priceRange: _priceRange,
                                  );

                                  if (context.mounted) {
                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Restaurante añadido correctamente'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      context.go('/home');
                                    } else {
                                      setState(() {
                                        _isSubmitting = false;
                                      });
                                    }
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: (viewModel.isLoading || _isSubmitting)
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Añadir restaurante',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
