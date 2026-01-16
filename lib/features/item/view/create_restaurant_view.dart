import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:raco/features/item/viewmodel/create_restaurant_viewmodel.dart';

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
          title: const Text('Add Restaurant'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(false),
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
                          labelText: 'Restaurant Name',
                          hintText: 'Enter restaurant name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.restaurant),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          hintText: 'Enter address',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an address';
                          }
                          return null;
                        },
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Tags',
                          hintText: 'e.g., Italian, Pizza, Pasta',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label),
                          helperText: 'Separate tags with commas',
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Mark as visited'),
                        subtitle: const Text('Already been to this restaurant?'),
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
                          'Rating',
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
                            labelText: 'Notes',
                            hintText: 'Add your thoughts about this restaurant',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note),
                          ),
                          maxLines: 3,
                        ),
                      ],
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: viewModel.isLoading
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
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
                                  );

                                  if (success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Restaurant added successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    context.pop(true);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: viewModel.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Add Restaurant',
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
