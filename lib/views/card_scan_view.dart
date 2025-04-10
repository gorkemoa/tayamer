import 'package:card_scanner/card_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'card_form_view.dart';

// Kart tarama işlemi ile başlayan ekran
class CardScanView extends StatefulWidget {
  final String detailUrl;
  final int offerId;
  final int companyId;
  final String holderTC;
  final String holderBD;
  final int maxInstallment;

  const CardScanView({
    Key? key,
    required this.detailUrl,
    required this.offerId,
    required this.companyId,
    required this.holderTC,
    required this.holderBD,
    this.maxInstallment = 1,
  }) : super(key: key);

  @override
  State<CardScanView> createState() => _CardScanViewState();
}

class _CardScanViewState extends State<CardScanView> {
  bool _isLoading = false;
  bool _permissionDenied = false;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında hemen kamera izinlerini kontrol et ve taramayı başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initState içinde doğrudan çağırmak yerine postFrameCallback kullanıyoruz
      _checkCameraPermission();
    });
  }
  
  // Kamera izinlerini kontrol et
  Future<void> _checkCameraPermission() async {
    try {
      // Önce mevcut durumu kontrol et
      final status = await Permission.camera.status;
      
      if (status.isGranted) {
        // İzin zaten verilmiş, taramayı hemen başlat
        if (mounted) {
          _startCardScan();
        }
        return;
      }
      
      // İzin durumunu kontrol et ve açık bir şekilde iste
      final result = await Permission.camera.request();
      
      if (mounted) {
        if (result.isGranted) {
          // İzin alındı, taramayı başlat
          _startCardScan();
        } else if (result.isPermanentlyDenied) {
          // Kullanıcı kalıcı olarak reddetti
          setState(() {
            _permissionDenied = true;
          });
        } else {
          // Normal ret durumu
          setState(() {
            _permissionDenied = true;
          });
        }
      }
    } catch (e) {
      debugPrint('İzin kontrolü sırasında hata: $e');
      // Hata durumunda manuel form göster
      if (mounted) {
        setState(() {
          _permissionDenied = true;
        });
      }
    }
  }

  // Kart tarama işlemini başlat
  Future<void> _startCardScan() async {
    if (_scanning) return;

    setState(() {
      _scanning = true;
    });

    try {
      // Tarama işlemini başlatmadan önce ek kontrol
      final cameraStatus = await Permission.camera.status;
      if (!cameraStatus.isGranted) {
        if (mounted) {
          setState(() {
            _scanning = false;
            _permissionDenied = true;
          });
        }
        return;
      }
      
      // card_scanner paketi doğrudan kullanılıyor
      debugPrint('Kart taraması başlatılıyor...');
      
      final CardDetails? cardDetails = await CardScanner.scanCard();
      debugPrint('Kart tarama tamamlandı: ${cardDetails != null ? "Başarılı" : "Başarısız"}');
      
      if (mounted) {
        if (cardDetails != null) {
          debugPrint('Kart numarası: ${cardDetails.cardNumber ?? "Bulunamadı"}');
          debugPrint('Son kullanma tarihi: ${cardDetails.expiryDate ?? "Bulunamadı"}');
          debugPrint('Kart sahibi: ${cardDetails.cardHolderName ?? "Bulunamadı"}');
          
          // Tarama başarılı oldu, manuel form ekranına geç
          _navigateToManualEntry(cardDetails);
        } else {
          // Tarama iptal edildi veya başarısız oldu
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kart taraması iptal edildi veya tamamlanamadı.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      debugPrint('Kart tarama platform hatası: ${e.message}, Kod: ${e.code}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kart tarama işlemi sırasında hata: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Kart tarama genel hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kart tarama sırasında hata oluştu. Manuel girişi deneyebilirsiniz.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _scanning = false;
        });
      }
    }
  }

  // Manuel giriş ekranına geçiş
  void _navigateToManualEntry(CardDetails? scanResult) {
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(
        builder: (context) => CardManualEntryView(
          detailUrl: widget.detailUrl,
          offerId: widget.offerId,
          companyId: widget.companyId,
          holderTC: widget.holderTC,
          holderBD: widget.holderBD,
          maxInstallment: widget.maxInstallment,
          cardNumber: scanResult?.cardNumber,
          cardHolder: scanResult?.cardHolderName,
          expiryDate: scanResult?.expiryDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // İzin reddedilmişse yönlendirme ekranı göster
    if (_permissionDenied) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Kamera İzni Gerekli'),
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _navigateToManualEntry(null),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.camera_alt_outlined,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Kart tarama işlemi için kamera izni gereklidir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    await openAppSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    backgroundColor: const Color(0xFF1E3A8A),
                  ),
                  child: const Text('Ayarları Aç', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => _navigateToManualEntry(null),
                  child: const Text('Manuel Bilgi Girişi Yap'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Kart tarama ekranı
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        title: const Text('Kartınızı Okutun'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _navigateToManualEntry(null),
        ),
      ),
      body: Column(
        children: [
          // Tarama alanı (ekranın büyük kısmını kaplayacak)
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _startCardScan,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Kamera görüntüsü temsili alanı
                      Container(
                        width: double.infinity,
                        height: 250, // Tarama alanı yüksekliği
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _scanning 
                          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                          : const Center(
                              child: Icon(
                                Icons.credit_card,
                                size: 80,
                                color: Colors.black26,
                              ),
                            ),
                      ),
                      
                      // Mavi çerçeve
                      Container(
                        width: double.infinity,
                        height: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blue,
                            width: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Alt kısım - Manuel Giriş butonu
          Container(
            padding: const EdgeInsets.all(20),
            child: TextButton(
              onPressed: () => _navigateToManualEntry(null),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                foregroundColor: const Color(0xFF1E3A8A),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('Manuel Giriş'),
            ),
          ),
          const SizedBox(height: 20), // Ekranın alt kısmında biraz boşluk bırak
        ],
      ),
    );
  }
} 