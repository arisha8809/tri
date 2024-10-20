import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth for the current user
import 'package:tri/order_history_page.dart'; // Import OrderHistoryPage
import 'package:tri/about_us.dart'; // Import About Us Page
import 'package:tri/favourites_page.dart'; // Import Favourites Page
import 'package:tri/home_page.dart'; // Import Home Page
import 'package:tri/help_page.dart'; // Import Help Page
import 'package:tri/logout_page.dart'; // Import Logout Page
import 'user_service.dart' as user_service;  // Import user_service if needed for user-specific logic

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final int _currentIndex = 2; // Highlight Profile icon

  Future<String?> _fetchUserFullName() async {
    User? currentUser = FirebaseAuth.instance.currentUser; // Get the current authenticated user
    if (currentUser != null) {
      String? fullName = await getFullName(currentUser.uid); // Fetch full name from Firestore
      return fullName;
    }
    return null; // Return null if user is not authenticated
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Page'),
      ),
      body: FutureBuilder<String?>(
        future: _fetchUserFullName(), // Fetch the full name
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a loading spinner while waiting for the data
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Handle any errors
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            // If no data, show a fallback message
            return const Center(child: Text('User not found'));
          }

          // Once the data is available, display the profile UI
          String fullName = snapshot.data!; // Get the full name

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Profile Picture in Triangle shape
                ClipPath(
                  clipper: TriangleClipper(),
                  child: Image.asset(
                    'assets/profile_picture.png', // Ensure to use your own image path
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                // Display the fetched full name
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                // Navigation ListTiles
                ListTile(
                  title: const Text('Order History'),
                  onTap: () {
                    // Navigate to the Order History Page using push, not pushReplacement
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => OrderHistoryPage()), // Correct navigation with push
                    );
                  },
                ),
                ListTile(
                  title: const Text('About Us'),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => AboutUsPage()),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Help'),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HelpPage()),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Log Out'),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LogoutPage()),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, // Highlight the Profile icon
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favourites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => FavouritesPage()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
              break;
            case 2:
              // Stay on Profile Page
              break;
          }
        },
      ),
    );
  }
}

// Triangle clipper for profile picture
class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Function to fetch the full name from Firestore
Future<String?> getFullName(String userId) async {
  try {
    // Reference the Firestore collection
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      // Fetch the 'username' field
      String fullName = userDoc.get('username');
      return fullName; // Return the full name
    } else {
      return null; // User not found
    }
  } catch (e) {
    print('Error fetching user data: $e');
    return null;
  }
}
