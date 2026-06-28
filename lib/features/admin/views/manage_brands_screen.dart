import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/admin_config_viewmodel.dart';

class ManageBrandsScreen extends StatefulWidget {
  const ManageBrandsScreen({super.key});

  @override
  State<ManageBrandsScreen> createState() => _ManageBrandsScreenState();
}

class _ManageBrandsScreenState extends State<ManageBrandsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminConfigViewModel>().fetchBrands();
    });
  }

  void _showAddEditDialog({String? id, String? initialName}) {
    final nameController = TextEditingController(text: initialName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(id == null ? 'Add Vehicle Brand' : 'Edit Vehicle Brand'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Brand Name',
            hintText: 'e.g. Toyota, Honda',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final viewModel = context.read<AdminConfigViewModel>();
                try {
                  if (id == null) {
                    await viewModel.addBrand(name);
                  } else {
                    await viewModel.updateBrand(id, name);
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(id == null ? 'Brand added successfully' : 'Brand updated successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Operation failed: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminConfigViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2E3C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Manage Vehicle Brands',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.brands.isEmpty
              ? const Center(child: Text('No brands added yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: viewModel.brands.length,
                  itemBuilder: (context, index) {
                    final brand = viewModel.brands[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        title: Text(
                          brand.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                              onPressed: () => _showAddEditDialog(id: brand.id, initialName: brand.name),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Brand'),
                                    content: const Text('Are you sure you want to delete this brand?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true && context.mounted) {
                                  try {
                                    await viewModel.deleteBrand(brand.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Brand deleted successfully')),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Failed to delete: $e')),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: const Color(0xFF1B2E3C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
