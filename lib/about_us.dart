import 'package:flutter/material.dart';
import 'profile_page.dart'; // Import the ProfilePage

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
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
        child: Text('Information about us will be displayed here.'),
      ),
    );
  }
}
