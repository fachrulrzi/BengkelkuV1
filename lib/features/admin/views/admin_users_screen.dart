import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/models/user_model.dart';
import '../viewmodels/admin_config_viewmodel.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _roleFilter = 'all'; // 'all', 'customer', 'bengkel', 'mekanik', 'admin'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminConfigViewModel>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUserForm({UserModel? user}) {
    final isEdit = user != null;
    final formKey = GlobalKey<FormState>();
    
    final nameCtrl = TextEditingController(text: user?.name);
    final emailCtrl = TextEditingController(text: user?.email);
    final passwordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: user?.phone);
    final addressCtrl = TextEditingController(text: user?.address);
    UserRole selectedRole = user?.role ?? UserRole.customer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pull handler
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isEdit ? 'Ubah Informasi Pengguna' : 'Tambah Pengguna Baru',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 20),

                  // Nama Lengkap
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Nama lengkap wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: emailCtrl,
                    readOnly: isEdit,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      filled: isEdit,
                      fillColor: isEdit ? Colors.grey.shade100 : null,
                      helperText: isEdit ? 'Email tidak dapat diubah setelah didaftarkan' : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Email wajib diisi';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) return 'Masukkan email yang valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password (hanya untuk Add User)
                  if (!isEdit) ...[
                    TextFormField(
                      controller: passwordCtrl,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        helperText: 'Minimal 6 karakter',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Password wajib diisi';
                        if (val.length < 6) return 'Password minimal 6 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Telepon
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: InputDecoration(
                      labelText: 'No. Telepon',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (val) => val == null || val.trim().isEmpty ? 'No. telepon wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  // Alamat
                  TextFormField(
                    controller: addressCtrl,
                    decoration: InputDecoration(
                      labelText: 'Alamat Lengkap',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.home_outlined),
                    ),
                    maxLines: 2,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Alamat wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  // Role Dropdown
                  DropdownButtonFormField<UserRole>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Peran Pengguna (Role)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.shield_outlined),
                    ),
                    items: UserRole.values
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(r.name.toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedRole = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B2E3C),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      
                      Navigator.pop(ctx); // Close sheet
                      
                      final viewModel = context.read<AdminConfigViewModel>();
                      try {
                        if (isEdit) {
                          await viewModel.updateUser(
                            user.id,
                            fullName: nameCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            address: addressCtrl.text.trim(),
                            role: selectedRole.name,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Informasi pengguna berhasil diperbarui!'), backgroundColor: Colors.green),
                            );
                          }
                        } else {
                          await viewModel.addUser(
                            fullName: nameCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            password: passwordCtrl.text,
                            phone: phoneCtrl.text.trim(),
                            address: addressCtrl.text.trim(),
                            role: selectedRole.name,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Pengguna baru berhasil didaftarkan!'), backgroundColor: Colors.green),
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal menyimpan data: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    child: Text(
                      isEdit ? 'Simpan Perubahan' : 'Daftarkan Pengguna',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Hapus Pengguna', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${user.name}"? Semua data terkait transaksi, kendaraan, dan order pengguna ini akan terhapus secara permanen.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus Permanen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await context.read<AdminConfigViewModel>().deleteUser(user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pengguna berhasil dihapus secara permanen.'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus pengguna: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminConfigViewModel>();

    // Search and filter logic
    List<UserModel> filteredUsers = viewModel.users.where((user) {
      final matchesSearch = user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesRole = _roleFilter == 'all' || user.role.name == _roleFilter;

      return matchesSearch && matchesRole;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserForm(),
        backgroundColor: const Color(0xFF1B2E3C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () => viewModel.fetchUsers(),
        child: Column(
          children: [
            // Search Bar & Filter
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari pengguna berdasarkan nama/email...',
                      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildRoleFilterTab('all', 'Semua'),
                        const SizedBox(width: 8),
                        _buildRoleFilterTab('customer', 'Customer'),
                        const SizedBox(width: 8),
                        _buildRoleFilterTab('bengkel', 'Mitra Bengkel'),
                        const SizedBox(width: 8),
                        _buildRoleFilterTab('mekanik', 'Mekanik'),
                        const SizedBox(width: 8),
                        _buildRoleFilterTab('admin', 'Admin'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // User List
            Expanded(
              child: viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredUsers.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                            const Center(
                              child: Column(
                                children: [
                                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'Pengguna tidak ditemukan',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Coba kata kunci pencarian atau filter lain.',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return _buildUserCard(user);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleFilterTab(String roleCode, String label) {
    final isActive = _roleFilter == roleCode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _roleFilter = roleCode;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1B2E3C) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? Colors.transparent : Colors.grey.shade200),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    Color roleBgColor = Colors.green.shade50;
    Color roleTextColor = Colors.green.shade700;
    if (user.role == UserRole.bengkel) {
      roleBgColor = Colors.blue.shade50;
      roleTextColor = Colors.blue.shade700;
    } else if (user.role == UserRole.mekanik) {
      roleBgColor = Colors.orange.shade50;
      roleTextColor = Colors.orange.shade700;
    } else if (user.role == UserRole.admin) {
      roleBgColor = Colors.purple.shade50;
      roleTextColor = Colors.purple.shade700;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Avatar / Role representation icon
          CircleAvatar(
            radius: 22,
            backgroundColor: roleBgColor,
            child: Icon(
              user.role == UserRole.customer
                  ? Icons.person
                  : user.role == UserRole.bengkel
                      ? Icons.storefront
                      : user.role == UserRole.mekanik
                          ? Icons.build
                          : Icons.admin_panel_settings,
              color: roleTextColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),

          // User Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user.role.name.toUpperCase(),
                        style: TextStyle(color: roleTextColor, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (user.phone != null && user.phone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.phone!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
                if (user.address != null && user.address!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    user.address!,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Action Buttons
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                onPressed: () => _showUserForm(user: user),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
              const SizedBox(height: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => _confirmDelete(user),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
