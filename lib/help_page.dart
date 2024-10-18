import 'package:flutter/material.dart';
import 'profile_page.dart'; // Import the ProfilePage

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            ); // Navigate back to the ProfilePage
          },
        ),
      ),
      body: const Center(
        child: Text('Help information will be displayed here.'),
      ),
    );
  }
}
