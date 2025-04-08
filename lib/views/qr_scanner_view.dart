import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
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
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isProcessing = false; // QR kodu işleniyor mu?
  bool _isDisposed = false; // Widget dispose edildi mi?
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isDisposed = true;
    controller?.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null) {
        _handleQRDetection(context, scanData);
      }
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama arka plana gittiğinde veya öne çıktığında kamera durumunu ayarla
    if (state == AppLifecycleState.resumed) {
      controller?.resumeCamera();
    } else if (state == AppLifecycleState.inactive || 
              state == AppLifecycleState.paused || 
              state == AppLifecycleState.detached) {
      controller?.pauseCamera();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: const Color(0xFF1C3879),
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: MediaQuery.of(context).size.width * 0.8,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Mavi başlık çubuğu
                Container(
                  color: const Color(0xFF1C3879),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.help_outline, color: Colors.white),
                        onPressed: () {
                          if (_isDisposed) return;
                          // Yardım bilgisi göster
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('QR Kod Okutma Hakkında'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
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
                                  child: const Text('Anladım'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const Spacer(), // Kamera alanı için boşluk
                
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
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                        child: const Text('Manuel Giriş'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                            controller?.pauseCamera();
                            
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
                        child: const Text('Fotoğraf Yükle'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleQRDetection(BuildContext context, Barcode scanData) {
    // Eğer zaten işleme devam ediyorsa veya widget dispose olduysa işlem yapma
    if (_isProcessing || _isDisposed) return;
    
    try {
      _isProcessing = true; // İşleme başladı
      
      // QR kod algılandığında yapılacak işlemler
      final String code = scanData.code ?? '';
      
      // Boş kod kontrolü
      if (code.isEmpty) {
        print('Boş QR kod içeriği');
        _isProcessing = false;
        return;
      }
      
      // *** EKLENDİ: Okunan ham QR kod verisini logla ***
      print('[QRScannerView] Raw QR Code: $code');
      
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
      controller?.pauseCamera();
      
      Map<String, dynamic> qrData = {};
      
      // JSON formatında veri geldiğini varsayıyoruz
      try {
        // JSON dönüşüm hatalarını yakala
        if (code.trim().startsWith('{') && code.trim().endsWith('}')) {
          qrData = jsonDecode(code);
          // *** EKLENDİ: JSON olarak ayrıştırılan veriyi logla ***
          print('[QRScannerView] Parsed JSON data: $qrData');
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
            // *** EKLENDİ: Anahtar=Değer olarak ayrıştırılan veriyi logla ***
            print('[QRScannerView] Parsed Key-Value data: $qrData');
          }
          
          // Eğer veri ayrıştırılamadıysa, ham veriyi ekle
          if (qrData.isEmpty) {
            qrData['rawData'] = code;
            // *** EKLENDİ: Ham veri olarak işaretlenen veriyi logla ***
            print('[QRScannerView] Marked as rawData: $qrData');
          }
        }
      } catch(e) {
        print('QR kod işleme hatası: $e');
        qrData['rawData'] = code;
        // *** EKLENDİ: Hata durumunda ham veriyi logla ***
        print('[QRScannerView] Error parsing, marked as rawData: $qrData');
      }
      
      // Future.microtask kullanarak navigator pop işlemini UI thread'inden sonraya ertele
      Future.microtask(() {
        if (!_isDisposed && mounted) {
          // *** EKLENDİ: Geri gönderilecek veriyi logla ***
          print('[QRScannerView] Popping with data: $qrData');
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