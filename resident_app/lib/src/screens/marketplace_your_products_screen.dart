// lib/src/screens/marketplace_your_products_screen.dart
// Your Products management screen

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/listing_model.dart';
import '../services/listing_firestore_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../widgets/skeleton_loader.dart';

class MarketplaceYourProductsScreen extends StatefulWidget {
  const MarketplaceYourProductsScreen({super.key});

  @override
  State<MarketplaceYourProductsScreen> createState() =>
      _MarketplaceYourProductsScreenState();
}

class _MarketplaceYourProductsScreenState
    extends State<MarketplaceYourProductsScreen> {
  final ListingFirestoreService _listingService = ListingFirestoreService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ListingModel>>(
      stream: _buildMyListingsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SkeletonListLoader(itemCount: 5, itemHeight: 120);
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64.w,
                  color: Colors.red.shade300,
                ),
                SizedBox(height: 16.h),
                const Text('Error loading your products'),
              ],
            ),
          );
        }

        final listings = snapshot.data ?? [];

        if (listings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 64.w,
                  color: Colors.grey.shade300,
                ),
                SizedBox(height: 16.h),
                const Text('No products yet'),
                SizedBox(height: 8.h),
                Text(
                  'Create your first listing to get started',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            0,
            AppSizes.pagePadding,
            AppSizes.pagePadding,
          ),
          itemCount: listings.length,
          itemBuilder: (context, index) {
            final listing = listings[index];
            return _buildProductCard(context, listing);
          },
        );
      },
    );
  }

  Stream<List<ListingModel>> _buildMyListingsStream() async* {
    try {
      final listings = await _listingService.getMyListings();
      // Filter to show only active products
      final activeListings = listings
          .where((listing) => listing.status == 'active')
          .toList();
      yield activeListings;

      // Also listen for real-time updates
      await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
        final updatedListings = await _listingService.getMyListings();
        final activeUpdated = updatedListings
            .where((listing) => listing.status == 'active')
            .toList();
        yield activeUpdated;
      }
    } catch (e) {
      print('❌ Error streaming my listings: $e');
      yield [];
    }
  }

  Widget _buildProductCard(BuildContext context, ListingModel listing) {
    return GestureDetector(
      onTap: () => _navigateToDetail(context, listing),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
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
            // Header with status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        listing.formattedPrice,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(listing.status),
              ],
            ),

            SizedBox(height: 12.h),

            // Details
            Row(
              children: [
                _buildDetailChip(Icons.category, listing.category),
                SizedBox(width: 8.w),
                _buildDetailChip(Icons.check_circle, listing.condition),
                SizedBox(width: 8.w),
                _buildDetailChip(Icons.calendar_today, listing.formattedDate),
              ],
            ),

            SizedBox(height: 12.h),

            // Phone Requests (Clickable)
            if (listing.phoneRequestCount > 0)
              GestureDetector(
                onTap: () => _navigateToDetail(context, listing),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 16.w,
                        color: Colors.blue.shade600,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '${listing.phoneRequestCount} phone request${listing.phoneRequestCount > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(
                        Icons.arrow_forward,
                        size: 14.w,
                        color: Colors.blue.shade600,
                      ),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 12.h),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _editProduct(context, listing),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: const Text('Edit'),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _markAsSold(context, listing),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: listing.status == 'sold'
                          ? Colors.grey.shade400
                          : Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      listing.status == 'sold' ? 'Sold' : 'Mark Sold',
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _deleteProduct(context, listing),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade500,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'active':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade600;
        label = 'Active';
        break;
      case 'sold':
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade600;
        label = 'Sold';
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade600;
        label = 'Inactive';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.w, color: Colors.grey.shade600),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _editProduct(BuildContext context, ListingModel listing) {
    Navigator.pushNamed(
      context,
      '/marketplace_edit_listing',
      arguments: listing,
    );
  }

  void _navigateToDetail(BuildContext context, ListingModel listing) {
    Navigator.pushNamed(
      context,
      '/marketplace_your_product_detail',
      arguments: listing,
    );
  }

  Future<void> _markAsSold(BuildContext context, ListingModel listing) async {
    if (listing.status == 'sold') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product already marked as sold')),
      );
      return;
    }

    final result = await _listingService.updateListingStatus(
      listing.id!,
      'sold',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Product marked as sold'),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteProduct(
    BuildContext context,
    ListingModel listing,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _listingService.deleteListing(listing.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Product deleted'),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
