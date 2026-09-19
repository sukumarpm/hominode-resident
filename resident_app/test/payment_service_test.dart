import 'package:flutter_test/flutter_test.dart';
import 'package:resident_app/src/services/payment_service.dart';

void main() {
  test('resident-initiated payments are disabled for production V1', () {
    expect(ResidentPaymentV1Policy.enabled, isFalse);
  });
}
