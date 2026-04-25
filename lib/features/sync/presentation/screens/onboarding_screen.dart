import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hisabet/core/utils/phone_util.dart';
import 'package:hisabet/features/contacts/presentation/screens/contacts_list_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final bool startAtProfile;
  final List<String> initialRoles;
  const OnboardingScreen({super.key, this.startAtProfile = false, this.initialRoles = const []});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const bool _manualBypassEnabled = bool.fromEnvironment(
    'PHONE_AUTH_MANUAL_BYPASS',
  );
  static const bool _devBypassProfileCheck = bool.fromEnvironment(
    'DEV_BYPASS_PROFILE_CHECK',
  );
  static const String _manualBypassCode = String.fromEnvironment(
    'PHONE_AUTH_TEST_CODE',
  );

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _profilePhoneController = TextEditingController();
  final _supplierAddressController = TextEditingController();
  final _supplierTermsController = TextEditingController(text: '0');
  final _supplierOpeningBalanceController = TextEditingController(text: '0');
  final _supplierCurrentBalanceController = TextEditingController(text: '0');
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _codeSent = false;
  late bool _isNameStep; // Late initialization
  List<String> _selectedRoles = [];
  final List<String> _availableRoles = ['Supplier', 'Broker', 'Wholesaler', 'Retailer'];

  bool _profilePhoneVerified = false;
  String? _linkingVerificationId;
  bool _linkingCodeSent = false;
  bool _isLinking = false;
  final _linkingOtpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isNameStep = widget.startAtProfile;
    if (widget.initialRoles.isNotEmpty) {
      _selectedRoles = List.from(widget.initialRoles);
    }
    final signedInPhone = FirebaseAuth.instance.currentUser?.phoneNumber;
    if (signedInPhone != null && signedInPhone.trim().isNotEmpty) {
      _profilePhoneController.text = signedInPhone;
      _profilePhoneVerified = true;
    }
  }

  String? _verificationId;
  String? _phoneError;
  int? _resendToken;

  // Timer Logic
  Timer? _timer;
  int _start = 60;
  bool _canResend = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _profilePhoneController.dispose();
    _linkingOtpController.dispose();
    _supplierAddressController.dispose();
    _supplierTermsController.dispose();
    _supplierOpeningBalanceController.dispose();
    _supplierCurrentBalanceController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _start = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _canResend = true;
          _timer?.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  Future<void> _verifyPhone() async {
    setState(() {
      _isLoading = true;
      _phoneError = null;
    });

    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) {
      setState(() {
        _isLoading = false;
        _phoneError = 'Phone number required. ex: +251...';
      });
      return;
    }

    final phone = PhoneUtil.normalize(rawPhone);
    final digitCount = phone.replaceAll(RegExp(r'\D'), '').length;
    if (!phone.startsWith('+') || digitCount < 10 || digitCount > 15) {
      setState(() {
        _isLoading = false;
        _phoneError = 'Use a valid phone number in international format.';
      });
      return;
    }

    _phoneController.text = phone;

    // Debug-only manual bypass mode for development without SMS/billing.
    if (_manualBypassEnabled && _manualBypassCode.isNotEmpty) {
      if (mounted) {
        setState(() {
          _verificationId = '__manual_dev_bypass__';
          _codeSent = true;
          _isLoading = false;
        });
        _startTimer();
      }
      return;
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution (Instant)
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (mounted) {
            await _checkUserProfile();
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _phoneError = _readablePhoneAuthError(e);
            });
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _resendToken = resendToken;
              _codeSent = true;
              _isLoading = false;
            });
            _startTimer();
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _phoneError = e.toString();
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6 || _verificationId == null) return;
    setState(() => _isLoading = true);
    debugPrint('[OnboardingScreen] _verifyOtp: submitting OTP...');

    if (_verificationId == '__manual_dev_bypass__') {
      final enteredCode = _otpController.text.trim();
      if (enteredCode != _manualBypassCode) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid test code for manual bypass.')),
          );
        }
        return;
      }

      try {
        debugPrint('[OnboardingScreen] Dev bypass: signing in anonymously...');
        await FirebaseAuth.instance.signInAnonymously();
        debugPrint('[OnboardingScreen] Dev bypass: anonymous sign-in complete. AuthGate will handle routing.');
        // AuthGate/ProfileCheckGate handles routing. Reset loading if still mounted.
        if (mounted) setState(() => _isLoading = false);
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Anonymous dev sign-in failed.')),
          );
        }
      }
      return;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );

      debugPrint('[OnboardingScreen] _verifyOtp: calling signInWithCredential...');
      await FirebaseAuth.instance.signInWithCredential(credential);
      debugPrint('[OnboardingScreen] _verifyOtp: signInWithCredential SUCCESS. AuthGate will handle routing.');
      // AuthGate's authStateChanges stream fires -> ProfileCheckGate takes over.
      // Reset loading if still mounted (widget may already be unmounted by AuthGate rebuild).
      if (mounted) setState(() => _isLoading = false);
    } on FirebaseAuthException catch (e) {
      debugPrint('[OnboardingScreen] _verifyOtp: FirebaseAuthException: ${e.code} - ${e.message}');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_readablePhoneAuthError(e))),
        );
      }
    } catch (e) {
      debugPrint('[OnboardingScreen] _verifyOtp: unexpected error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _phoneError = null;
    });
    debugPrint('[OnboardingScreen] _signInWithGoogle: starting Google sign-in flow...');

    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('[OnboardingScreen] _signInWithGoogle: user cancelled Google sign-in.');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      debugPrint('[OnboardingScreen] _signInWithGoogle: got Google user ${googleUser.email}');
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('[OnboardingScreen] _signInWithGoogle: calling signInWithCredential...');
      await FirebaseAuth.instance.signInWithCredential(credential);
      debugPrint('[OnboardingScreen] _signInWithGoogle: signInWithCredential SUCCESS. AuthGate will handle routing.');
      // AuthGate's authStateChanges stream fires -> ProfileCheckGate takes over.
      if (mounted) setState(() => _isLoading = false);
    } on FirebaseAuthException catch (e) {
      debugPrint('[OnboardingScreen] _signInWithGoogle: FirebaseAuthException: ${e.code} - ${e.message}');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Google sign-in failed.')),
        );
      }
    } catch (e) {
      debugPrint('[OnboardingScreen] _signInWithGoogle: unexpected error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in failed: $e')),
        );
      }
    }
  }

  String _readablePhoneAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Invalid phone format. Example: +251911223344';
      case 'invalid-verification-code':
        return 'The OTP code is invalid. Please try again.';
      case 'invalid-verification-id':
        return 'Verification session expired. Please request a new code.';
      case 'session-expired':
        return 'Code expired. Request a new verification code.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Try again later or use a test number.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and retry.';
      case 'app-not-authorized':
        return 'This app is not authorized in Firebase. Check SHA-1/SHA-256 setup.';
      case 'captcha-check-failed':
        return 'App verification failed. Retry and complete the reCAPTCHA step.';
      default:
        return e.message ?? 'Phone verification failed. Please try again.';
    }
  }

  Future<void> _verifyPhoneForProfile() async {
    setState(() {
      _isLinking = true;
    });

    final rawPhone = _profilePhoneController.text.trim();
    if (rawPhone.isEmpty) {
      setState(() => _isLinking = false);
      return;
    }
    
    final phone = PhoneUtil.normalize(rawPhone);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.currentUser?.linkWithCredential(credential);
          if (mounted) {
            setState(() {
              _profilePhoneVerified = true;
              _isLinking = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Phone number verified automatically.')),
            );
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() => _isLinking = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_readablePhoneAuthError(e))),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _linkingVerificationId = verificationId;
              _linkingCodeSent = true;
              _isLinking = false;
            });
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _linkingVerificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLinking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e')),
        );
      }
    }
  }

  Future<void> _verifyOtpForProfile() async {
    if (_linkingOtpController.text.length != 6 || _linkingVerificationId == null) return;
    setState(() => _isLinking = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _linkingVerificationId!,
        smsCode: _linkingOtpController.text.trim(),
      );

      await FirebaseAuth.instance.currentUser?.linkWithCredential(credential);

      if (mounted) {
        setState(() {
          _profilePhoneVerified = true;
          _isLinking = false;
          _linkingCodeSent = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number linked successfully.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLinking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_readablePhoneAuthError(e))),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLinking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Check if profile exists; if not, show name setup
  Future<void> _checkUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data();
    final hasName = data?['name']?.toString().trim().isNotEmpty == true;
    final hasPhone = data?['phone']?.toString().trim().isNotEmpty == true;
    final hasEmail = data?['email']?.toString().trim().isNotEmpty == true;
    final existingRoles = (data?['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final hasRoles = existingRoles.isNotEmpty;

    // Populate local role state if user already has roles in DB
    if (hasRoles && _selectedRoles.isEmpty && mounted) {
      setState(() => _selectedRoles = existingRoles);
    }

    // Profile is complete: has name, at least one role, and phone OR email
    final isComplete = doc.exists && hasName && (hasPhone || hasEmail) && hasRoles;

    if (isComplete) {
      // AuthGate's StreamBuilder will handle routing to MainScaffold.
      // Just reset the loading state.
      if (mounted) setState(() => _isLoading = false);
    } else {
      // New user or incomplete profile -> show Profile setup step
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isNameStep = true;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final profilePhone = _profilePhoneController.text.trim();
    
    if (name.isEmpty) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (profilePhone.isNotEmpty && !_profilePhoneVerified && user.phoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify your optional phone number first or clear the field.')),
      );
      return;
    }

    if (_selectedRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one business role.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    debugPrint('[OnboardingScreen] _saveProfile: saving for uid=${user.uid}, name=$name, roles=$_selectedRoles');

    try {
      final profilePayload = <String, dynamic>{
        'id': user.uid,
        'name': name,
        'roles': _selectedRoles,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Save phone: prefer user-entered verified phone, else use Firebase Auth phone
      if (_profilePhoneVerified && profilePhone.isNotEmpty) {
        profilePayload['phone'] = PhoneUtil.normalize(profilePhone);
      } else if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
        profilePayload['phone'] = user.phoneNumber!;
      }

      // Always save email from Firebase Auth if available (Google users)
      if (user.email != null && user.email!.isNotEmpty) {
        profilePayload['email'] = user.email!;
        debugPrint('[OnboardingScreen] _saveProfile: saving email=${user.email}');
      }

      if (_selectedRoles.contains('Supplier')) {
        profilePayload['supplierAddress'] =
            _supplierAddressController.text.trim().isEmpty
                ? null
                : _supplierAddressController.text.trim();
        profilePayload['supplierTermsDays'] =
            int.tryParse(_supplierTermsController.text.trim()) ?? 0;
        profilePayload['supplierOpeningBalance'] =
            _supplierOpeningBalanceController.text.trim().isEmpty
                ? '0'
                : _supplierOpeningBalanceController.text.trim();
        profilePayload['supplierCurrentBalance'] =
            _supplierCurrentBalanceController.text.trim().isEmpty
                ? '0'
                : _supplierCurrentBalanceController.text.trim();
      }

      debugPrint('[OnboardingScreen] _saveProfile: writing to Firestore...');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(profilePayload, SetOptions(merge: true));
      debugPrint('[OnboardingScreen] _saveProfile: Firestore write SUCCESS. ProfileCheckGate will navigate to MainScaffold.');
      // ProfileCheckGate's Firestore stream detects the update and routes to MainScaffold.
    } on FirebaseException catch (e) {
      if (!mounted) return;

      if (e.code == 'permission-denied') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profile save blocked by Firestore rules. Allow users/{uid} write in Firebase rules.',
            ),
          ),
        );

        // Let AuthGate handle navigation if bypassed
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile save failed: ${e.message ?? e.code}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we are showing Name Step, we are technically logged in,
    // but we preventing the main app from showing until we are done?
    // Actually, AuthGate will remove this widget once logged in.
    // We need to fix AuthGate to wait for Profile?
    // OR we change the flow: Onboarding is NOT removed until we say so?
    // No, StreamBuilder reacts instantly.

    // Quick Fix Plan for User Request:
    // Update AuthGate to check if Profile is complete? That causes loading delay.
    // Better: Allow access to Home, but show "Complete Profile" modal?
    // User asked for "Enforce account creation".

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNameStep ? 'Create Profile' : 'Verified Login'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              try {
                final GoogleSignIn googleSignIn = GoogleSignIn();
                if (await googleSignIn.isSignedIn()) {
                  await googleSignIn.signOut();
                }
              } catch (_) {}
              if (mounted) {
                setState(() {
                  _isNameStep = false;
                  _selectedRoles.clear();
                });
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isNameStep) ...[
                  const Icon(Icons.person, size: 64, color: Colors.blue),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome!',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'What should we call you?',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name (e.g. Ahmed Shop)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select your business roles:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _availableRoles.map((role) {
                      final isSelected = _selectedRoles.contains(role);
                      return FilterChip(
                        label: Text(role),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedRoles.add(role);
                            } else {
                              _selectedRoles.remove(role);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  if (_selectedRoles.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Please select at least one role to continue.',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _profilePhoneController,
                          keyboardType: TextInputType.phone,
                          enabled: FirebaseAuth.instance.currentUser?.phoneNumber == null,
                          decoration: InputDecoration(
                            labelText: FirebaseAuth.instance.currentUser?.phoneNumber != null ? 'Phone Number' : 'Optional Phone Number',
                            hintText: '+251911223344',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.phone),
                          ),
                        ),
                      ),
                      if (FirebaseAuth.instance.currentUser?.phoneNumber == null && !_profilePhoneVerified) ...[
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isLinking ? null : _verifyPhoneForProfile,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          ),
                          child: _isLinking ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Verify'),
                        ),
                      ] else if (_profilePhoneVerified) ...[
                        const SizedBox(width: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Icon(Icons.check_circle, color: Colors.green),
                        ),
                      ]
                    ],
                  ),
                  if (_linkingCodeSent && !_profilePhoneVerified) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _linkingOtpController,
                            decoration: const InputDecoration(
                              labelText: '6-Digit SMS Code',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isLinking ? null : _verifyOtpForProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          ),
                          child: _isLinking ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Confirm'),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_selectedRoles.contains('Supplier')) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _supplierAddressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Supplier Address (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _supplierTermsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Credit Terms (Days, Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.schedule),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _supplierOpeningBalanceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Opening Balance',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _supplierCurrentBalanceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Current Balance',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Keep balances at 0 unless you are migrating from existing paper/old records.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: (_isLoading || _selectedRoles.isEmpty) ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: _selectedRoles.isEmpty ? Colors.grey : null,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Start Using HisabET'),
                  ),
                ] else if (!_codeSent) ...[
                  const Icon(Icons.security, size: 64, color: Colors.orange),
                  const SizedBox(height: 24),
                  Text(
                    'Secure Login',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select your business roles to continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+251911223344',
                      border: const OutlineInputBorder(),
                      errorText: _phoneError,
                      prefixIcon: const Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.go,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyPhone,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Send Code'),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: const [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('or'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: const Icon(Icons.login),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(14),
                    ),
                  ),
                  if (_manualBypassEnabled && _manualBypassCode.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Dev mode: manual OTP bypass is enabled.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ] else ...[
                  const Icon(Icons.message, size: 64, color: Colors.green),
                  const SizedBox(height: 24),
                  Text(
                    'Enter Validation Code',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sent to ${_phoneController.text}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _otpController,
                    decoration: const InputDecoration(
                      labelText: '6-Digit Code',
                      hintText: '123456',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_clock),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                  const SizedBox(height: 8),
                  // Timer / Resend
                  TextButton(
                    onPressed: _canResend ? _verifyPhone : null,
                    child: Text(
                      _canResend ? 'Resend Code' : 'Resend in $_start s',
                    ),
                  ),

                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Verify & Login'),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _codeSent = false;
                      _verificationId = null;
                      _otpController.clear();
                    }),
                    child: const Text('Wrong Number?'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
