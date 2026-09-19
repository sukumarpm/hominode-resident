// lib/src/screens/marketplace_your_product_detail_screen.dart
// Product detail screen for seller's own products

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../models/listing_model.dart';
import '../services/listing_firestore_service.dart';
import 'marketplace_edit_listing_screen.dart';

class MarketplaceYourProductDetailScreen extends StatefulWidget {
  final ListingModel listing;

  const MarketplaceYourProductDetailScreen({super.key, required this.listing});

  @override
  State<MarketplaceYourProductDetailScreen> createState() =>
      _MarketplaceYourProductDetailScreenState();
}

class _MarketplaceYourProductDetailScreenState
    extends State<MarketplaceYourProductDetailScreen> {
  final ListingFirestoreService _listingService = ListingFirestoreService();
  late PageController _imageController;
  int _currentImageIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _imageController = PageController();
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Product Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Gallery
                  _buildImageGallery(),

                  // Product Info
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.pagePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Price
                        _buildTitleSection(),
                        const SizedBox(height: AppSizes.spaceBetweenSections),

                        // Category, Condition, Date
                        _buildDetailsChips(),
                        const SizedBox(height: AppSizes.spaceBetweenSections),

                        // Description
                        _buildDescriptionSection(),
                        const SizedBox(height: AppSizes.spaceBetweenSections),

                        // Phone Requests
                        _buildPhoneRequestsSection(),
                        const SizedBox(height: AppSizes.spaceBetweenSections),

                        if (widget.listing.status == 'active') ...[
                          const SizedBox(height: AppSizes.spaceBetweenSections),
                          _buildActionButtons(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildImageGallery() {
    if (widget.listing.images.isEmpty) {
      return Container(
        height: 300.h,
        color: Colors.grey.shade200,
        child: Center(
          child: Icon(
            Icons.image_not_supported,
            size: 64.w,
            color: Colors.grey.shade400,
          ),
        ),
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: 300.h,
          child: PageView.builder(
            controller: _imageController,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemCount: widget.listing.images.length,
            itemBuilder: (context, index) {
              return Image.network(
                widget.listing.images[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.broken_image,
                      size: 64.w,
                      color: Colors.grey.shade400,
                    ),
                  );
                },
              );
            },
          ),
        ),
        // Image counter
        Positioned(
          bottom: 12,
          right: 12,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              '${_currentImageIndex + 1}/${widget.listing.images.length}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.listing.title,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
            _buildStatusBadge(widget.listing.status),
          ],
        ),
        SizedBox(height: 8.h),
        Text(
          widget.listing.formattedPrice,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
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

  Widget _buildDetailsChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildDetailChip(Icons.category, widget.listing.category),
        _buildDetailChip(Icons.check_circle, widget.listing.condition),
        _buildDetailChip(Icons.calendar_today, widget.listing.formattedDate),
      ],
    );
  }

  Widget _buildDetailChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.w, color: Colors.grey.shade600),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          widget.listing.description,
          style: TextStyle(
            fontSize: 13.sp,
            color: Colors.grey.shade700,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneRequestsSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _listingService.streamPhoneRequestsForListing(widget.listing.id!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 100.h,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.phone, color: Colors.blue.shade600, size: 20.w),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'No phone requests yet',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phone Requests (${requests.length})',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 12.h),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return _buildPhoneRequestCard(request);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPhoneRequestCard(Map<String, dynamic> request) {
    final status = request['status'] ?? 'pending';
    final requesterName =
        request['requesterName'] ?? request['requestUserName'] ?? 'Unknown';
    final flatLabel =
        request['flatLabel'] ?? request['requestUserFlat'] ?? 'N/A';
    final requestId = request['requestId'] ?? request['id'] ?? '';
    final requesterId =
        request['requesterId'] ?? request['requestUserId'] ?? '';
    final createdAt = request['createdAt'];

    // Format the request time
    String formattedTime = 'Just now';
    if (createdAt != null) {
      try {
        final requestTime = (createdAt as Timestamp).toDate();
        final now = DateTime.now();
        final difference = now.difference(requestTime);

        if (difference.inMinutes < 1) {
          formattedTime = 'Just now';
        } else if (difference.inMinutes < 60) {
          formattedTime = '${difference.inMinutes}m ago';
        } else if (difference.inHours < 24) {
          formattedTime = '${difference.inHours}h ago';
        } else if (difference.inDays < 7) {
          formattedTime = '${difference.inDays}d ago';
        } else {
          formattedTime =
              '${requestTime.day}/${requestTime.month}/${requestTime.year}';
        }
      } catch (e) {
        formattedTime = 'Recently';
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Requester Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requesterName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Flat: $flatLabel',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadgeSmall(status),
            ],
          ),

          SizedBox(height: 12.h),

          // Accept/Reject Buttons (for pending requests)
          if (status == 'pending')
            Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectRequest(requestId),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text('Reject', style: TextStyle(fontSize: 12.sp)),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _acceptRequest(requestId, requesterId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text('Accept', style: TextStyle(fontSize: 12.sp)),
                    ),
                  ),
                ],
              ),
            ),

          // Accepted status display
          if (status == 'accepted')
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16.w,
                    color: Colors.green.shade600,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Request accepted',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Rejected status display
          if (status == 'rejected')
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.cancel, size: 16.w, color: Colors.red.shade600),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Request rejected',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadgeSmall(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'accepted':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade600;
        label = 'Accepted';
        break;
      case 'rejected':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade600;
        label = 'Rejected';
        break;
      default:
        bgColor = Colors.yellow.shade50;
        textColor = Colors.yellow.shade700;
        label = 'Pending';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    // Historical listings are read-only.
    // Sold/deleted listings must not be edited, sold again, or deleted.
    if (widget.listing.status != 'active') {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: AppSizes.buttonHeightPrimary,
          child: ElevatedButton(
            onPressed: _editProduct,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusButton),
              ),
            ),
            child: const Text('Edit Product'),
          ),
        ),
        SizedBox(height: 10.h),
        SizedBox(
          width: double.infinity,
          height: AppSizes.buttonHeightSecondary,
          child: OutlinedButton(
            onPressed: _markAsSold,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusButton),
              ),
            ),
            child: const Text('Mark as Sold'),
          ),
        ),
        SizedBox(height: 10.h),
        SizedBox(
          width: double.infinity,
          height: AppSizes.buttonHeightSecondary,
          child: OutlinedButton(
            onPressed: _deleteProduct,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusButton),
              ),
            ),
            child: const Text('Delete Product'),
          ),
        ),
      ],
    );
  }

  Future<void> _acceptRequest(String requestId, String requesterId) async {
    setState(() => _isLoading = true);

    final result = await _listingService.acceptPhoneRequest(
      widget.listing.id!,
      requestId,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Request accepted'),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
      if (result.success) {
        setState(() {});
      }
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    setState(() => _isLoading = true);

    final result = await _listingService.rejectPhoneRequest(
      widget.listing.id!,
      requestId,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Request rejected'),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
      if (result.success) {
        setState(() {});
      }
    }
  }

  void _editProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MarketplaceEditListingScreen(listing: widget.listing),
      ),
    );
  }

  Future<void> _markAsSold() async {
    if (widget.listing.status == 'sold') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product already marked as sold')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _listingService.updateListingStatus(
      widget.listing.id!,
      'sold',
    );

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Product marked as sold'),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
      if (result.success) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _deleteProduct() async {
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
      setState(() => _isLoading = true);

      final result = await _listingService.deleteListing(widget.listing.id!);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Product deleted'),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
        if (result.success) {
          Navigator.pop(context);
        }
      }
    }
  }
}
