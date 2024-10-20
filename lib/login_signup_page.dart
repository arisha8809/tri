import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore package
import 'dart:math'; // For the triangle animation
import 'home_page.dart'; // Import the home page after successful login

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance; // Firestore instance

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  String welcomeText = "WELCOME!";
  List<String> translations = [
    "WELCOME!", "स्वागत है!", "സ്വാഗതം!", "ಸ್ವಾಗತ", 
    "வரவேற்கிறோம்!", "स्वागत आहे!", "ਸੁਆਗਤ ਹੈ!", "স্বাগতম!"
  ];
  int currentTranslationIndex = 0;
  bool showErrorMessages = false;
  bool isLogin = true; // Flag to toggle between login and signup
  bool loading = false; // Flag for loading state

  @override
  void initState() {
    super.initState();
    startWelcomeTextTransition();
  }

  void startWelcomeTextTransition() {
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        currentTranslationIndex = (currentTranslationIndex + 1) % translations.length;
        welcomeText = translations[currentTranslationIndex];
      });
      startWelcomeTextTransition();
    });
  }

  Future<void> login() async {
    setState(() {
      loading = true; // Start loading
    });

    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      setState(() {
        showErrorMessages = true;
        loading = false; // Stop loading
      });
      return;
    }

    if (password.isEmpty || password.length < 6) {
      setState(() {
        showErrorMessages = true;
        loading = false; // Stop loading
      });
      return;
    }

    try {
      UserCredential userCredential = await auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        showErrorDialog("Please verify your email.");
      } else {
        // Fetch user data from Firestore
        DocumentSnapshot userDoc = await firestore.collection('users').doc(user?.uid).get();

        if (userDoc.exists) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
        } else {
          showErrorDialog("User not found in Firestore.");
        }
      }
    } catch (e) {
      showErrorDialog(e.toString());
    } finally {
      setState(() {
        loading = false; // Stop loading
      });
    }
  }

  Future<void> signUp() async {
    setState(() {
      loading = true; // Start loading
    });

    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();
    String fullName = fullNameController.text.trim();
    String phoneNumber = phoneController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty || password != confirmPassword) {
      setState(() {
        showErrorMessages = true;
        loading = false; // Stop loading
      });
      return;
    }

    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        // Add user details to Firestore
        await firestore.collection('users').doc(user.uid).set({
          'userId': user.uid,
          'username': fullName,
          'email': user.email,
          'phone_number': phoneNumber,
          'created_on': DateTime.now(),
          'is_email_verified': user.emailVerified,
          'role': 'customer',
          'status': 'active',
          'address': '', // You can add address if needed later
        });

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
      }
    } catch (e) {
      showErrorDialog(e.toString());
    } finally {
      setState(() {
        loading = false; // Stop loading
      });
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              // Image and welcome text
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                color: const Color.fromARGB(255, 255, 255, 255),
                child: Column(
                  children: [
                    Image.asset('assets/triangle_image.png', height: 150),
                    Text(welcomeText, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Full Name (Visible only in Signup mode)
              if (!isLogin)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Full Name *'),
                    TextField(
                      controller: fullNameController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your full name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              // Phone (Visible only in Signup mode)
              if (!isLogin)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Phone Number *'),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your phone number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              // Email Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Email *'),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: 'for example: ab@xyz.christuniversity.in',
                      border: const OutlineInputBorder(),
                      errorText: showErrorMessages && emailController.text.isEmpty
                          ? 'Enter a valid email'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Password Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Password *'),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'must contain at least 6 characters',
                      border: const OutlineInputBorder(),
                      errorText: showErrorMessages && passwordController.text.length < 6
                          ? 'Password too short'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Confirm Password (Visible only in Signup mode)
              if (!isLogin)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Confirm Password *'),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        errorText: showErrorMessages &&
                                confirmPasswordController.text != passwordController.text
                            ? 'Passwords do not match'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              // Loading indicator when processing login/signup
              if (loading)
                const TriangleRotationAnimation(), // Use the triangle loading animation
              const SizedBox(height: 16),

              // Log In or Sign Up Button
              if (!loading)
                ElevatedButton(
                  onPressed: isLogin ? login : signUp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  child: Text(isLogin ? 'Log In' : 'Sign Up'),
                ),
              const SizedBox(height: 16),

              // Toggle between Log In and Sign Up
              if (!loading)
                TextButton(
                  onPressed: () {
                    setState(() {
                      isLogin = !isLogin; // Toggle login and signup
                                       });
                                },
                                child: Text(isLogin ? 'Don\'t have an account? Sign Up' : 'Already have an account? Log In'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                }

// Triangle rotation animation for loading
class TriangleRotationAnimation extends StatefulWidget {
  const TriangleRotationAnimation({super.key});

  @override
  _TriangleRotationAnimationState createState() => _TriangleRotationAnimationState();
}

class _TriangleRotationAnimationState extends State<TriangleRotationAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(); // Start the triangle rotation
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: CustomPaint(
        size: const Size(80, 80), // Size of the triangle
        painter: TrianglePainter(),
      ),
    );
  }
}

// Custom painter for drawing the triangle
class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.green // You can change the color of the triangle here
      ..style = PaintingStyle.fill;

    final Path path = Path();
    path.moveTo(size.width / 2, 0); // Start at the top center
    path.lineTo(size.width, size.height); // Draw to the bottom right
    path.lineTo(0, size.height); // Draw to the bottom left
    path.close(); // Close the triangle path

    canvas.drawPath(path, paint); // Draw the triangle
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false; // No need to repaint as the triangle stays the same
  }
}
