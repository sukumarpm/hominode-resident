/// App-wide standardized sizing constants - COMPACT VERSION
/// Reduced sizes for more compact, professional UI across all screens
library;

class AppSizes {
  // Page/Screen Padding - REDUCED
  static const double pagePadding = 16.0; // Standard page padding
  static const double pagePaddingTight = 12.0; // Dense content
  static const double pagePaddingLoose = 18.0; // Special cases (reduced from 20)
  
  // Component Spacing - REDUCED
  static const double spaceBetweenCards = 8.0; // Reduced from 10
  static const double spaceBetweenSections = 14.0; // Reduced from 16
  static const double spaceSmall = 6.0; // Reduced from 8
  static const double spaceTiny = 4.0;
  static const double spaceMedium = 10.0; // Reduced from 12
  
  // Card/Container Padding - REDUCED
  static const double cardPadding = 10.0; // Reduced from 12
  static const double cardPaddingLarge = 14.0; // Reduced from 16
  static const double cardPaddingSmall = 8.0; // Reduced from 10
  
  // Icon Sizes - REDUCED
  static const double iconContainerLarge = 52.0; // Reduced from 56
  static const double iconContainerMedium = 44.0; // Reduced from 48
  static const double iconContainerSmall = 36.0; // Reduced from 40
  static const double iconSizeLarge = 26.0; // Reduced from 28
  static const double iconSizeMedium = 22.0; // Reduced from 24
  static const double iconSizeSmall = 18.0; // Reduced from 20
  
  // Button Heights - REDUCED
  static const double buttonHeightPrimary = 48.0; // Keep for accessibility
  static const double buttonHeightSecondary = 42.0; // Reduced from 44
  static const double buttonHeightSmall = 38.0; // Reduced from 40
  
  // Border Radius - SLIGHTLY REDUCED
  static const double radiusCard = 12.0; // Reduced from 14
  static const double radiusCardLarge = 14.0; // Reduced from 16
  static const double radiusCardSmall = 10.0; // Reduced from 12
  static const double radiusButton = 10.0; // Reduced from 12
  static const double radiusModal = 18.0; // Reduced from 20
  
  // Modal/Dialog - REDUCED
  static const double modalPadding = 18.0; // Reduced from 20
  static const double modalInset = 18.0; // Reduced from 20
  
  // Header - INCREASED for better prominence
  static const double headerPaddingVertical = 14.0; // Increased for more height
  static const double headerPaddingBottom = 20.0; // Increased for more height
  
  // Auth Screens Specific
  static const double authLogoSize = 100.0; // Compact logo
  static const double authFieldSpacing = 14.0; // Between form fields
  static const double authSectionSpacing = 20.0; // Between sections
}

class AppTextSizes {
  // Headers - INCREASED for better visibility
  static const double screenTitle = 20.0; // Increased for prominence
  static const double sectionTitle = 15.0; // Reduced from 16
  static const double cardTitle = 15.0; // Reduced from 16
  static const double subtitle = 13.0; // Reduced from 14
  
  // Body - REDUCED
  static const double bodyPrimary = 14.0; // Keep readable
  static const double bodySecondary = 13.0;
  static const double bodySmall = 12.0;
  static const double bodyTiny = 11.0;
  
  // Buttons - SLIGHTLY REDUCED
  static const double buttonPrimary = 16.0; // Keep for accessibility
  static const double buttonSecondary = 15.0;
  static const double buttonSmall = 14.0;
  
  // Auth Screens Specific
  static const double authHeading = 20.0; // Main headings
  static const double authLabel = 14.0; // Form labels
  static const double authInput = 14.0; // Input text
}
