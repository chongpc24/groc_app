import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/supabase_service.dart';

class MyDetailsScreen extends StatefulWidget {
  const MyDetailsScreen({super.key});

  @override
  State<MyDetailsScreen> createState() =>
      _MyDetailsScreenState();
}

class _MyDetailsScreenState
    extends State<MyDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _icController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController =
  TextEditingController();

  final _genderOptions = const [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  String _gender = 'Prefer not to say';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _icController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = AuthService.instance.currentUser;

    if (user == null) {
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    Map<String, dynamic>? profile;

    try {
      profile =
      await SupabaseService.instance.fetchMyProfile();
      await DatabaseService()
          .upsertProfileCache(profile);
    } catch (_) {
      profile = await DatabaseService()
          .getProfileCache(user.id);
    }

    if (!mounted) {
      return;
    }

    profile ??= {
      'email': user.email ?? '',
      'full_name': '',
      'ic_number': '',
      'phone_number': '',
      'gender': 'Prefer not to say',
      'address': '',
    };

    _nameController.text =
        profile['full_name']?.toString() ?? '';
    _emailController.text =
        profile['email']?.toString() ??
            user.email ??
            '';
    _icController.text =
        profile['ic_number']?.toString() ?? '';
    _phoneController.text =
        profile['phone_number']?.toString() ?? '';
    _addressController.text =
        profile['address']?.toString() ?? '';
    _gender =
        profile['gender']?.toString() ??
            'Prefer not to say';

    setState(() {
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final profile =
      await SupabaseService.instance.updateMyProfile(
        fullName: _nameController.text,
        phoneNumber: AuthService.normalizePhone(
          _phoneController.text,
        ),
        gender: _gender,
        address: _addressController.text,
      );

      await DatabaseService()
          .upsertProfileCache(profile);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated.'),
        ),
      );

      Navigator.pop(context, true);
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update profile: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Details'),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration:
                const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon:
                  Icon(Icons.person_outline),
                ),
                validator:
                AuthService.validateFullName,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                readOnly: true,
                decoration:
                const InputDecoration(
                  labelText: 'Email',
                  prefixIcon:
                  Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _icController,
                readOnly: true,
                decoration:
                const InputDecoration(
                  labelText: 'IC number',
                  prefixIcon:
                  Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType:
                TextInputType.phone,
                decoration:
                const InputDecoration(
                  labelText: 'Phone number',
                  prefixIcon:
                  Icon(Icons.phone_outlined),
                ),
                validator:
                AuthService.validatePhone,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration:
                const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon:
                  Icon(Icons.people_outline),
                ),
                items: _genderOptions
                    .map(
                      (option) =>
                      DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      ),
                )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (value) {
                  setState(() {
                    _gender =
                        value ?? _gender;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller:
                _addressController,
                minLines: 2,
                maxLines: 4,
                decoration:
                const InputDecoration(
                  labelText: 'Address',
                  prefixIcon:
                  Icon(Icons.home_outlined),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if ((value ?? '')
                      .trim()
                      .isEmpty) {
                    return 'Address is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed:
                  _saving ? null : _save,
                  style:
                  FilledButton.styleFrom(
                    backgroundColor:
                    Colors.green.shade700,
                    padding:
                    const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Save Changes',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
