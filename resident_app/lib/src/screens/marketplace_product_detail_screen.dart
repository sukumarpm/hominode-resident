// lib/src/screens/marketplace_product_detail_screen.dart
// Product detail screen with phone request functionality

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import '../models/listing_model.dart';
import '../services/listing_firestore_service.dart';
import '../services/image_display_flow_function.dart';
import '../constants/app_colors.dart';

class MarketplaceProductDetailScreen extends StatefulWidget {
  final ListingModel listing;

  const MarketplaceProductDetailScreen({super.key, required this.listing});

  @override
  State<MarketplaceProductDetailScreen> createState() =>
      _MarketplaceProductDetailScreenState();
}

class _MarketplaceProductDetailScreenState
    extends State<MarketplaceProductDetailScreen> {
  final ListingFirestoreService _listingService = ListingFirestoreService();
  bool _isRequestingPhone = false;
  bool _phoneRequested = false;
  bool _isOwnProduct = false;
  bool _isLoadingCheck = true;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _checkIfOwnProduct();
    _checkPhoneRequestStatus();
  }

  Future<void> _checkIfOwnProduct() async {
    try {
      final currentUserId = await _listingService.getCurrentUserId();
      _currentUserId = currentUserId;

      // Check if user already requested phone
      final hasRequested = widget.listing.phoneRequestIds.contains(
        currentUserId,
      );

      setState(() {
        _isOwnProduct = currentUserId == widget.listing.sellerId;
        _phoneRequested = hasRequested;
        _isLoadingCheck = false;
      });
    } catch (e) {
      setState(() => _isLoadingCheck = false);
    }
  }

  Future<void> _checkPhoneRequestStatus() async {
    try {
      // Check if request was accepted
      final acceptedNumbers = await _listingService
          .getAcceptedPhoneNumbersForBuyer(widget.listing.id!);

      if (acceptedNumbers.isNotEmpty) {
        setState(() {
          _phoneRequested = true;
        });
      }
    } catch (e) {
      print('Error checking phone request status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCheck) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Product Details',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Product Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Gallery
            Container(
              height: 300.h,
              color: Colors.grey.shade200,
              child: widget.listing.images.isNotEmpty
                  ? PageView.builder(
                      itemCount: widget.listing.images.length,
                      itemBuilder: (context, index) {
                        final imageUrl = widget.listing.images[index];
                        return Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        );
                      },
                    )
                  : FutureBuilder<ImageDisplayResult>(
                      future: ImageDisplayFlowFunction.instance
                          .getMarketplaceProductImage(
                            listingId: widget.listing.id ?? '',
                          ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          );
                        }

                        if (snapshot.hasData &&
                            snapshot.data!.success &&
                            snapshot.data!.imageUrl != null) {
                          return Image.network(
                            snapshot.data!.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey.shade400,
                                size: 64.w,
                              ),
                            ),
                          );
                        }

                        // No image found
                        return Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey.shade400,
                            size: 64.w,
                          ),
                        );
                      },
                    ),
            ),

            // Details Section
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.listing.title,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // Price
                  Text(
                    widget.listing.formattedPrice,
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Info Row
                  Row(
                    children: [
                      _buildInfoChip('Condition', widget.listing.condition),
                      SizedBox(width: 12.w),
                      _buildInfoChip('Category', widget.listing.category),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Seller Info
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seller Information',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Container(
                              width: 48.w,
                              height: 48.h,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Center(
                                child: Text(
                                  widget.listing.sellerName[0].toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.listing.sellerName,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'Building Member',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Description
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    widget.listing.description,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey.shade700,
                      height: 1.6,
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Posted Date
                  Text(
                    'Posted on ${widget.listing.formattedDate}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Request Phone Button or Show Phone (for buyers only)
                  if (!_isOwnProduct) _buildPhoneSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneRequestButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _phoneRequested || _isRequestingPhone
            ? null
            : _requestPhoneNumber,
        style: ElevatedButton.styleFrom(
          backgroundColor: _phoneRequested ? Colors.grey : AppColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
        child: _isRequestingPhone
            ? SizedBox(
                height: 20.h,
                width: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _phoneRequested
                    ? 'Request Sent - Waiting for Seller'
                    : 'Request Phone Number',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildPhoneSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _listingService.getAcceptedPhoneNumbersForBuyer(
        widget.listing.id!,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 60.h,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final acceptedNumbers = snapshot.data ?? [];

        if (acceptedNumbers.isEmpty) {
          // Show request button if not requested yet
          return _buildPhoneRequestButton();
        }

        // Show accepted phone number
        final phoneData = acceptedNumbers.first;
        final phone = phoneData['phone'] ?? '';
        final sellerName = phoneData['sellerName'] ?? 'Seller';

        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 20.w,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Request Accepted',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                'Seller Phone Number',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      phone,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _copyToClipboard(phone),
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Icon(
                          Icons.copy,
                          color: Colors.white,
                          size: 16.w,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _requestPhoneNumber() async {
    setState(() => _isRequestingPhone = true);

    final result = await _listingService.requestPhoneNumber(widget.listing.id!);

    if (mounted) {
      setState(() => _isRequestingPhone = false);

      if (result.success) {
        setState(() => _phoneRequested = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Phone request sent to seller'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Failed to request phone'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewSellerContact() {
    Navigator.pushNamed(
      context,
      '/marketplace_buyer_phone_view',
      arguments: widget.listing,
    );
  }

  void _copyToClipboard(String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Phone number copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
