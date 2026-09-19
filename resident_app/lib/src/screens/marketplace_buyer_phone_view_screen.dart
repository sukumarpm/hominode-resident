// lib/src/screens/marketplace_buyer_phone_view_screen.dart
// Screen for buyer to view accepted phone numbers from sellers

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import '../models/listing_model.dart';
import '../services/listing_firestore_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class MarketplaceBuyerPhoneViewScreen extends StatefulWidget {
  final ListingModel listing;

  const MarketplaceBuyerPhoneViewScreen({super.key, required this.listing});

  @override
  State<MarketplaceBuyerPhoneViewScreen> createState() =>
      _MarketplaceBuyerPhoneViewScreenState();
}

class _MarketplaceBuyerPhoneViewScreenState
    extends State<MarketplaceBuyerPhoneViewScreen> {
  final ListingFirestoreService _listingService = ListingFirestoreService();
  final bool _isLoading = false;

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
          'Seller Contact',
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
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Info
                    _buildProductCard(),
                    const SizedBox(height: AppSizes.spaceBetweenSections),

                    // Seller Contact Info
                    _buildSellerContactSection(),
                    const SizedBox(height: AppSizes.spaceBetweenSections),

                    // Instructions
                    _buildInstructionsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProductCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.listing.title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            widget.listing.formattedPrice,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Seller: ${widget.listing.sellerName}',
            style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerContactSection() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getSellerPhoneNumber(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final phoneData = snapshot.data;

        if (phoneData == null) {
          return Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.orange.shade600, size: 20.w),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Seller has not accepted your request yet',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.orange.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

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
              SizedBox(height: 16.h),
              Text(
                'Seller Name',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                sellerName,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Phone Number',
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
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _callSeller(phone),
                  icon: const Icon(Icons.phone),
                  label: const Text('Call Seller'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstructionsSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tips for Contacting Seller',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade600,
            ),
          ),
          SizedBox(height: 12.h),
          _buildTipItem('Be polite and respectful'),
          _buildTipItem('Ask about product condition'),
          _buildTipItem('Arrange meeting in safe location'),
          _buildTipItem('Inspect product before payment'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, size: 16.w, color: Colors.blue.shade600),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13.sp, color: Colors.blue.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _getSellerPhoneNumber() async {
    try {
      // Get accepted phone numbers for this listing
      final acceptedNumbers = await _listingService
          .getAcceptedPhoneNumbersForBuyer(widget.listing.id!);

      if (acceptedNumbers.isNotEmpty) {
        return acceptedNumbers.first;
      }

      return null;
    } catch (e) {
      print('❌ Error fetching seller phone: $e');
      return null;
    }
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

  void _callSeller(String phone) {
    // In production, use url_launcher to make actual calls
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Call $phone'), backgroundColor: Colors.green),
    );
  }
}
