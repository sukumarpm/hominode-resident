// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:provider/provider.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'main_navigation.dart';
// import 'src/providers/theme_provider.dart';
// import 'src/providers/language_provider.dart';
// import 'src/providers/localization_provider.dart';
// import 'src/screens/splash_screen_clean.dart';
// import 'src/screens/simple_login_screen.dart';
// import 'src/services/firebase_auth_service.dart';
// import 'src/services/tenant_resolution_service.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Initialize Firebase
//   await Firebase.initializeApp();

//   // Initialize EasyLocalization
//   await EasyLocalization.ensureInitialized();

//   // Set system UI to light mode
//   SystemChrome.setSystemUIOverlayStyle(
//     const SystemUiOverlayStyle(
//       statusBarColor: Colors.transparent,
//       statusBarIconBrightness: Brightness.dark,
//       statusBarBrightness: Brightness.light,
//     ),
//   );

//   runApp(
//     EasyLocalization(
//       supportedLocales: const [
//         Locale('en'),
//         Locale('ta'),
//         Locale('hi'),
//         Locale('es'),
//         Locale('ar'),
//       ],
//       path: 'assets/translations',
//       fallbackLocale: const Locale('en'),
//       startLocale: const Locale('en'),
//       child: MultiProvider(
//         providers: [
//           ChangeNotifierProvider(create: (_) => LanguageProvider()),
//           ChangeNotifierProvider(create: (_) => LocalizationProvider()),
//           ChangeNotifierProvider(create: (_) => TenantResolutionService()),
//         ],
//         child: const MyApp(),
//       ),
//     ),
//   );
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'app_title'.tr(),
//       debugShowCheckedModeBanner: false,

//       // Localization configuration
//       localizationsDelegates: [
//         GlobalMaterialLocalizations.delegate,
//         GlobalWidgetsLocalizations.delegate,
//         GlobalCupertinoLocalizations.delegate,
//         EasyLocalization.of(context)!.delegate,
//       ],
//       supportedLocales: EasyLocalization.of(context)!.supportedLocales,
//       locale: context.locale,

//       // Apply light theme only
//       theme: AppTheme.lightTheme,
//       themeMode: ThemeMode.light,

//       home: const AuthCheckScreen(),
//       onGenerateRoute: (settings) {
//         switch (settings.name) {
//           case '/splash':
//             return MaterialPageRoute(
//               builder: (context) => CleanSplashScreen(
//                 logoAssetPath: 'lib/assets/Resident_New.png',
//                 appName: 'Lyvo',
//                 tagline: 'Your Community, Connected',
//                 duration: const Duration(milliseconds: 3000),
//                 onFinish: () async {
//                   final result = await FirebaseAuthService()
//                       .restoreResidentSession(
//                         context.read<TenantResolutionService>(),
//                       );
//                   if (context.mounted) {
//                     if (result.success) {
//                       Navigator.of(context).pushReplacementNamed('/home');
//                     } else {
//                       Navigator.of(context).pushReplacementNamed('/login');
//                     }
//                   }
//                 },
//               ),
//             );
//           case '/login':
//             return MaterialPageRoute(
//               builder: (context) => const SimpleLoginScreen(),
//             );
//           case '/home':
//             return MaterialPageRoute(
//               builder: (context) => const MainNavigation(),
//             );
//           default:
//             return MaterialPageRoute(
//               builder: (context) => const MainNavigation(),
//             );
//         }
//       },
//     );
//   }
// }

// // Auth Check Screen - Determines initial route based on login state
// class AuthCheckScreen extends StatefulWidget {
//   const AuthCheckScreen({super.key});

//   @override
//   State<AuthCheckScreen> createState() => _AuthCheckScreenState();
// }

// class _AuthCheckScreenState extends State<AuthCheckScreen> {
//   @override
//   void initState() {
//     super.initState();
//     _checkAuthStatus();
//   }

//   Future<void> _checkAuthStatus() async {
//     await Future.delayed(const Duration(milliseconds: 500));

//     if (mounted) {
//       final result = await FirebaseAuthService().restoreResidentSession(
//         context.read<TenantResolutionService>(),
//       );

//       if (mounted) {
//         if (result.success) {
//           Navigator.of(context).pushReplacementNamed('/home');
//         } else {
//           Navigator.of(context).pushReplacementNamed('/login');
//         }
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Image.asset('assets/logo1.png', width: 100, height: 100),
//             const SizedBox(height: 24),
//             const CircularProgressIndicator(
//               valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hominode_legal/hominode_legal.dart';
import 'package:hominode_notifications/hominode_notifications.dart';
import 'package:provider/provider.dart';

