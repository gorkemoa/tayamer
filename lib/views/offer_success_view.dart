import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'home_view.dart';

class OfferSuccessView extends StatefulWidget {
  final String message;
  final String title;

  const OfferSuccessView({
    Key? key, 
    required this.message,
    this.title = 'Teklif Oluşturuldu',
  }) : super(key: key);

  @override
  State<OfferSuccessView> createState() => _OfferSuccessViewState();
}

class _OfferSuccessViewState extends State<OfferSuccessView> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    // Sayfa açıldığında otomatik olarak konfeti patlat
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Geri tuşuna basıldığında ana sayfaya yönlendir
        _navigateToHome();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF1C3879)),
            onPressed: _navigateToHome,
          ),
          title: Text(
            widget.title,
            style: const TextStyle(
              color: Color(0xFF1C3879),
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            // Konfeti (çoklu efekt için birden fazla konfeti widget'ı)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2,
                maxBlastForce: 5,
                minBlastForce: 2,
                emissionFrequency: 0.05,
                numberOfParticles: 50,
                gravity: 0.2,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                  Colors.red,
                  Colors.yellow,
                ],
              ),
            ),
            
            // Sağ üstten konfeti
            Align(
              alignment: Alignment.topRight,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi, // sol yöne doğru
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.3,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                ],
              ),
            ),
            
            // Sol üstten konfeti
            Align(
              alignment: Alignment.topLeft,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: 0, // sağ yöne doğru
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.3,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                ],
              ),
            ),
            
            // İçerik
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Başarı ikonu
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green.shade700,
                        size: 80,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Başlık
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Color(0xFF1C3879),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    // Mesaj
                    Text(
                      widget.message,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    
                    // Ana sayfaya dön butonu
                    ElevatedButton(
                      onPressed: _navigateToHome,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1C3879),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Ana Sayfaya Dön',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => HomeView(),
        settings: const RouteSettings(arguments: 0),
      ),
      (route) => false,
    );
  }
} 