import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hisabet/core/auth/providers/auth_providers.dart';
import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/app_colors.dart';
import 'package:hisabet/core/theme/app_text_styles.dart';
import 'package:hisabet/core/theme/theme_provider.dart';
import 'package:intl/intl.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _nameCtrl = TextEditingController();
  final _birthdayCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _saving = false;
  String? _photoUrl;
  File? _localImage;
  DateTime? _joinedDate;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider).value;
    _nameCtrl.text = profile?.displayName ?? '';
    _photoUrl = FirebaseAuth.instance.currentUser?.photoURL;
    _joinedDate = FirebaseAuth.instance.currentUser?.metadata.creationTime;
    _loadExtraData();
  }

  Future<void> _loadExtraData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists && mounted) {
      final data = doc.data()!;
      setState(() {
        _birthdayCtrl.text = data['birthday'] ?? '';
        _roleCtrl.text = data['role'] ?? '';
        _phoneCtrl.text = data['phone'] ?? '';
        _photoUrl = data['photoUrl'] ?? _photoUrl;
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
        'role': _roleCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      };
      if (uploadedUrl != null) payload['photoUrl'] = uploadedUrl;

      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        payload,
        SetOptions(merge: true),
      );
      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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
    _roleCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final themeMode = ref.watch(themeModeProvider);
    final avatar = _localImage != null
        ? FileImage(_localImage!)
        : (_photoUrl != null ? NetworkImage(_photoUrl!) as ImageProvider : null);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: AppProfileHeader(
                name: user?.displayName ?? 'Merchant',
                avatar: avatar,
                subtitle: _roleCtrl.text.isEmpty ? 'Business profile and account details' : _roleCtrl.text,
                helperText: 'Tap avatar to update photo',
                onAvatarTap: _pickImage,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('PERSONAL INFORMATION'),
                  const SizedBox(height: 16),
                  _buildProfileField(
                    controller: _nameCtrl,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  _buildProfileField(
                    controller: _roleCtrl,
                    label: 'Business Role',
                    icon: Icons.work_outline,
                    hint: 'e.g. Store Manager, Owner',
                  ),
                  const SizedBox(height: 16),
                  _buildProfileField(
                    controller: _phoneCtrl,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildProfileField(
                    controller: _birthdayCtrl,
                    label: 'Birthday',
                    icon: Icons.cake_outlined,
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(1995),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null && mounted) {
                        setState(() {
                          _birthdayCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader('APPEARANCE'),
                  const SizedBox(height: 12),
                  _buildThemeSelector(themeMode),
                  const SizedBox(height: 32),
                  _buildSectionHeader('ACCOUNT SECURITY'),
                  const SizedBox(height: 16),
                  _buildReadOnlyField(
                    label: 'Linked Email',
                    value: user?.email ?? 'No email linked',
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildReadOnlyField(
                    label: 'Member Since',
                    value: _joinedDate != null ? DateFormat('MMMM dd, yyyy').format(_joinedDate!) : 'N/A',
                    icon: Icons.calendar_today_outlined,
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text('Save Profile Changes', style: AppTextStyles.buttonLabel),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.sectionLabel,
    );
  }

  Widget _buildProfileField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary.withOpacity(0.6)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.labelSmall),
              Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(ThemeMode currentMode) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          _buildThemeOption(ThemeMode.light, Icons.light_mode, 'Light', currentMode == ThemeMode.light),
          _buildThemeOption(ThemeMode.dark, Icons.dark_mode, 'Dark', currentMode == ThemeMode.dark),
          _buildThemeOption(ThemeMode.system, Icons.settings_brightness, 'System', currentMode == ThemeMode.system),
        ],
      ),
    );
  }

  Widget _buildThemeOption(ThemeMode mode, IconData icon, String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : AppColors.textSecondary, size: 20),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}

