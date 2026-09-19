import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../models/resident_registration_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/resident_auth_routing.dart';
import '../services/resident_registration_service.dart';
import '../services/tenant_resolution_service.dart';

class ResidentRegistrationScreen extends StatefulWidget {
  const ResidentRegistrationScreen({super.key});

  @override
  State<ResidentRegistrationScreen> createState() =>
      _ResidentRegistrationScreenState();
}

class _ResidentRegistrationScreenState
    extends State<ResidentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _building = TextEditingController();
  final _unit = TextEditingController();
  final _email = TextEditingController();
  final _service = ResidentRegistrationService();
  CommunityInvite? _invite;
  bool _resolving = false;
  bool _submitting = false;
  bool _checkingImportedOnboarding = true;
  String? _error;
  String _residentType = 'owner';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _claimImportedOnboarding();
    });
  }

  Future<void> _claimImportedOnboarding() async {
    try {
      final claimed = await _service.claimImportedOnboarding();
      if (!mounted) return;
      if (!claimed) {
        setState(() => _checkingImportedOnboarding = false);
        return;
      }
      final result = await FirebaseAuthService().restoreResidentSession(
        context.read<TenantResolutionService>(),
      );
      if (mounted) {
        ResidentAuthRouting.navigateToResult(context, result);
      }
    } on ResidentRegistrationException catch (error) {
      if (mounted) {
        setState(() {
          _checkingImportedOnboarding = false;
          _error = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _checkingImportedOnboarding = false;
          _error = 'Imported registration could not be checked.';
        });
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _building.dispose();
    _unit.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _resolveCode() async {
    setState(() {
      _resolving = true;
      _error = null;
      _invite = null;
    });
    try {
      final invite = await _service.resolveInvite(_code.text);
      if (!mounted) return;
      setState(() => _invite = invite);
    } on ResidentRegistrationException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to verify community code.');
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final invite = _invite;
    final user = FirebaseAuth.instance.currentUser;
    if (invite == null) {
      setState(() => _error = 'Verify your community code first.');
      return;
    }
    if (user == null || user.phoneNumber == null) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _service.register(
        ResidentRegistrationModel(
          uid: user.uid,
          phoneNumber: user.phoneNumber!,
          name: _name.text.trim(),
          communityId: invite.communityId,
          communityInviteCode: invite.code,
          buildingReference: _building.text.trim(),
          unitReference: _unit.text.trim(),
          email: _email.text.trim().isEmpty ? null : _email.text.trim(),
          residentType: _residentType,
        ),
      );
      if (mounted) {
        final result = await FirebaseAuthService().restoreResidentSession(
          context.read<TenantResolutionService>(),
        );
        if (mounted) {
          ResidentAuthRouting.navigateToResult(context, result);
        }
      }
    } on ResidentRegistrationException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Registration could not be submitted.');
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    if (_checkingImportedOnboarding) {
      return const Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Checking imported resident registration…'),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Resident Registration')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(20.w),
            children: [
              Text(
                'Complete your resident details',
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 24.h),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: _required,
              ),
              SizedBox(height: 16.h),
              TextFormField(
                initialValue: phone,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Verified Phone Number',
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _code,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Community Invite Code',
                      ),
                      onChanged: (_) => setState(() => _invite = null),
                      validator: _required,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  FilledButton(
                    onPressed: _resolving ? null : _resolveCode,
                    child: Text(_resolving ? 'Checking…' : 'Verify'),
                  ),
                ],
              ),
              if (_invite != null) ...[
                SizedBox(height: 16.h),
                Card(
                  child: ListTile(
                    leading: _invite!.logoUrl == null
                        ? const CircleAvatar(child: Icon(Icons.apartment))
                        : CircleAvatar(
                            backgroundImage: NetworkImage(_invite!.logoUrl!),
                          ),
                    title: Text(_invite!.communityName),
                    subtitle: const Text('Community verified'),
                    trailing: const Icon(Icons.verified, color: Colors.green),
                  ),
                ),
              ],
              SizedBox(height: 16.h),
              TextFormField(
                controller: _building,
                decoration: const InputDecoration(
                  labelText: 'Building / Tower',
                ),
                validator: _required,
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _unit,
                decoration: const InputDecoration(labelText: 'Flat / Unit'),
                validator: _required,
              ),
              SizedBox(height: 16.h),
              DropdownButtonFormField<String>(
                initialValue: _residentType,
                decoration: const InputDecoration(labelText: 'Resident Type'),
                items: const [
                  DropdownMenuItem(value: 'owner', child: Text('Owner')),
                  DropdownMenuItem(value: 'tenant', child: Text('Tenant')),
                ],
                onChanged: _submitting
                    ? null
                    : (value) => setState(
                        () => _residentType = value ?? _residentType,
                      ),
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email (Optional)',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  return RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(value.trim())
                      ? null
                      : 'Enter a valid email';
                },
              ),
              if (_error != null) ...[
                SizedBox(height: 16.h),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              SizedBox(height: 24.h),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: Text(
                  _submitting ? 'Submitting…' : 'Submit for Approval',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
