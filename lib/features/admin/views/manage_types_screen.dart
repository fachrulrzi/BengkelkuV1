import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/admin_config_viewmodel.dart';

class ManageTypesScreen extends StatefulWidget {
  const ManageTypesScreen({super.key});

  @override
  State<ManageTypesScreen> createState() => _ManageTypesScreenState();
}

class _ManageTypesScreenState extends State<ManageTypesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminConfigViewModel>().fetchTypes();
    });
  }

  void _showAddEditDialog({String? id, String? initialName, String? initialDesc}) {
    final nameController = TextEditingController(text: initialName);
    final descController = TextEditingController(text: initialDesc);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(id == null ? 'Add Vehicle Type' : 'Edit Vehicle Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Type Name',
                hintText: 'e.g. Sedan, SUV, Motorcycle',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g. 4-Wheeled Passenger Car',
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
                    await viewModel.addType(name, desc);
                  } else {
                    await viewModel.updateType(id, name, desc);
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(id == null ? 'Type added successfully' : 'Type updated successfully')),
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
          'Manage Vehicle Types',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.types.isEmpty
              ? const Center(child: Text('No types added yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: viewModel.types.length,
                  itemBuilder: (context, index) {
                    final type = viewModel.types[index];
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
                          type.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        subtitle: type.description.isNotEmpty
                            ? Text(type.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                              onPressed: () => _showAddEditDialog(id: type.id, initialName: type.name, initialDesc: type.description),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Type'),
                                    content: const Text('Are you sure you want to delete this vehicle type?'),
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
                                    await viewModel.deleteType(type.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Type deleted successfully')),
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
