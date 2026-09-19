import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'src/screens/animated_splash_screen.dart';

/// Standalone demo for testing the splash screen
/// Run with: flutter run lib/splash_demo.dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  
  runApp(const SplashDemo());
}

class SplashDemo extends StatelessWidget {
  const SplashDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Splash Screen Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F80ED)),
      ),
      home: const SplashDemoHome(),
    );
  }
}

class SplashDemoHome extends StatefulWidget {
  const SplashDemoHome({super.key});

  @override
  State<SplashDemoHome> createState() => _SplashDemoHomeState();
}

class _SplashDemoHomeState extends State<SplashDemoHome> {
  bool _showSplash = true;
  bool _reduceMotion = false;
  bool _simulateSlowDevice = false;

  void _resetSplash() {
    setState(() {
      _showSplash = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return AnimatedSplashScreen(
        onAnimationComplete: () {
          setState(() {
            _showSplash = false;
          });
        },
        reduceMotion: _reduceMotion,
        simulateSlowDevice: _simulateSlowDevice,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Splash Screen Demo'),
        backgroundColor: const Color(0xFF2F80ED),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success message
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Splash Animation Complete!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The splash screen animation has finished successfully.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Test options
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Options',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      SwitchListTile(
                        title: const Text('Reduce Motion'),
                        subtitle: const Text('Test accessibility mode'),
                        value: _reduceMotion,
                        onChanged: (value) {
                          setState(() {
                            _reduceMotion = value;
                          });
                        },
                      ),
                      
                      SwitchListTile(
                        title: const Text('Simulate Slow Device'),
                        subtitle: const Text('Test performance mode'),
                        value: _simulateSlowDevice,
                        onChanged: (value) {
                          setState(() {
                            _simulateSlowDevice = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Replay button
              ElevatedButton.icon(
                onPressed: _resetSplash,
                icon: const Icon(Icons.replay),
                label: const Text('Replay Splash Animation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F80ED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Info cards
              _buildInfoCard(
                'Duration',
                '2.2 seconds',
                Icons.timer,
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                'Target Device',
                'iPhone 13 (390px)',
                Icons.phone_iphone,
                Colors.purple,
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                'Performance',
                '60 FPS optimized',
                Icons.speed,
                Colors.green,
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                'Accessibility',
                'Reduced motion support',
                Icons.accessibility_new,
                Colors.orange,
              ),

              const SizedBox(height: 32),

              // Documentation link
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Documentation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'See SPLASH_SCREEN_IMPLEMENTATION.md for full documentation, customization options, and asset setup instructions.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
