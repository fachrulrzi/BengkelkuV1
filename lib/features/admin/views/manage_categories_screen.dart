import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/admin_config_viewmodel.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminConfigViewModel>().fetchCategories();
    });
  }

  void _showAddEditDialog({String? id, String? initialName, String? initialDesc}) {
    final nameController = TextEditingController(text: initialName);
    final descController = TextEditingController(text: initialDesc);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(id == null ? 'Add Service Category' : 'Edit Service Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g. Tune Up, Servis Rem, Ganti Oli',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g. Perawatan berkala mesin kendaraan',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final desc = descController.text.trim();
              if (name.isNotEmpty) {
                final viewModel = context.read<AdminConfigViewModel>();
                try {
                  if (id == null) {
                    await viewModel.addCategory(name, desc);
                  } else {
                    await viewModel.updateCategory(id, name, desc);
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(id == null ? 'Category added successfully' : 'Category updated successfully')),
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
          'Manage Service Categories',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.categories.isEmpty
              ? const Center(child: Text('No categories added yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: viewModel.categories.length,
                  itemBuilder: (context, index) {
                    final category = viewModel.categories[index];
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
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        subtitle: category.description.isNotEmpty
                            ? Text(category.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                              onPressed: () => _showAddEditDialog(id: category.id, initialName: category.name, initialDesc: category.description),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Category'),
                                    content: const Text('Are you sure you want to delete this service category?'),
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
                                    await viewModel.deleteCategory(category.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Category deleted successfully')),
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
