import 'package:flutter/material.dart';

class SellerInfoCard extends StatelessWidget {
  final String sellerName;
  final String sellerUnit;
  final String sellerPhone;

  const SellerInfoCard({
    super.key,
    required this.sellerName,
    required this.sellerUnit,
    required this.sellerPhone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: Color(0xFF9CA3AF),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                '$sellerName - $sellerUnit',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.phone,
                color: Color(0xFF9CA3AF),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                sellerPhone,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
