import 'package:flutter/material.dart';

import '../../core/booking_background.dart';

class CenterActionScreen extends StatelessWidget {
  const CenterActionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text('Bambare'),
      ),
      extendBodyBehindAppBar: true,
      body: const BookingBackgroundLayer(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Quick actions and featured services can go here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
