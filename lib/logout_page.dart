import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase session termination
import 'package:tri/login_signup_page.dart'; // Ensure the path to login_signup_page.dart is correct

class LogoutPage extends StatefulWidget {
  const LogoutPage({super.key});

  @override
  LogoutPageState createState() => LogoutPageState();
}

class LogoutPageState extends State<LogoutPage> {
  
  @override
  void initState() {
    super.initState();
    // Immediately terminate the session and then redirect after a delay
    _logoutAndRedirect();
  }

  Future<void> _logoutAndRedirect() async {
    // Terminate the session by signing out the user
    await FirebaseAuth.instance.signOut();

    // Wait for 2-3 seconds before redirecting to the login page
    await Future.delayed(const Duration(seconds: 3));

    // Redirect to LoginPage and clear the navigation stack to prevent back navigation
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()), // Replace with your login/signup page
      (Route<dynamic> route) => false, // Remove all previous routes to prevent back navigation
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logged Out'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[
            Text('Logging Out...'),
            SizedBox(height: 20),
            // Show a loading indicator or a message while the redirect is about to happen
            CircularProgressIndicator(), // Optional loading indicator
          ],
        ),
      ),
    );
  }
}
