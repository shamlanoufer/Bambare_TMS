// lib/screens/profile/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/forgot/forgot_screen.dart';
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _auth = AuthService();
  late TextEditingController _fullName;
  late TextEditingController _email;
  late TextEditingController _phone;
  late TextEditingController _bio;
  
  String _dob = '';
  String? _gender;
  String? _nationality;
  String? _photoUrl;
  List<String> _selectedPrefs = [];
  
  bool _loading = false;
  bool _uploading = false;

  final List<String> _prefOptions = ['Cultural', 'Beach', 'Wildlife', 'Food', 'Adventure', 'Wellness'];
  final List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];
  final List<String> _nationalities = ['Sri Lankan', 'Indian', 'British', 'American', 'Other'];

  @override
  void initState() {
    super.initState();
    _fullName = TextEditingController(text: widget.user.fullName);
    _email = TextEditingController(text: widget.user.email);
    _phone = TextEditingController(text: widget.user.phone.replaceFirst('+94', ''));
    _bio = TextEditingController(text: widget.user.bio);
    _dob = widget.user.dateOfBirth;
    _gender = widget.user.gender.isNotEmpty ? widget.user.gender : null;
    _nationality = widget.user.nationality.isNotEmpty ? widget.user.nationality : null;
    _photoUrl = widget.user.photoUrl;
    _selectedPrefs = List<String>.from(widget.user.travelPreferences);
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Change Profile Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppTheme.yellow),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.yellow),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
    if (source == null) return;
    final img = await picker.pickImage(source: source, imageQuality: 70);
    if (img == null) return;

    setState(() => _uploading = true);
    try {
      final url = await _auth.uploadProfilePhoto(img, widget.user.uid);
      if (url != null) {
        await _auth.updateUserData(widget.user.uid, {'photoUrl': url});
        if (mounted) {
          setState(() => _photoUrl = url);
          showMsg(context, 'Photo updated!', isError: false);
        }
      } else {
        if (mounted) showMsg(context, 'Upload failed or timed out. Check CORS/Firebase Storage setup.');
      }
    } catch (e) {
      if (mounted) showMsg(context, 'Update failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deleteAccount() async {
    final emailCtrl = TextEditingController(text: widget.user.email);
    final passCtrl = TextEditingController();
    bool dialogLoading = false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Confirm Deletion', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your credentials to permanently delete your account and all data.'),
              const SizedBox(height: 20),
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEFEFEF))),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                decoration: InputDecoration(
                  labelText: 'Password',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEFEFEF))),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              if (dialogLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: CircularProgressIndicator(color: AppTheme.yellow),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: dialogLoading ? null : () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: dialogLoading ? null : () async {
                if (emailCtrl.text.isEmpty || passCtrl.text.isEmpty) {
                  showMsg(context, 'Enter both email and password');
                  return;
                }
                setDialogState(() => dialogLoading = true);
                try {
                  await _auth.deleteAccountWithEmailPassword(
                    email: emailCtrl.text.trim(),
                    password: passCtrl.text,
                  );
                  if (context.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (context.mounted) {
                    setDialogState(() => dialogLoading = false);
                    showMsg(context, parseFirebaseError(e.toString()));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirm Delete'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      if (mounted) {
        showMsg(context, 'Account deleted permanently', isError: false);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  Future<void> _changePassword() async {
    final emailCtrl = TextEditingController(text: widget.user.email);
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    
    int step = 1; // 1: Verify Current, 2: New Password
    bool dialogLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(step == 1 ? 'Verify Current Password' : 'Create New Password', 
                       style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (step == 1) ...[
                  const Text('For security, please enter your current password to continue.'),
                  const SizedBox(height: 20),
                  TextField(
                    controller: emailCtrl,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEFEFEF))),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: currentPassCtrl,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEFEFEF))),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotScreen()));
                      },
                      child: const Text('Forgot Password?', style: TextStyle(color: AppTheme.yellow, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ] else ...[
                  const Text('Enter your new password below.'),
                  const SizedBox(height: 20),
                  TextField(
                    controller: newPassCtrl,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEFEFEF))),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPassCtrl,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEFEFEF))),
                      prefixIcon: const Icon(Icons.lock_reset_rounded),
                    ),
                    obscureText: true,
                  ),
                ],
                if (dialogLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: CircularProgressIndicator(color: AppTheme.yellow),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: dialogLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: dialogLoading ? null : () async {
                if (step == 1) {
                  if (emailCtrl.text.isEmpty || currentPassCtrl.text.isEmpty) {
                    showMsg(context, 'Fill all fields');
                    return;
                  }
                  setDialogState(() => dialogLoading = true);
                  try {
                    // Re-authenticate only
                    final cred = EmailAuthProvider.credential(email: emailCtrl.text.trim(), password: currentPassCtrl.text);
                    await AuthService().currentUser!.reauthenticateWithCredential(cred);
                    setDialogState(() {
                      step = 2;
                      dialogLoading = false;
                    });
                  } catch (e) {
                    if (context.mounted) {
                      setDialogState(() => dialogLoading = false);
                      showMsg(context, parseFirebaseError(e.toString()));
                    }
                  }
                } else {
                  if (newPassCtrl.text.isEmpty || confirmPassCtrl.text.isEmpty) {
                    showMsg(context, 'Fill all fields');
                    return;
                  }
                  if (newPassCtrl.text != confirmPassCtrl.text) {
                    showMsg(context, 'Passwords do not match');
                    return;
                  }
                  setDialogState(() => dialogLoading = true);
                  try {
                    await _auth.updateEmailPassword(
                      email: emailCtrl.text.trim(),
                      currentOrTempPassword: currentPassCtrl.text,
                      newPassword: newPassCtrl.text,
                    );
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      showMsg(context, 'Password updated successfully!', isError: false);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      setDialogState(() => dialogLoading = false);
                      showMsg(context, parseFirebaseError(e.toString()));
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.yellow,
                foregroundColor: AppTheme.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(step == 1 ? 'Verify' : 'Update Password'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final names = _fullName.text.trim().split(' ');
      final fName = names.isNotEmpty ? names.first : '';
      final lName = names.length > 1 ? names.sublist(1).join(' ') : '';
      
      final data = {
        'firstName': fName,
        'lastName': lName,
        'email': _email.text.trim(),
        'phone': AuthService.formatPhone(_phone.text.trim()),
        'dateOfBirth': _dob,
        'gender': _gender ?? '',
        'nationality': _nationality ?? '',
        'bio': _bio.text.trim(),
        'photoUrl': _photoUrl ?? '',
        'travelPreferences': _selectedPrefs,
      };
      await _auth.updateUserData(widget.user.uid, data);
      if (mounted) {
        showMsg(context, 'Profile updated successfully!', isError: false);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showMsg(context, 'Save failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header (Matches Signup Layout)
            Stack(
              children: [
                const Center(child: BeeHeader()),
                Positioned(
                  left: 10,
                  top: 10,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  ),
                ),
              ],
            ),

            // Form Content in a Card (Matches Signup card layout but in white)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Edit Profile 👋', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.black)),
                      const SizedBox(height: 6),
                      const Text('Update your personal and travel details.', style: TextStyle(color: AppTheme.grey, fontSize: 13)),
                      const SizedBox(height: 28),

                      // Avatar Section
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 100, height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.yellow, width: 2),
                                  image: (_photoUrl != null && _photoUrl!.isNotEmpty)
                                      ? DecorationImage(
                                          image: _photoUrl!.startsWith('data:image')
                                              ? MemoryImage(base64Decode(_photoUrl!.split(',').last)) as ImageProvider
                                              : NetworkImage(_photoUrl!), 
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                                  ],
                                ),
                                child: (_photoUrl == null || _photoUrl!.isEmpty) 
                                    ? const Icon(Icons.person, size: 50, color: Colors.grey)
                                    : null,
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(color: AppTheme.yellow, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, size: 16, color: AppTheme.black),
                              ),
                              if (_uploading)
                                const Positioned.fill(child: Center(child: CircularProgressIndicator(color: AppTheme.yellow, strokeWidth: 2))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      _fieldLabel('First & Last Name'),
                      _whiteField(_fullName, 'Full Name', Icons.person_outline),

                      _fieldLabel('Email Address'),
                      _whiteField(_email, 'Email Address', Icons.email_outlined, type: TextInputType.emailAddress),

                      _fieldLabel('Phone Number'),
                      _phoneInput(),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Date of Birth'),
                                _pickerField(_dob.isEmpty ? 'Select Date' : _dob, Icons.calendar_month_outlined, _pickDate),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Gender'),
                                _dropdownField(_gender, _genderOptions, (v) => setState(() => _gender = v)),
                              ],
                            ),
                          ),
                        ],
                      ),

                      _fieldLabel('Nationality'),
                      _dropdownField(_nationality, _nationalities, (v) => setState(() => _nationality = v)),

                      _fieldLabel('Bio (optional)'),
                      _bioField(),

                      const SizedBox(height: 24),
                      _fieldLabel('Travel Preferences'),
                      _prefChips(),

                      const SizedBox(height: 40),
                      _actionTile('🔒', 'Change Password', 'Last changed 3 months ago', onTap: _changePassword),
                      const SizedBox(height: 16),
                      _actionTile('🗑️', 'Delete Account', 'Permanently remove your account', onTap: _deleteAccount),

                      const SizedBox(height: 48),
                      // Save Changes Button (Yellow Pill)
                      GestureDetector(
                        onTap: _save,
                        child: Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7D154), // Matches user screenshot yellow
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFF7D154).withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: _loading
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Cancel Button (Gray Pill)
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBCBCB), // Matches user screenshot gray
                            borderRadius: BorderRadius.circular(30),
                          ),
                          alignment: Alignment.center,
                          child: const Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(String emoji, String title, String sub, {VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEFEFEF))),
          child: Text(emoji, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12, color: AppTheme.grey)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black),
        onTap: onTap,
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.black)),
    );
  }

  Widget _whiteField(TextEditingController controller, String hint, IconData icon, {TextInputType type = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFEF)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        style: const TextStyle(color: AppTheme.black),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(icon, size: 20, color: AppTheme.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.grey.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  Widget _phoneInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFEF)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: const Text('+94', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.black)),
          ),
          Container(height: 24, width: 1, color: Colors.grey.withValues(alpha: 0.3)),
          Expanded(
            child: TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppTheme.black),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                hintText: 'Phone Number',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickerField(String text, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEFEFEF)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.grey),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _dropdownField(String? val, List<String> options, Function(String?) onCh) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: val,
          isExpanded: true,
          hint: const Text('Select'),
          style: const TextStyle(color: AppTheme.black, fontSize: 14),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.grey),
          items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onCh,
        ),
      ),
    );
  }

  Widget _bioField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFEF)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _bio,
        maxLines: 3,
        maxLength: 120,
        style: const TextStyle(color: AppTheme.black),
        decoration: const InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: InputBorder.none,
          hintText: 'About yourself',
          counterStyle: TextStyle(fontSize: 10),
        ),
      ),
    );
  }

  Widget _prefChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _prefOptions.map((e) {
        final isSel = _selectedPrefs.contains(e);
        return GestureDetector(
            onTap: () {
              setState(() {
                if (isSel) {
                  _selectedPrefs.remove(e);
                } else {
                  _selectedPrefs.add(e);
                }
              });
            },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSel ? AppTheme.yellow : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSel ? AppTheme.yellow : const Color(0xFFEFEFEF)),
            ),
            child: Text(
              e,
              style: TextStyle(
                color: AppTheme.black,
                fontSize: 13,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _dob = date.toString().split(' ')[0]);
    }
  }
}
