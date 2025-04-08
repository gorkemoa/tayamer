import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../viewmodels/policy_type_viewmodel.dart';
import 'dart:convert';

class QRScannerView extends StatefulWidget {
  /// Manuel giriş butonuna tıklandığında çağrılacak callback
  final VoidCallback? onManualEntry;

  const QRScannerView({Key? key, this.onManualEntry}) : super(key: key);

  @override
  State<QRScannerView> createState() => _QRScannerViewState();
}

class _QRScannerViewState extends State<QRScannerView> with WidgetsBindingObserver {
  late MobileScannerController controller;
  bool _isProcessing = false; // QR kodu işleniyor mu?
  bool _isDisposed = false; // Widget dispose edildi mi?
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = MobileScannerController();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isDisposed = true;
    controller.dispose();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama arka plana gittiğinde veya öne çıktığında kamera durumunu ayarla
    if (state == AppLifecycleState.resumed) {
      controller.start();
    } else if (state == AppLifecycleState.inactive || 
              state == AppLifecycleState.paused || 
              state == AppLifecycleState.detached) {
      controller.stop();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) => _handleQRDetection(context, capture),
          ),
          SafeArea(
            child: Column(
              children: [
                // Mavi başlık çubuğu
                Container(
                  color: Color(0xFF1C3879),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          if (!_isDisposed) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                      Expanded(
                        child: Text(
                          'QR Kodunuzu Okutun',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.help_outline, color: Colors.white),
                        onPressed: () {
                          if (_isDisposed) return;
                          // Yardım bilgisi göster
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('QR Kod Okutma Hakkında'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('QR kodunuzu kameranın görüş alanında tutun.'),
                                  SizedBox(height: 8),
                                  Text('Otomatik olarak aşağıdaki bilgilerinizi algılayabilir:'),
                                  SizedBox(height: 8),
                                  Text('• Plaka'),
                                  Text('• TC Kimlik Numarası'),
                                  Text('• Ruhsat Numarası'),
                                  SizedBox(height: 8),
                                  Text('Diğer bilgileri manuel olarak tamamlayabilirsiniz.'),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Anladım'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                Spacer(), // Kamera alanı için boşluk
                
                // Alt butonlar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () {
                          if (_isDisposed) return;
                          // QR tarayıcıyı kapat
                          Navigator.of(context).pop();
                          // Eğer onManualEntry callback tanımlanmışsa çağır
                          if (widget.onManualEntry != null) {
                            widget.onManualEntry!();
                          }
                        },
                        child: Text('Manuel Giriş'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () async {
                          if (_isDisposed) return;
                          
                          // Galeriden fotoğraf seçme
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                          
                          // Widget devre dışı kalmış olabilir, kontrol et
                          if (_isDisposed) return;
                          
                          if (image != null && mounted) {
                            // Kullanıcıya bilgi ver
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Fotoğraftan QR kod taranıyor...'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            
                            // Controller'a özel bir durumda olduğumuzu belirtelim
                            await controller.stop();
                            
                            // Widget hala aktif mi kontrol et
                            if (_isDisposed) return;
                            
                            // Temel bilgilerle popla
                            Navigator.of(context).pop({
                              'plaka': '',
                              'tc': '',
                              'ruhsatNo': '',
                              'galleryMode': true
                            });
                          }
                        },
                        child: Text('Fotoğraf Yükle'),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleQRDetection(BuildContext context, BarcodeCapture capture) {
    // Eğer zaten işleme devam ediyorsa veya widget dispose olduysa işlem yapma
    if (_isProcessing || _isDisposed) return;
    
    try {
      _isProcessing = true; // İşleme başladı
      
      final List<Barcode> barcodes = capture.barcodes;
      if (barcodes.isEmpty) {
        _isProcessing = false;
        return;
      }
      
      // QR kod algılandığında yapılacak işlemler
      final String code = barcodes.first.rawValue ?? '';
      
      // Boş kod kontrolü
      if (code.isEmpty) {
        print('Boş QR kod içeriği');
        _isProcessing = false;
        return;
      }
      
      // Widget hala aktif mi? Mounted kontrolü
      if (_isDisposed) {
        _isProcessing = false;
        return;
      }
      
      // Okuma başarılı olduğunda bildirim göster
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR kod okundu, işleniyor...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      // QR tarayıcıyı durdur
      controller.stop();
      
      Map<String, dynamic> qrData = {};
      
      // JSON formatında veri geldiğini varsayıyoruz
      try {
        // JSON dönüşüm hatalarını yakala
        if (code.trim().startsWith('{') && code.trim().endsWith('}')) {
          qrData = jsonDecode(code);
        } else {
          // JSON formatında değilse, ham veriyi analiz et
          // QR kod içeriğinde anahtar=değer formatı olup olmadığını kontrol et
          if (code.contains('=')) {
            // Anahtar=değer çiftlerini ayır
            List<String> pairs = code.split('&');
            for (String pair in pairs) {
              List<String> keyValue = pair.split('=');
              if (keyValue.length == 2) {
                qrData[keyValue[0].trim()] = keyValue[1].trim();
              }
            }
          }
          
          // Eğer veri ayrıştırılamadıysa, ham veriyi ekle
          if (qrData.isEmpty) {
            qrData['rawData'] = code;
          }
        }
      } catch(e) {
        print('QR kod işleme hatası: $e');
        qrData['rawData'] = code;
      }
      
      // Future.microtask kullanarak navigator pop işlemini UI thread'inden sonraya ertele
      Future.microtask(() {
        if (!_isDisposed && mounted) {
          // Navigator.pop ile veriyi geri döndür
          Navigator.of(context).pop(qrData);
        }
      });
      
    } catch (e) {
      print('QR tarama genel hatası: $e');
      
      // Hata durumunda - mounted kontrolü
      if (!_isDisposed && mounted) {
        // Kullanıcıya bilgi ver
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR kod taranırken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      _isProcessing = false;
    }
  }
} 