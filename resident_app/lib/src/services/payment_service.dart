enum PaymentMethod { upi, card, netBanking }

abstract final class ResidentPaymentV1Policy {
  /// Resident-initiated payments stay disabled until a trusted payment gateway
  /// and server-side settlement flow are available.
  static const bool enabled = false;
}
