// lib/src/screens/qr_scanner_screen.dart
// QR Scanner Screen - Scans visitor QR codes and fetches data from Firestore

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../services/visitor_firestore_service.dart';

/// QR Scanner Screen
/// Scans visitor QR codes and displays visitor information from Firestore
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  
  final _firestore = FirebaseFirestore.instance;
  final _visitorService = VisitorFirestoreService();
  
  bool _isProcessing = false;
  bool _hasScanned = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleQRCode(String qrData) async {
    if (_isProcessing || _hasScanned) return;
    
    setState(() {
      _isProcessing = true;
      _hasScanned = true;
    });

    print('🔵 QR Scanner: Scanned data: $qrData');

    try {
      // Parse QR code data
      final Map<String, dynamic> qrJson = jsonDecode(qrData);
      final String visitorId = qrJson['visitorId'] ?? '';

      if (visitorId.isEmpty) {
       