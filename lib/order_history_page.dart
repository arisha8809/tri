import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For fetching the logged-in user

class OrderHistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get the current logged-in user's ID
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text("Order History"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('orderHistory') // Query from user's order history
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error fetching orders. Please try again later.')); // Improved error handling message
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No order history available.'));
          }

          // List of order items from Firestore
          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final items = List<Map<String, dynamic>>.from(order['items']); // Fetching items from Firestore

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items.map((item) {
                  // Extracting values with null checks and default values if needed
                  String dishName = item['dishName'] ?? 'Dish Not Available';
                  String hotelName = item['hotelName'] ?? 'Hotel Not Available';
                  String price = (item['price'] != null) ? item['price'].toString() : '0';
                  bool isVeg = item['isVeg'] ?? true;
                  String date = (order['orderDate'] != null) 
                                ? order['orderDate'].toDate().toString() 
                                : 'Date Not Available';

                  return buildOrderItem(
                    context,
                    dishName: dishName,
                    hotelName: hotelName,
                    price: price,
                    isVeg: isVeg,
                    date: date,
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }

  // Function to build the layout of each order item
  Widget buildOrderItem(
    BuildContext context, {
    required String dishName,
    required String hotelName,
    required String price,
    required bool isVeg,
    required String date,
  }) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dish Image Placeholder (Assuming a placeholder image or a network image URL)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                image: DecorationImage(
                  image: AssetImage('assets/food_placeholder.png'), // Replace with your image asset
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 16),
            // Dish and hotel info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dish Name
                  Text(
                    dishName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  // Hotel Name
                  Text(
                    hotelName,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  // Price and Veg/Non-Veg Symbol
                  Row(
                    children: [
                      Text(
                        '₹$price',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(width: 8),
                      // Veg/Non-Veg Icon placed below price
                      Icon(
                        isVeg ? Icons.stop_circle : Icons.stop_circle_outlined,
                        color: isVeg ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
