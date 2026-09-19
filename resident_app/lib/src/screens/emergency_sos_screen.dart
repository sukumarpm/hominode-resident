import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hominode_sos/hominode_sos.dart';

class EmergencySosScreen extends StatelessWidget {
  const EmergencySosScreen({super.key, this.client, this.captureLocation});
  final SosClient? client;
  final SosLocationCapture? captureLocation;

  @override
  Widget build(BuildContext context) => ResidentSosPage(
    client: client,
    captureLocation: captureLocation ?? captureSosLocation,
  );
}

// Check-only hook for future normal-day location onboarding. Any permission
// request belongs in that flow, never in SOS or a new startup dialog.
Future<bool> hasResidentLocationPermission() async {
  final permission = await Geolocator.checkPermission();
  return permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always;
}

// One snapshot using existing permission, with a two-second total budget.
Future<Map<String, dynamic>?> captureSosLocation() async {
  const budget = Duration(seconds: 2);
  final elapsed = Stopwatch()..start();
  try {
    if (!await hasResidentLocationPermission().timeout(budget)) return null;
    var remaining = budget - elapsed.elapsed;
    if (remaining <= Duration.zero) return null;
    if (!await Geolocator.isLocationServiceEnabled().timeout(remaining)) {
      return null;
    }
    remaining = budget - elapsed.elapsed;
    if (remaining <= Duration.zero) return null;
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      // Avoid the Android fused provider's location-settings resolution dialog.
      forceAndroidLocationManager: true,
      timeLimit: remaining,
    ).timeout(remaining);
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'capturedAt': position.timestamp.millisecondsSinceEpoch,
    };
  } catch (_) {
    return null;
  } finally {
    elapsed.stop();
  }
}
