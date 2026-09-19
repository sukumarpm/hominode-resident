import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:resident_app/src/screens/emergency_sos_screen.dart';

import '../../packages/hominode_sos/test/sos_test_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter.baseflow.com/geolocator');
  final calls = <MethodCall>[];
  var permission = LocationPermission.whileInUse;
  var servicesEnabled = true;
  String? failingMethod;
  String? hangingMethod;
  var nullPosition = false;
  late Completer<Object?> pending;
  final position = <String, dynamic>{
    'latitude': 14.5,
    'longitude': 121.0,
    'accuracy': 1000.0,
    'timestamp': 1700000000000,
  };

  setUp(() {
    calls.clear();
    permission = LocationPermission.whileInUse;
    servicesEnabled = true;
    failingMethod = null;
    hangingMethod = null;
    nullPosition = false;
    pending = Completer<Object?>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == failingMethod) {
            throw PlatformException(code: 'LOCATION_UNAVAILABLE');
          }
          if (call.method == hangingMethod) return pending.future;
          return switch (call.method) {
            'checkPermission' => permission.index,
            'isLocationServiceEnabled' => servicesEnabled,
            'getCurrentPosition' => nullPosition ? null : position,
            _ => throw StateError('Unexpected location call: ${call.method}'),
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<TestSosClient> activate(WidgetTester tester) async {
    final client = TestSosClient();
    addTearDown(client.dispose);
    // Exercise the actual default Resident location capture, without injection.
    await tester.pumpWidget(
      MaterialApp(home: EmergencySosScreen(client: client)),
    );
    await tester.pumpAndSettle();
    for (var tap = 0; tap < 3; tap++) {
      expect(client.triggers, 0);
      expect(calls, isEmpty);
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    return client;
  }

  void expectOnlyCalls(List<String> expected) {
    // This allowlist also catches permission, precise-accuracy and settings
    // requests even if captureSosLocation catches their exceptions.
    expect(calls.map((call) => call.method).toList(), expected);
  }

  for (final denied in [
    LocationPermission.denied,
    LocationPermission.deniedForever,
    LocationPermission.unableToDetermine,
  ]) {
    testWidgets('$denied sends without location or permission prompts', (
      tester,
    ) async {
      permission = denied;
      final client = await activate(tester);
      expect(client.triggers, 1);
      expect(client.lastLocation, isNull);
      expect(find.text('CANCEL SOS'), findsOneWidget);
      expectOnlyCalls(['checkPermission']);
    });
  }

  for (final granted in [
    LocationPermission.whileInUse,
    LocationPermission.always,
  ]) {
    testWidgets('$granted sends one snapshot without accuracy prompts', (
      tester,
    ) async {
      permission = granted;
      final client = await activate(tester);
      expect(client.triggers, 1);
      expect(client.lastLocation, {
        'latitude': 14.5,
        'longitude': 121.0,
        'accuracy': 1000.0,
        'capturedAt': 1700000000000,
      });
      expectOnlyCalls([
        'checkPermission',
        'isLocationServiceEnabled',
        'getCurrentPosition',
      ]);
      final settings = calls.last.arguments as Map;
      expect(settings['forceLocationManager'], isTrue);
      expect(settings['accuracy'], LocationAccuracy.medium.index);
      await tester.pump(const Duration(seconds: 5));
      expect(calls.length, 3);
      expect(client.triggers, 1);
    });
  }

  testWidgets('disabled services send immediately without location', (
    tester,
  ) async {
    servicesEnabled = false;
    final client = await activate(tester);
    expect(client.triggers, 1);
    expect(client.lastLocation, isNull);
    expectOnlyCalls(['checkPermission', 'isLocationServiceEnabled']);
  });

  for (final method in [
    'checkPermission',
    'isLocationServiceEnabled',
    'getCurrentPosition',
  ]) {
    testWidgets('$method failure still sends SOS', (tester) async {
      failingMethod = method;
      final client = await activate(tester);
      expect(client.triggers, 1);
      expect(client.lastLocation, isNull);
      expect(calls.last.method, method);
    });

    testWidgets(
      '$method timeout sends within two seconds without late capture',
      (tester) async {
        hangingMethod = method;
        final client = await activate(tester);
        expect(client.triggers, 0);
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(client.triggers, 1);
        expect(client.lastLocation, isNull);
        expect(find.text('CANCEL SOS'), findsOneWidget);
        final callCount = calls.length;
        pending.complete(switch (method) {
          'checkPermission' => LocationPermission.whileInUse.index,
          'isLocationServiceEnabled' => true,
          _ => position,
        });
        await tester.pumpAndSettle();
        expect(calls.length, callCount);
        expect(client.triggers, 1);
        expect(client.lastLocation, isNull);
      },
    );
  }

  testWidgets('null platform position still sends without location', (
    tester,
  ) async {
    nullPosition = true;
    final client = await activate(tester);
    expect(client.triggers, 1);
    expect(client.lastLocation, isNull);
  });
}
