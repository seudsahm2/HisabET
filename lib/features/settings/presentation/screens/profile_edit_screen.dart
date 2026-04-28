import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hisabet/core/auth/providers/auth_providers.dart';
import 'package:hisabet/core/theme/app_colors.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _nameCtrl = TextEditingController();
  final _birthdayCtrl = TextEditingController();
  bool _saving = false;
  String? _photoUrl;
  File? _localImage;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider).value;
    _nameCtrl.text = profile?.displayName ?? '';
    _photoUrl = FirebaseAuth.instance.currentUser?.photoURL;
    // Load birthday from Firestore if stored
    _loadExtraData();
  }

  Future<void> _loadExtraData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists && mounted) {
      setState(() {
        _birthdayCtrl.text = doc.data()?['birthday'] ?? '';
        _photoUrl = doc.data()?['photoUrl'] ?? _photoUrl;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked == null) return;
    setState(() => _localImage = File(picked.path));
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      String? uploadedUrl;

      if (_localImage != null) {
        final ref = FirebaseStorage.instance.ref('profile_photos/$uid.jpg');
        await ref.putFile(_localImage!);
        uploadedUrl = await ref.getDownloadURL();
        await FirebaseAuth.instance.currentUser?.updatePhotoURL(uploadedUrl);
      }

      final payload = <String, dynamic>{
        'name': name,
        'display_name': name,
        'birthday': _birthdayCtrl.text.trim(),
      };
      if (uploadedUrl != null) payload['photoUrl'] = uploadedUrl;

      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        payload,
        SetOptions(merge: true),
      );
      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _birthdayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ── Avatar ────────────────────────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: AppColors.primaryContainer,
                      backgroundImage: _localImage != null
                          ? FileImage(_localImage!) as ImageProvider
                          : (_photoUrl != null ? NetworkImage(_photoUrl!) : null),
                      child: (_localImage == null && _photoUrl == null)
                          ? Text(
                              (user?.displayName ?? 'U').substring(0, 1).toUpperCase(),
                              style: const TextStyle(fontSize: 40, color: AppColors.primary, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to change photo',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 32),

            // ── Email (read-only) ─────────────────────────────────────────
            TextFormField(
              initialValue: user?.email ?? 'No email linked',
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Email (cannot be changed)',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // ── Display Name ──────────────────────────────────────────────
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // ── Birthday (optional) ───────────────────────────────────────
            TextFormField(
              controller: _birthdayCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Birthday (optional)',
                prefixIcon: Icon(Icons.cake_outlined),
                hintText: 'Tap to pick date',
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime(1995),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (picked != null && mounted) {
                  setState(() {
                    _birthdayCtrl.text =
                        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                  });
                }
              },
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
