// lib/screens/auth/signup/signup_controller.dart
import 'package:flutter/material.dart';
import 'dart:io' show File;
import 'dart:typed_data' show Uint8List;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../services/auth_service.dart';
import '../../../models/user_model.dart';
import '../login_screen.dart';
import '../phone_otp_screen.dart';

class SignupController extends StatefulWidget {
  const SignupController({super.key});

  @override
  State<SignupController> createState() => _SignupControllerState();
}

class _SignupControllerState extends State<SignupController> {
  final _auth = AuthService();
  final PageController _pageCtrl = PageController();
  int _step = 0;
  bool _loading = false;

  // Step 1
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _nic = TextEditingController();
  final _dob = TextEditingController();
  XFile? _photoFile;
  Uint8List? _webImage;

  // Step 2
  final _address = TextEditingController();
  final _district = TextEditingController();
  final _province = TextEditingController();

  // Step 3
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPass = TextEditingController();
  bool _agreed = false;
  bool _passObscure = true;
  bool _confirmObscure = true;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _nic.dispose();
    _dob.dispose();
    _address.dispose();
    _district.dispose();
    _province.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPass.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (img != null) {
      if (kIsWeb) {
        final bytes = await img.readAsBytes();
        setState(() {
          _photoFile = img;
          _webImage = bytes;
        });
      } else {
        setState(() => _photoFile = img);
      }
    }
  }

  void _nextPage() {
    _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _step++);
  }

  bool _validateStep1() {
    if (_firstName.text.trim().isEmpty || _lastName.text.trim().isEmpty || _nic.text.trim().isEmpty || _dob.text.trim().isEmpty) {
      showMsg(context, 'Please fill all required fields');
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_address.text.trim().isEmpty || _district.text.trim().isEmpty || _province.text.trim().isEmpty) {
      showMsg(context, 'Please fill all address details');
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final phoneRaw = _phone.text.trim();
    final pass = _password.text;
    if (email.isEmpty || pass.isEmpty) {
      showMsg(context, 'Please enter email and password');
      return;
    }
    if (phoneRaw.isEmpty) {
      showMsg(context, 'Please enter your phone number');
      return;
    }
    if (pass != _confirmPass.text) {
      showMsg(context, 'Passwords do not match');
      return;
    }
    if (!_agreed) {
      showMsg(context, 'You must agree to the Terms of Service');
      return;
    }

    final phone = AuthService.formatPhone(phoneRaw);
    final userModel = UserModel(
      uid: '',
      email: email,
      phone: phone,
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      nicNumber: _nic.text.trim(),
      dateOfBirth: _dob.text.trim(),
      personalAddress: _address.text.trim(),
      district: _district.text.trim(),
      province: _province.text.trim(),
      photoUrl: '',
    );

    setState(() => _loading = true);
    _auth.sendRegisterOtp(
      phone: phone,
      onSent: (verId) {
        if (!mounted) return;
        setState(() => _loading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PhoneOtpScreen(
              verificationId: verId,
              phone: phone,
              mode: OtpMode.register,
              email: email,
              password: pass,
              userModel: userModel,
              photoFile: _photoFile,
            ),
          ),
        );
      },
      onError: (e) {
        if (mounted) {
          setState(() => _loading = false);
          showMsg(context, parseFirebaseError(e));
        }
      },
    );
  }

  void _goToStep(int index) {
    if (index < 0 || index > 2) return;
    setState(() => _step = index);
    _pageCtrl.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isActive = i <= _step;
        return GestureDetector(
          onTap: () => _goToStep(i),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              height: 6,
              width: 32,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.white : AppTheme.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: BeeHeader(),
          ),

            // Card
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildStepIndicator(),
                    Expanded(
                      child: PageView(
                        controller: _pageCtrl,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _Step1Personal(
                            firstName: _firstName,
                            lastName: _lastName,
                            nic: _nic,
                            dob: _dob,
                            photoFile: _photoFile,
                            webImage: _webImage,
                            onPhoto: _pickImage,
                            onNext: () {
                              if (_validateStep1()) _nextPage();
                            },
                          ),
                          _Step2Address(
                            address: _address,
                            district: _district,
                            province: _province,
                            onNext: () {
                              if (_validateStep2()) _nextPage();
                            },
                          ),
                          _Step3Account(
                            email: _email,
                            phone: _phone,
                            password: _password,
                            confirmPass: _confirmPass,
                            passObscure: _passObscure,
                            confirmObscure: _confirmObscure,
                            togglePass: () => setState(() => _passObscure = !_passObscure),
                            toggleConfirm: () => setState(() => _confirmObscure = !_confirmObscure),
                            agreed: _agreed,
                            onAgreed: (v) => setState(() => _agreed = v),
                            loading: _loading,
                            onSubmit: _submit,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step1Personal extends StatelessWidget {
  final TextEditingController firstName, lastName, nic, dob;
  final XFile? photoFile;
  final Uint8List? webImage;
  final VoidCallback onNext, onPhoto;

  const _Step1Personal({
    required this.firstName,
    required this.lastName,
    required this.nic,
    required this.dob,
    this.photoFile,
    this.webImage,
    required this.onNext,
    required this.onPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Welcome! 👋', style: AppTheme.heading),
          const SizedBox(height: 6),
          const Text('Make sure to fill in your personal\ninformation correctly.', style: AppTheme.subText),
          const SizedBox(height: 24),

          Center(
            child: GestureDetector(
              onTap: onPhoto,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      shape: BoxShape.circle,
                      image: photoFile != null 
                          ? DecorationImage(
                              image: (kIsWeb && webImage != null)
                                  ? MemoryImage(webImage!)
                                  : FileImage(File(photoFile!.path)) as ImageProvider,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: photoFile == null 
                        ? const Icon(Icons.person, size: 45, color: Colors.grey)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const FieldLabel('First name'),
          DarkField(controller: firstName, hint: ''),
          const SizedBox(height: 14),

          const FieldLabel('Last name'),
          DarkField(controller: lastName, hint: ''),
          const SizedBox(height: 14),

          const FieldLabel('NIC number'),
          DarkField(controller: nic, hint: ''),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text("This can't be changed later. Double-check before submitting.", style: TextStyle(color: AppTheme.grey, fontSize: 10)),
          ),
          const SizedBox(height: 14),

          const FieldLabel('Date of birth'),
          DarkField(controller: dob, hint: ''),
          const SizedBox(height: 24),

          PrimaryBtn(label: 'Next', onTap: onNext),
          const SizedBox(height: 16),
          
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: RichText(
                text: const TextSpan(children: [
                  TextSpan(text: 'Already have an account? ', style: TextStyle(color: AppTheme.grey, fontSize: 13)),
                  TextSpan(text: 'Sign in', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step2Address extends StatelessWidget {
  final TextEditingController address, district, province;
  final VoidCallback onNext;

  const _Step2Address({
    required this.address,
    required this.district,
    required this.province,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Welcome! 👋', style: AppTheme.heading),
          const SizedBox(height: 6),
          const Text('Make sure to fill in your personal\ninformation correctly.', style: AppTheme.subText),
          const SizedBox(height: 32),

          const FieldLabel('Personal address'),
          DarkField(controller: address, hint: ''),
          const SizedBox(height: 14),

          const FieldLabel('District'),
          DarkField(controller: district, hint: ''),
          const SizedBox(height: 14),

          const FieldLabel('Province'),
          DarkField(controller: province, hint: ''),
          const SizedBox(height: 32),

          PrimaryBtn(label: 'Next', onTap: onNext),
          const SizedBox(height: 16),
          
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: RichText(
                text: const TextSpan(children: [
                  TextSpan(text: 'Already have an account? ', style: TextStyle(color: AppTheme.grey, fontSize: 13)),
                  TextSpan(text: 'Sign in', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step3Account extends StatelessWidget {
  final TextEditingController email, phone, password, confirmPass;
  final bool passObscure, confirmObscure, agreed, loading;
  final VoidCallback togglePass, toggleConfirm, onSubmit;
  final ValueChanged<bool> onAgreed;

  const _Step3Account({
    required this.email,
    required this.phone,
    required this.password,
    required this.confirmPass,
    required this.passObscure,
    required this.confirmObscure,
    required this.agreed,
    required this.togglePass,
    required this.toggleConfirm,
    required this.onAgreed,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Welcome! 👋', style: AppTheme.heading),
          const SizedBox(height: 6),
          const Text('Make sure to fill in your personal\ninformation correctly.', style: AppTheme.subText),
          const SizedBox(height: 32),

          const FieldLabel('Email address'),
          DarkField(controller: email, hint: '', keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),

          const FieldLabel('Phone number'),
          PhoneField(
            controller: phone,
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Will be saved to your account for password reset.', style: TextStyle(color: AppTheme.grey, fontSize: 10)),
          ),
          const SizedBox(height: 14),

          const FieldLabel('Password'),
          DarkField(
            controller: password, hint: '', obscure: passObscure,
            suffix: IconButton(
              icon: Icon(passObscure ? Icons.visibility_off : Icons.visibility, color: AppTheme.grey, size: 20),
              onPressed: togglePass,
            ),
          ),
          const SizedBox(height: 14),

          const FieldLabel('Confirm Password'),
          DarkField(
            controller: confirmPass, hint: '', obscure: confirmObscure,
            suffix: IconButton(
              icon: Icon(confirmObscure ? Icons.visibility_off : Icons.visibility, color: AppTheme.grey, size: 20),
              onPressed: toggleConfirm,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              SizedBox(
                width: 24, height: 24,
                child: Checkbox(
                  value: agreed,
                  onChanged: (v) => onAgreed(v ?? false),
                  activeColor: AppTheme.white,
                  checkColor: AppTheme.black,
                  side: const BorderSide(color: AppTheme.grey),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('I agree to the Terms of Service and Privacy Policy', style: TextStyle(color: AppTheme.grey, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 32),

          PrimaryBtn(label: 'Create Account', onTap: onSubmit, loading: loading),
          const SizedBox(height: 16),
          
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: RichText(
                text: const TextSpan(children: [
                  TextSpan(text: 'Already have an account? ', style: TextStyle(color: AppTheme.grey, fontSize: 13)),
                  TextSpan(text: 'Sign in', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