import 'main_navigation.dart';
import 'src/providers/language_provider.dart';
import 'src/providers/localization_provider.dart';
import 'src/providers/theme_provider.dart';
import 'src/screens/access_blocked_screen.dart';
import 'src/screens/awaiting_approval_screen.dart';
import 'src/screens/resident_identity_verification_screen.dart';
import 'src/screens/resident_registration_screen.dart';
import 'src/screens/simple_login_screen.dart';
import 'src/screens/splash_screen_clean.dart';
import 'src/services/firebase_auth_service.dart';
import 'src/services/resident_auth_routing.dart';
import 'src/services/resident_notification_router.dart';
import 'src/services/tenant_resolution_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ------------------------------------------------------------
  // Firebase
  // ------------------------------------------------------------
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
  );
  unawaited(
    HominodePushNotifications.instance
        .initialize(onAuthorizedTap: ResidentNotificationRouter.handle)
        .timeout(const Duration(seconds: 8))
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Notification initialization failed: $error');
          debugPrintStack(stackTrace: stackTrace);
        }),
  );

  // ------------------------------------------------------------
  // Localization
  // ------------------------------------------------------------
  await EasyLocalization.ensureInitialized();

  // ------------------------------------------------------------
  // System UI
  // ------------------------------------------------------------
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // ------------------------------------------------------------
  // App
  // ------------------------------------------------------------
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('ta'),
        Locale('hi'),
        Locale('es'),
        Locale('ar'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => LocalizationProvider()),
          ChangeNotifierProvider(create: (_) => TenantResolutionService()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // Base design size used by .w, .h, .r and .sp.
      //
      // ScreenUtil will automatically adapt this to different
      // Android/iPhone screen sizes.
      designSize: const Size(390, 844),

      minTextAdapt: true,
      splitScreenMode: true,

      builder: (context, child) {
        return MaterialApp(
          navigatorKey: residentNotificationNavigatorKey,
          title: 'app_title'.tr(),
          debugShowCheckedModeBanner: false,

          // ------------------------------------------------------
          // Localization
          // ------------------------------------------------------
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            EasyLocalization.of(context)!.delegate,
          ],
          supportedLocales: EasyLocalization.of(context)!.supportedLocales,
          locale: context.locale,

          // ------------------------------------------------------
          // Theme
          // ------------------------------------------------------
          theme: AppTheme.lightTheme,
          themeMode: ThemeMode.light,

          // ------------------------------------------------------
          // Initial screen
          // ------------------------------------------------------
          home: child,

          // ------------------------------------------------------
          // Routes
          // ------------------------------------------------------
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/splash':
                return MaterialPageRoute(
                  builder: (context) => CleanSplashScreen(
                    logoAssetPath: 'lib/assets/Resident_New.png',
                    appName: 'Hominode',
                    tagline: 'Your Community, Connected',
                    duration: const Duration(milliseconds: 3000),
                    onFinish: () async {
                      final result = await FirebaseAuthService()
                          .restoreResidentSession(
                            context.read<TenantResolutionService>(),
                          );

                      if (!context.mounted) {
                        return;
                      }

                      Navigator.of(context).pushReplacementNamed(
                        ResidentAuthRouting.routeFor(result),
                        arguments: result.message,
                      );
                    },
                  ),
                );

              case '/login':
                return MaterialPageRoute(
                  builder: (context) => const SimpleLoginScreen(),
                );

              case '/home':
                return PageRouteBuilder(
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const HominodeLegalAcceptanceGate(
                        profileCollection: 'users',
                        loadingWidget: _ResidentLegalLoadingScreen(),
                        child: MainNavigation(),
                      ),
                );

              case '/resident-registration':
                return MaterialPageRoute(
                  builder: (context) => const ResidentRegistrationScreen(),
                );

              case '/awaiting-approval':
                return MaterialPageRoute(
                  builder: (context) => const AwaitingApprovalScreen(),
                );

              case '/resident-access-blocked':
                return MaterialPageRoute(
                  builder: (context) => AccessBlockedScreen(
                    message:
                        settings.arguments as String? ??
                        'Resident access is unavailable. Contact your community administrator.',
                  ),
                );

              case '/resident-identity-verification':
                return MaterialPageRoute(
                  builder: (context) =>
                      const ResidentIdentityVerificationScreen(),
                );

              default:
                return MaterialPageRoute(
                  builder: (context) => const SimpleLoginScreen(),
                );
            }
          },
        );
      },

      child: const AuthCheckScreen(),
    );
  }
}

// ============================================================================
// AUTH CHECK SCREEN
// Determines whether an existing resident session can be restored.
// ============================================================================

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    debugPrint(
      '🔐 STARTUP AUTH UID: ${FirebaseAuth.instance.currentUser?.uid}',
    );
    debugPrint(
      '🔐 STARTUP AUTH PHONE: ${FirebaseAuth.instance.currentUser?.phoneNumber}',
    );

    final result = await FirebaseAuthService().restoreResidentSession(
      context.read<TenantResolutionService>(),
    );

    debugPrint(
      '🔐 RESTORE RESULT: '
      'success=${result.success}, '
      'state=${result.state}, '
      'message=${result.message}',
    );

    if (!mounted) return;

    final route = ResidentAuthRouting.routeFor(result);
    debugPrint('🔐 RESTORE ROUTE: $route');

    Navigator.of(
      context,
    ).pushReplacementNamed(route, arguments: result.message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06182B),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'lib/assets/images/resident_login_background.png',
            fit: BoxFit.cover,
          ),

          Container(color: const Color(0xFF06182B).withValues(alpha: 0.18)),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'lib/assets/Resident_New.png',
                  width: 130,
                  height: 130,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF31D6E5),
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

class _ResidentLegalLoadingScreen extends StatelessWidget {
  const _ResidentLegalLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06182B),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'lib/assets/images/resident_login_background.png',
            fit: BoxFit.cover,
          ),

          Container(color: const Color(0xFF06182B).withValues(alpha: 0.18)),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'lib/assets/Resident_New.png',
                  width: 130,
                  height: 130,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF31D6E5),
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
