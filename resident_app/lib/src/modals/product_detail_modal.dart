import 'package:flutter/material.dart';
import '../models/marketplace_item.dart';
import '../components/condition_tag_widget.dart';
import '../components/seller_info_card.dart';
import '../components/primary_cta_button.dart';
import '../components/read_more_text.dart';

class ProductDetailModal extends StatelessWidget {
  final MarketplaceItem product;

  const ProductDetailModal({super.key, required this.product});

  static Future<void> show(BuildContext context, MarketplaceItem product) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Product Details',
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(child: ProductDetailModal(product: product));
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            ).drive(Tween<double>(begin: 0.85, end: 1.0)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final modalWidth = screenWidth * 0.92;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: modalWidth,
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImageSection(context),
              _buildContentSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return SizedBox(
      height: 260,
      width: double.infinity,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 260,
              width: double.infinity,
              child: Image.asset(
                product.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 260,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image,
                      size: 80,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: ConditionTagWidget(condition: product.condition),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '₹${product.price.toInt()}',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0E4778),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  product.category,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ReadMoreText(
            text: 'Barely used study table in excellent condition',
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF9CA3AF),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SellerInfoCard(
            sellerName: 'Priya Sharma',
            sellerUnit: 'A-205',
            sellerPhone: '+91 98765 12345',
          ),
          const SizedBox(height: 20),
          PrimaryCTAButton(
            text: 'Contact Seller',
            icon: Icons.phone,
            onPressed: () {
              // TODO: Integrate url_launcher
              // final Uri phoneUri = Uri(scheme: 'tel', path: '+919876512345');
              // if (await canLaunchUrl(phoneUri)) {
              //   await launchUrl(phoneUri);
              // }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Calling +91 98765 12345...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
