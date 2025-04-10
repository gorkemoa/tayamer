import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3A73), // Uygulamanın birincil rengi
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/images/tayamer-logo.png',
              color: Colors.white,
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 30),
            // Yükleme göstergesi
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 20),
            // Yükleniyor yazısı
            
          ],
        ),
      ),
    );
  }
} 