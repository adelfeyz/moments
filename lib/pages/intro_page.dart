import 'package:flutter/material.dart';
import 'login_page.dart';

class IntroPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Blue app bar with menu, theme toggle and user icons
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 6, 154, 102),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () { /* open drawer */ },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.dark_mode),
            onPressed: () { /* toggle dark/light */ },
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () { /* profile */ },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 2. Curved‐bottom image header
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(80),
                    bottomRight: Radius.circular(80),
                  ),
                  child: Image.asset(
                    'assets/images/Slider_home.png',
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LoginPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 6, 154, 102),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 5,
                        ),
                        child: Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () {
                          // Handle sign up
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 185, 185, 185),
                          foregroundColor: const Color.fromARGB(221, 2, 47, 33),
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 5,
                        ),
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Welcome to Moments',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      'Preserve. Relive. Share.',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 6, 154, 102),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Life is made up of meaningful moments—spontaneous laughter, breathtaking views, unforgettable journeys, and voices that matter. With Moments, you can capture these memories effortlessly using text, voice, or video—and revisit them anytime, anywhere.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Whether you\'re recording your travels, funny stories with friends, or the little joys of everyday life, Moments transforms them into dynamic, beautiful stories you\'ll want to relive and share.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    '✨ What You Can Do:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 6, 154, 102),
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildFeatureItem(
                    Icons.record_voice_over,
                    'Speak or write your memories'
                  ),
                  _buildFeatureItem(
                    Icons.collections,
                    'Add photos, voices, and short clips'
                  ),
                  _buildFeatureItem(
                    Icons.auto_awesome,
                    'Let AI bring your moments to life with stories, timelines, and highlights'
                  ),
                  _buildFeatureItem(
                    Icons.group,
                    'Connect with the people who shared those memories with you'
                  ),
                  SizedBox(height: 40), // Add bottom padding
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Color.fromARGB(255, 6, 154, 102),
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
