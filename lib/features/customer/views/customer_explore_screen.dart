import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/customer_marketplace_viewmodel.dart';
import 'customer_bengkel_list_tab.dart';
import 'customer_marketplace_screen.dart';
import 'cart_screen.dart';

class CustomerExploreScreen extends StatelessWidget {
  const CustomerExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CustomerMarketplaceViewModel>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text(
            'Explore',
            style: GoogleFonts.outfit(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: -0.5,
            ),
          ),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Marketplace'),
              Tab(text: 'Servis'),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.textPrimary),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CartScreen()),
                      );
                    },
                  ),
                  if (viewModel.cartCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${viewModel.cartCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            )
          ],
        ),
        body: const TabBarView(
          children: [
            CustomerMarketplaceScreen(),
            CustomerBengkelListTab(),
          ],
        ),
      ),
    );
  }
}
