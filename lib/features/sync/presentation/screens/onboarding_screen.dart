import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hisabet/core/utils/phone_util.dart';
import 'package:hisabet/features/contacts/presentation/screens/contacts_list_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final bool startAtProfile;
  const OnboardingScreen({super.key, this.startAtProfile = false});

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
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _codeSent = false;
  late bool _isNameStep; // Late initialization

  @override
  void initState() {
    super.initState();
    _isNameStep = widget.startAtProfile;
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
        // Anonymous sign-in unlocks authenticated app flow for feature development.
        await FirebaseAuth.instance.signInAnonymously();
        if (mounted) {
          await _checkUserProfile();
        }
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

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted) {
        await _checkUserProfile();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_readablePhoneAuthError(e))),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _phoneError = null;
    });

    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted) {
        await _checkUserProfile();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Google sign-in failed.')),
        );
      }
    } catch (e) {
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

  // Check if profile exists; if not, show name setup
  Future<void> _checkUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists && doc.data() != null && doc.data()!['name'] != null) {
      // User exists and has name -> AuthGate handles navigation
    } else {
      // User is new -> Show Name Setup
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
    if (name.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'id': user.uid,
          'phone': user.phoneNumber,
          'name': name,
          'created_at': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ContactsListScreen()),
          );
        }
      }
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

        if (_devBypassProfileCheck) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ContactsListScreen()),
          );
        }
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
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
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
                    'We will verify your phone number to secure your ledger.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
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
