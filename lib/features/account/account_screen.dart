import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/supabase_service.dart';
import 'login_screen.dart';
import 'my_details.dart';
import 'register_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() =>
      _AccountScreenState();
}

class _AccountScreenState
    extends State<AccountScreen> {
  StreamSubscription<AuthState>? _subscription;
  Map<String, dynamic>? _profile;
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _subscription =
        AuthService.instance.authStateChanges.listen((_) {
          if (mounted) {
            _refresh();
          }
        });

    _refresh();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final user =
        AuthService.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _profile = null;
          _loading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final profile =
      await SupabaseService.instance
          .fetchMyProfile();

      await DatabaseService()
          .upsertProfileCache(profile);

      if (mounted) {
        setState(() {
          _profile = profile;
        });
      }
    } catch (_) {
      final cached =
      await DatabaseService()
          .getProfileCache(user.id);

      if (mounted) {
        setState(() {
          _profile = cached;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _openLogin() async {
    final loggedIn =
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const LoginScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    if (loggedIn == true) {
      await _refresh();
    }
  }

  Future<void> _openRegister() async {
    final registered =
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const RegisterScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    if (registered == true) {
      await _refresh();
    }
  }

  Future<void> _openMyDetails() async {
    final changed =
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const MyDetailsScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    if (changed == true) {
      await _refresh();
    }
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Logged out. Guest browsing is still available.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.instance.isLoggedIn) {
      return _buildGuest();
    }

    return _buildLoggedIn();
  }

  Widget _buildGuest() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
      ),
      body: ListView(
        padding:
        const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 46,
            backgroundColor:
            Colors.green.shade50,
            child: Icon(
              Icons.person_outline,
              size: 52,
              color:
              Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Guest',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
              fontWeight:
              FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Search prices and view nearby grocery stores without an account.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
              Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _openLogin,
            style: FilledButton.styleFrom(
              backgroundColor:
              Colors.green.shade700,
              padding:
              const EdgeInsets.symmetric(
                vertical: 14,
              ),
            ),
            child:
            const Text('Login'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _openRegister,
            child: const Text(
              'Create Account',
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding:
              const EdgeInsets.all(
                16,
              ),
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: Colors
                        .green
                        .shade700,
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  const Expanded(
                    child: Text(
                      'Login is required to save shopping lists, add items to cart, sync orders and keep personal account details.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedIn() {
    final user =
        AuthService.instance.currentUser;

    final fullName =
    _profile?['full_name']
        ?.toString()
        .trim();

    final displayName =
    fullName == null ||
        fullName.isEmpty
        ? 'GROC User'
        : fullName;

    final email =
        _profile?['email']
            ?.toString() ??
            user?.email ??
            '';

    final firstLetter =
    displayName.isEmpty
        ? 'G'
        : displayName
        .substring(0, 1)
        .toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
      ),
      body: _loading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : ListView(
        padding:
        const EdgeInsets
            .fromLTRB(
          16,
          10,
          16,
          28,
        ),
        children: [
          const SizedBox(height: 6),
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor:
                Colors.green
                    .shade100,
                child: Text(
                  firstLetter,
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight:
                    FontWeight
                        .bold,
                    color: Colors
                        .green
                        .shade800,
                  ),
                ),
              ),
              const SizedBox(
                width: 14,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      displayName,
                      style:
                      const TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight
                            .bold,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      email,
                      style:
                      TextStyle(
                        color: Colors
                            .grey
                            .shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _refresh,
                icon: const Icon(
                  Icons.refresh,
                ),
                tooltip:
                'Refresh profile',
              ),
            ],
          ),
          const SizedBox(height: 22),
          Card(
            clipBehavior:
            Clip.antiAlias,
            child: Column(
              children: [
                _menuTile(
                  Icons
                      .person_outline,
                  'My Details',
                  _openMyDetails,
                ),
                const Divider(
                  height: 1,
                ),
                _menuTile(
                  Icons
                      .notifications_none,
                  'Notifications',
                      () {
                    ScaffoldMessenger
                        .of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'No new notifications.',
                        ),
                      ),
                    );
                  },
                ),
                const Divider(
                  height: 1,
                ),
                _menuTile(
                  Icons
                      .help_outline,
                  'Help',
                  _showHelp,
                ),
                const Divider(
                  height: 1,
                ),
                _menuTile(
                  Icons
                      .info_outline,
                  'About',
                  _showAbout,
                ),
                const Divider(
                  height: 1,
                ),
                _menuTile(
                  Icons
                      .settings_outlined,
                  'Account Settings',
                  _showAccountSettings,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _logout,
            icon:
            const Icon(Icons.logout),
            label:
            const Text('Log Out'),
            style:
            OutlinedButton.styleFrom(
              foregroundColor:
              Colors.red.shade700,
              padding:
              const EdgeInsets
                  .symmetric(
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile(
      IconData icon,
      String title,
      VoidCallback onTap,
      ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing:
      const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) =>
          AlertDialog(
            title: const Text('Help'),
            content: const Text(
              'Use Explore to compare grocery prices, Grocer to find nearby stores, List to manage saved shopping lists, and My Details to view or edit your personal information and address.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                  );
                },
                child:
                const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'GROC',
      applicationVersion: '1.0',
      applicationLegalese:
      'Grocery Price Comparison Platform',
    );
  }

  void _showAccountSettings() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) =>
          SafeArea(
            child: Padding(
              padding:
              const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                24,
              ),
              child: Column(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons
                          .lock_reset_outlined,
                    ),
                    title: const Text(
                      'Send password reset email',
                    ),
                    onTap: () async {
                      Navigator.pop(
                        sheetContext,
                      );

                      final email =
                          AuthService
                              .instance
                              .currentUser
                              ?.email;

                      if (email == null) {
                        return;
                      }

                      try {
                        await AuthService
                            .instance
                            .sendPasswordReset(
                          email,
                        );

                        if (!mounted) {
                          return;
                        }

                        ScaffoldMessenger
                            .of(
                          context,
                        ).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Password reset email sent.',
                            ),
                          ),
                        );
                      } on AuthException catch (
                      error
                      ) {
                        if (!mounted) {
                          return;
                        }

                        ScaffoldMessenger
                            .of(
                          context,
                        ).showSnackBar(
                          SnackBar(
                            content: Text(
                              error.message,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
