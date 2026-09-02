import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _icController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController =
  TextEditingController();
  final _passwordController =
  TextEditingController();
  final _confirmPasswordController =
  TextEditingController();

  final _genderOptions = const [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  String _gender = 'Prefer not to say';
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _icController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please confirm that the registration details are accurate.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final response =
      await AuthService.instance.register(
        fullName: _nameController.text,
        email: _emailController.text,
        icNumber: _icController.text,
        phoneNumber: _phoneController.text,
        gender: _gender,
        address: _addressController.text,
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      if (response.session == null) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text(
              'Registration submitted',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'An account was created for ${_emailController.text.trim()}. Please verify the email, then return to Login.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );

        if (!mounted) {
          return;
        }

        Navigator.pop(context, false);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registration successful.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } on AuthException catch (error) {
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
            'Registration failed: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            28,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 520,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Register for GROC',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Your account keeps personal shopping lists, cart items and orders linked to you.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _sectionTitle(
                      'Personal details',
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization:
                      TextCapitalization.words,
                      textInputAction:
                      TextInputAction.next,
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
                      controller: _icController,
                      keyboardType:
                      TextInputType.number,
                      textInputAction:
                      TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9-]'),
                        ),
                      ],
                      decoration:
                      const InputDecoration(
                        labelText: 'IC number',
                        hintText: 'YYMMDD-PP-NNNN',
                        prefixIcon:
                        Icon(Icons.badge_outlined),
                      ),
                      validator:
                      AuthService.validateIc,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType:
                      TextInputType.phone,
                      textInputAction:
                      TextInputAction.next,
                      decoration:
                      const InputDecoration(
                        labelText: 'Phone number',
                        hintText: '01X-XXXXXXX',
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
                      onChanged: _loading
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
                      textCapitalization:
                      TextCapitalization
                          .sentences,
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
                    _sectionTitle(
                      'Login details',
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _emailController,
                      keyboardType:
                      TextInputType.emailAddress,
                      textInputAction:
                      TextInputAction.next,
                      decoration:
                      const InputDecoration(
                        labelText: 'Email',
                        prefixIcon:
                        Icon(Icons.email_outlined),
                      ),
                      validator:
                      AuthService.validateEmail,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller:
                      _passwordController,
                      obscureText:
                      _obscurePassword,
                      textInputAction:
                      TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword =
                              !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons
                                .visibility_outlined
                                : Icons
                                .visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator:
                      AuthService.validatePassword,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Use at least 8 characters with uppercase, lowercase and a number.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller:
                      _confirmPasswordController,
                      obscureText:
                      _obscureConfirm,
                      textInputAction:
                      TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!_loading) {
                          _register();
                        }
                      },
                      decoration: InputDecoration(
                        labelText:
                        'Confirm password',
                        prefixIcon: const Icon(
                          Icons.lock_reset_outlined,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureConfirm =
                              !_obscureConfirm;
                            });
                          },
                          icon: Icon(
                            _obscureConfirm
                                ? Icons
                                .visibility_outlined
                                : Icons
                                .visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value !=
                            _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _acceptedTerms,
                      activeColor:
                      Colors.green.shade700,
                      onChanged: _loading
                          ? null
                          : (value) {
                        setState(() {
                          _acceptedTerms =
                              value ?? false;
                        });
                      },
                      controlAffinity:
                      ListTileControlAffinity.leading,
                      title: const Text(
                        'I confirm that the information provided is accurate.',
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed:
                      _loading ? null : _register,
                      style: FilledButton.styleFrom(
                        backgroundColor:
                        Colors.green.shade700,
                        padding:
                        const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                      ),
                      child: _loading
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
                        'Create Account',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
