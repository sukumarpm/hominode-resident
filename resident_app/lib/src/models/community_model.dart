import 'package:cloud_firestore/cloud_firestore.dart';

import 'community_feature_flags.dart';

class CommunityModel {
  static const String defaultDatabaseId = '(default)';

  final String id;
  final String name;
  final String slug;
  final String websitePath;
  final String databaseId;
  final String? logoUrl;
  final String brandName;
  final String? primaryColor;
  final String? secondaryColor;
  final List<String> bannerUrls;
  final String? supportPhone;
  final String? supportEmail;
  final String? address;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final CommunityFeatureFlags features;
  final bool ownerIdentityVerificationRequired;

  const CommunityModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.websitePath,
    this.databaseId = defaultDatabaseId,
    this.logoUrl,
    required this.brandName,
    this.primaryColor,
    this.secondaryColor,
    this.bannerUrls = const [],
    this.supportPhone,
    this.supportEmail,
    this.address,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.features = const CommunityFeatureFlags(),
    this.ownerIdentityVerificationRequired = false,
  });

  factory CommunityModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (!document.exists || data == null) {
      throw StateError('Community ${document.id} does not exist.');
    }

    return CommunityModel.fromMap(document.id, data);
  }

  factory CommunityModel.fromMap(String id, Map<String, dynamic> data) {
    final name = _string(data['name']);
    final storedSlug = _string(data['slug']);
    final slug = storedSlug.isEmpty ? slugify(name) : storedSlug;
    final websitePath = _string(data['websitePath']);
    final databaseId = _string(data['databaseId']);
    final brandName = _string(data['brandName']);

    return CommunityModel(
      id: id,
      name: name,
      slug: slug,
      websitePath: websitePath.isEmpty ? slug : websitePath,
      databaseId: databaseId.isEmpty ? defaultDatabaseId : databaseId,
      logoUrl: _nullableString(data['logoUrl']),
      brandName: brandName.isEmpty ? name : brandName,
      primaryColor: _nullableString(data['primaryColor']),
      secondaryColor: data['secondaryColor'] as String?,
      bannerUrls: List<String>.from(data['bannerUrls'] as List? ?? const []),
      supportPhone: data['supportPhone'] as String?,
      supportEmail: data['supportEmail'] as String?,
      address: data['address'] as String?,
      isActive: data['isActive'] == true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      features: CommunityFeatureFlags.fromMap(
        data['features'] as Map<String, dynamic>?,
      ),
      ownerIdentityVerificationRequired:
          data['ownerIdentityVerificationRequired'] == true,
    );
  }

  static String slugify(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  static String _string(Object? value) => value is String ? value.trim() : '';

  static String? _nullableString(Object? value) {
    final parsed = _string(value);
    return parsed.isEmpty ? null : parsed;
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'slug': slug,
    'websitePath': websitePath,
    'databaseId': databaseId,
    'logoUrl': logoUrl,
    'brandName': brandName,
    'primaryColor': primaryColor,
    'secondaryColor': secondaryColor,
    'bannerUrls': bannerUrls,
    'supportPhone': supportPhone,
    'supportEmail': supportEmail,
    'address': address,
    'isActive': isActive,
    'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    'features': features.toMap(),
    'ownerIdentityVerificationRequired': ownerIdentityVerificationRequired,
  };
}
