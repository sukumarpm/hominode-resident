// USAGE NOTE:
// 1. Add to pubspec.yaml under flutter section:
//    assets:
//      - assets/logo1.png
// 2. Run: flutter pub get
// 3. Ensure logo1.png exists at: resident_app/assets/logo1.png
// 4. For debug with absolute path, see commented alternative below

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hominode',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const ModernSplashScreen(),
    );
  }
}

class ModernSplashScreen extends StatefulWidget {
  const ModernSplashScreen({super.key});

  @override
  State<ModernSplashScreen> createState() => _ModernSplashScreenState();
}

class _ModernSplashScreenState extends State<ModernSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );

    // Scale animation with easeOutBack curve (overshoot effect)
    _scaleAnimation = Tween<double>(begin: 0.60, end: 1.00).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.68, curve: Curves.easeOutBack),
      ),
    );

    // Fade animation for logo and card
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.68, curve: Curves.easeOut),
      ),
    );

    // Progress bar animation
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Start animation
    _controller.forward();

    // Navigate to home screen after animation completes
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomeScreen(),
            transitionDuration: const Duration(milliseconds: 500),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0E4778), // Primary blue
              Color(0xFF061C4C), // Secondary blue
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main content
              Padding(
                padding: const EdgeInsets.only(top: 36.0, bottom: 48.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // Animated logo card
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Opacity(
                            opacity: _fadeAnimation.value,
                            child: Container(
                              width: 196.0, // 160 + (18*2) padding
                              height: 196.0,
                              padding: const EdgeInsets.all(18.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(32.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 10.0,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: _buildLogoImage(),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 28.0),

                    // App title
                    const Text(
                      'Hominode',
                      style: TextStyle(
                        fontSize: 28.0,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 8.0),

                    // Subtitle
                    Text(
                      'Your Community, Connected',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.70),
                        letterSpacing: 0.2,
                      ),
                    ),

                    const Spacer(),
                  ],
                ),
              ),

              // Bottom progress indicator
              Positioned(
                left: 0,
                right: 0,
                bottom: 24.0,
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return Center(
                      child: Container(
                        width: 200.0,
                        height: 3.0,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2.0),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progressAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2.0),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoImage() {
    // Default: Use asset from pubspec.yaml
    // Make sure to add 'assets/logo1.png' to pubspec.yaml under flutter > assets
    return Image.asset(
      'assets/logo1.png',
      width: 160.0,
      height: 160.0,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback: Show placeholder if asset is missing
        return Container(
          width: 160.0,
          height: 160.0,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Icon(
            Icons.image_outlined,
            size: 64.0,
            color: Colors.grey[400],
          ),
        );
      },
    );

    // ALTERNATIVE: For debug/testing with absolute path (uncomment to use)
    // Note: This only works on the specific device with this exact path
    // return Image.file(
    //   File('D:/Resident_App/resident_app/assets/logo1.png'),
    //   width: 160.0,
    //   height: 160.0,
    //   fit: BoxFit.contain,
    //   errorBuilder: (context, error, stackTrace) {
    //     return Container(
    //       width: 160.0,
    //       height: 160.0,
    //       decoration: BoxDecoration(
    //         color: Colors.grey[200],
    //         borderRadius: BorderRadius.circular(16.0),
    //       ),
    //       child: Icon(
    //         Icons.image_outlined,
    //         size: 64.0,
    //         color: Colors.grey[400],
    //       ),
    //     );
    //   },
    // );
  }
}

// Simple placeholder home screen for navigation demo
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: const Color(0xFF0E4778),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home, size: 80.0, color: Color(0xFF0E4778)),
            const SizedBox(height: 24.0),
            const Text(
              'Welcome to Hominode!',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12.0),
            Text(
              'Your Community, Connected',
              style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
