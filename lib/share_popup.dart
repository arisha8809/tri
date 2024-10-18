import 'package:flutter/material.dart';

class SharePopup extends StatelessWidget {
  const SharePopup({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black, // Match the background color in the design
      insetPadding: EdgeInsets.all(10), // Ensure it looks good on mobile
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // Rounded corners for dialog
      ),
      child: Container(
        padding: EdgeInsets.all(20), // Add padding inside the dialog
        child: Column(
          mainAxisSize: MainAxisSize.min, // Adjust size based on content
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Text(
                  'Share',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                SizedBox(width: 48), // To balance the close button width
              ],
            ),

            SizedBox(height: 20), // Add spacing

            // Main Content Area (Product Image and Name)
            Container(
              decoration: BoxDecoration(
                color: Colors.red[700], // Red background
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Placeholder for product image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.asset(
                      'assets/chocolate_cake.png', // Correct image path for the cake
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 10), // Space between image and text
                  Text(
                    'CHOCOLATE CAKE EKAANT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: 20), // Spacing between main content and share buttons

            // Share Buttons using image assets
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Snapchat button
                IconButton(
                  icon: Image.asset('assets/snapchat.png', height: 40, width: 40),
                  onPressed: () {
                    // Handle Snapchat share functionality
                  },
                ),
                
                // Pinterest button
                IconButton(
                  icon: Image.asset('assets/pinterest.png', height: 40, width: 40),
                  onPressed: () {
                    // Handle Pinterest share functionality
                  },
                ),
                
                // Facebook button
                IconButton(
                  icon: Image.asset('assets/facebook.png', height: 40, width: 40),
                  onPressed: () {
                    // Handle Facebook share functionality
                  },
                ),
                
                // WhatsApp button
                IconButton(
                  icon: Image.asset('assets/whatsapp.png', height: 40, width: 40),
                  onPressed: () {
                    // Handle WhatsApp share functionality
                  },
                ),
                
                // Telegram button
                IconButton(
                  icon: Image.asset('assets/telegram.png', height: 40, width: 40),
                  onPressed: () {
                    // Handle Telegram share functionality
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
