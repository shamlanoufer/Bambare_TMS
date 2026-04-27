import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin_login_screen.dart';

/// Routes unauthenticated users to [AdminLoginScreen] and verified admins to
/// [AdminDashboardScreen]. Sessions restored by Firebase Auth skip login.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          return const AdminLoginScreen();
        }
        return _AdminVerifiedShell(uid: user.uid);
      },
    );
  }
}

class _AdminVerifiedShell extends StatefulWidget {
  const _AdminVerifiedShell({required this.uid});

  final String uid;

  @override
  State<_AdminVerifiedShell> createState() => _AdminVerifiedShellState();
}

class _AdminVerifiedShellState extends State<_AdminVerifiedShell> {
  bool _loading = true;
  bool _allowed = false;

  @override
  void initState() {
    super.initState();
    _verify();
  }

  Future<void> _verify() async {
    final doc = await FirebaseFirestore.instance
        .collection('admins')
        .doc(widget.uid)
        .get();

    if (!doc.exists) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        setState(() {
        _loading = false;
        _allowed = false;
      });
      }
      return;
    }
    final active = doc.data()?['active'];
    if (active == false) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        setState(() {
        _loading = false;
        _allowed = false;
      });
      }
      return;
    }
<<<<<<< HEAD
    final role = (doc.data()?['role'] ?? '').toString().trim().toLowerCase();
    if (role != 'admin') {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        setState(() {
          _loading = false;
          _allowed = false;
        });
      }
      return;
    }
=======
>>>>>>> a28bf1f775365ea426a204b88ca42cc04604a505
    if (mounted) {
      setState(() {
        _loading = false;
        _allowed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_allowed) {
      return const SizedBox.shrink();
    }
    return const AdminDashboardScreen();
  }
}
