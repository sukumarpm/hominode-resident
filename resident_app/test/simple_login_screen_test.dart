import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resident_app/src/screens/simple_login_screen.dart';
import 'package:resident_app/src/services/firebase_auth_service.dart';

class _FakePhoneAuthGateway implements ResidentPhoneAuthGateway {
  int sendCount = 0;

  @override
  String formatPhoneNumber(String phone) => phone;

  @override
  bool validatePhoneNumber(String phone) => true;

  @override
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(AuthResult result) onError,
    bool forceResend = false,
  }) async {
    sendCount++;
    onCodeSent('verification-id');
  }
}

Widget _app(_FakePhoneAuthGateway gateway) => ScreenUtilInit(
  designSize: const Size(390, 844),
  builder: (_, __) => MaterialApp(
    home: SimpleLoginScreen(
      authGateway: gateway,
      otpScreenBuilder: (_, __) => const Scaffold(body: Text('OTP started')),
    ),
  ),
);

void main() {
  testWidgets('Register link is not shown in active resident login', (
    tester,
  ) async {
    final gateway = _FakePhoneAuthGateway();
    await tester.pumpWidget(_app(gateway));

    expect(find.byKey(const Key('resident-register-link')), findsNothing);
    expect(find.text('New resident? Register'), findsNothing);
  });

  testWidgets('Send OTP starts resident OTP screen', (tester) async {
    final gateway = _FakePhoneAuthGateway();
    await tester.pumpWidget(_app(gateway));

    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();

    expect(gateway.sendCount, 1);
    expect(find.text('OTP started'), findsOneWidget);
  });
}
