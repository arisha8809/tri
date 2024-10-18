import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore package

// Method to get the first name from Firestore using userId
Future<String?> getFirstName(String userId) async {
  try {
    // Reference the Firestore collection
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      // Fetch the 'name' field
      String fullName = userDoc.get('name');
      // Extract the first name from the full name
      String firstName = fullName.split(' ')[0]; // Split by space and get the first part
      return firstName;
    } else {
      return null; // User not found
    }
  } catch (e) {
    print('Error fetching user data: $e');
    return null;
  }
}
