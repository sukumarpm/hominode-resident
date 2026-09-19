// lib/src/screens/marketplace_screen_enhanced.dart
// Enhanced Marketplace with Browse & Your Products tabs, real data only

import 'package:flutter/material.dart';
import '../models/listing_model.dart';
import '../services/listing_firestore_service.dart';
import '../components/app_segmented_control.dart';
import '../components/primary_header.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../widgets/skeleton_loader.dart';
import 'marketplace_product_detail_screen.dart';
import 'marketplace_your_products_screen.dart';
import 'marketplace_create_listing_screen.dart';
import 'marketplace_your_product_detail_screen.dart';
import 'marketplace_edit_listing_screen.dart';

class MarketplaceScreenEnhanced extends StatefulWidget {
  const MarketplaceScreenEnhanced({super.key});

  @override
  State<MarketplaceScreenEnhanced> createState() => _MarketplaceScreenEnhancedState();
}

class _MarketplaceScreenEnhancedState extends State<MarketplaceScreenEnhanced> {
  final ListingFirestoreService _listingService = ListingFirestoreService();
  int _selectedTab = 0; // 0 = Browse, 1 = Your Products
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';
  final List<String> _categories = ['All', 'Furniture', 'Electronics', 'Other'];

  String get _selectedCategory => _categories[_selectedCategoryIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          const PrimaryHeader(title: 'Marketplace'),
          
          const SizedBox(height: 20),
          
          // Segmented Control - Browse & Your Products
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
            child: AppSegmentedControl(
              segments: const ['Browse', 'Your Products'],
              selectedIndex: _selectedTab,
              onChanged: (index) {
                setState(() {
                  _selectedTab = index;
                });
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Content
          Expanded(
            child: _selectedTab == 0
                ? _buildBrowseTab()
                : Navigator(
                    onGenerateRoute: (settings) {
                      switch (settings.name) {
                        case '/marketplace_your_product_detail':
                          final listing = settings.arguments as ListingModel;
                          return MaterialPageRoute(
                            builder: (_) => MarketplaceYourProductDetailScreen(
                              listing: listing,
                            ),
                          );
                        case '/marketplace_edit_listing':
                          final listing = settings.arguments as ListingModel;
                          return MaterialPageRoute(
                            builder: (_) => MarketplaceEditListingScreen(
                              listing: listing,
                            ),
                          );
                        default:
                          return MaterialPageRoute(
                            builder: (_) => const MarketplaceYourProductsScreen(),
                          );
                      }
                    },
                    initialRoute: '/',
                  ),
          ),
        ],
      ),
      floatingActionButton: _selectedTab == 0
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MarketplaceCreateListingScreen(),
                  ),
                );
                if (result == true) {
                  // Refresh the list
                  setState(() {});
                }
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  Widget _buildBrowseTab() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Category Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
          child: AppSegmentedControl(
            segments: _categories,
            selectedIndex: _selectedCategoryIndex,
            onChanged: (index) {
              setState(() => _selectedCategoryIndex = index);
            },
            horizontalMargin: 0,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Listings Grid
        Expanded(
          child: StreamBuilder<List<ListingModel>>(
            stream: _listingService.streamAllListings(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SkeletonListLoader(
                  itemCount: 6,
                  itemHeight: 200,
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      const Text('Error loading products'),
                    ],
                  ),
                );
              }

              final allListings = snapshot.data ?? [];
              
              // Filter listings
              final filteredListings = allListings.where((listing) {
                final matchesCategory = _selectedCategory == 'All' ||
                    listing.category.toLowerCase() == _selectedCategory.toLowerCase();
                final matchesSearch = _searchQuery.isEmpty ||
                    listing.title.toLowerCase().contains(_searchQuery.toLowerCase());
                return matchesCategory && matchesSearch;
              }).toList();

              if (filteredListings.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('No products found'),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.pagePadding,
                  0,
                  AppSizes.pagePadding,
                  AppSizes.pagePadding,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: filteredListings.length,
                itemBuilder: (context, index) {
                  final listing = filteredListings[index];
                  return _buildProductCard(context, listing);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, ListingModel listing) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MarketplaceProductDetailScreen(listing: listing),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: listing.images.isNotEmpty
                  ? Image.network(
                      listing.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(Icons.image_not_supported, color: Colors.grey.shade400),
                      ),
                    )
                  : Center(
                      child: Icon(Icons.image_not_supported, color: Colors.grey.shade400),
                    ),
            ),
            
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      listing.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Condition
                    Text(
                      listing.condition,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Price & Seller
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          listing.formattedPrice,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          listing.sellerName,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
