import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart' as mlkit;
import 'package:qr_code_scanner/qr_code_scanner.dart';
// import 'package:flutter/foundation.dart';

// QR tarayıcı kontrol bayrakları
bool _isQRPackageAvailable = true;

class QRScannerView extends StatefulWidget {
  /// Manuel giriş butonuna tıklandığında çağrılacak callback
  final VoidCallback? onManualEntry;
  
  /// QR kod sonucu elde edildiğinde çağrılacak callback
  final Function(Map<String, String>)? onResult;

  const QRScannerView({Key? key, this.onManualEntry, this.onResult}) : super(key: key);

  @override
  State<QRScannerView> createState() => _QRScannerViewState();
}

class _QRScannerViewState extends State<QRScannerView> with WidgetsBindingObserver {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isProcessing = false;
  bool _isDisposed = false;
  BuildContext? _storedContext;
  final ImagePicker _picker = ImagePicker();
  
  // Kamera kontrolü için ekstra bayrak
  bool _isCameraInitialized = false;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _storedContext = context;
  }
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isDisposed = false; // İlk başta false olarak ayarla
    print('DEBUG: QRScannerView initState çağrıldı');
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama arkaplanda veya öne geldiğinde kamerayı kontrol et
    print('DEBUG: AppLifecycleState değişti: $state');
    
    if (controller == null || _isDisposed) return;
    
    // Uygulamadan çıkıldığında kamerayı durdur
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      print('DEBUG: Uygulama arkaplan/duraklama durumuna geçti, kamera duruyor');
      _disposeCamera();
    }
    
    // Uygulama tekrar aktif olduğunda kamerayı yeniden başlat
    else if (state == AppLifecycleState.resumed && _isCameraInitialized) {
      print('DEBUG: Uygulama öne geldi, kamera yeniden başlatılıyor');
      _initializeCamera();
    }
  }
  
  // Kamerayı güvenli şekilde dispose et
  void _disposeCamera() {
    if (_isDisposed) return;
    
    try {
      print('DEBUG: Kamera durduruluyor...');
      controller?.pauseCamera();
    } catch (e) {
      print('DEBUG: Kamera durdurma hatası (güvenli): $e');
    }
  }
  
  // Kamerayı güvenli şekilde başlat
  void _initializeCamera() {
    if (_isDisposed || controller == null) return;
    
    try {
      print('DEBUG: Kamera başlatılıyor...');
      controller?.resumeCamera();
    } catch (e) {
      print('DEBUG: Kamera başlatma hatası (güvenli): $e');
    }
  }
  
  @override
  void dispose() {
    print('DEBUG: QRScannerView dispose çağrıldı');
    
    // Önce Observer'ı kaldır
    WidgetsBinding.instance.removeObserver(this);
    
    // Sonra kamerayı temizle (try-finally kullanarak)
    if (controller != null) {
      try {
        print('DEBUG: Kamera dispose ediliyor...');
        controller?.pauseCamera();
        controller?.dispose();
      } catch (e) {
        print('DEBUG: Controller dispose hatası: $e');
      } finally {
        controller = null;
      }
    }
    
    _isDisposed = true;
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    
    // Sıcak yeniden yükleme sırasında kamerayı durdurup yeniden başlat
    if (Platform.isAndroid && controller != null && !_isDisposed) {
      try {
        controller?.pauseCamera();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!_isDisposed && mounted && controller != null) {
            try {
              controller?.resumeCamera();
            } catch (e) {
              print('DEBUG: Kamera yeniden başlatma hatası: $e');
            }
          }
        });
      } catch (e) {
        print('DEBUG: Reassemble kamera hatası: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return const SizedBox.shrink();
    }
    return WillPopScope(
      // Geri tuşu işleyicisi
      onWillPop: () async {
        // Eğer işlem yapılıyorsa geri dönüşü engelle
        if (_isProcessing) return false;
        
        // Kamerayı güvenli bir şekilde durdur
        _disposeCamera();
        
        // Ana sayfaya dön
        _navigateToDashboard();
        
        // WillPopScope'un Navigator.pop yapmasını engelle
        return false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            // QR kod tarayıcı
            _buildQRView(),
            
            // Arayüz elemanları
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
                              // Ana sayfaya dön
                              _navigateToDashboard();
                            }
                          },
                        ),
                        const Expanded(
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
                          icon: const Icon(Icons.help_outline, color: Colors.white),
                          onPressed: () => _showHelpDialog(),
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
                          onPressed: () => _handleManualEntry(),
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
                          onPressed: () => _pickImage(),
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
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    if (_isDisposed) return;
    
    print('DEBUG: QR görünümü oluşturuldu, controller ayarlanıyor');
    // Controller'ı atama
    this.controller = controller;
    
    // Kameranın başlatılacağını belirt
    _isCameraInitialized = true;
    
    // Platform kontrolü
    if (Platform.isIOS) {
      // iOS için güvenli kamera başlatma
      _safeInitCameraForIOS(controller);
    } else {
      // Android için direkt başlat
      try {
        print('DEBUG: Android kamerası başlatılıyor');
        controller.resumeCamera();
      } catch (e) {
        print('DEBUG: Android kamera başlatma hatası: $e');
        if (!_isDisposed && mounted) {
          Future.microtask(() {
            // Hata dialogu yerine bilgilendirme mesajı gösteriyoruz
            _showError('Kamera başlatılamadı. Fotoğraf yükleme veya manuel giriş seçeneklerini kullanabilirsiniz.');
          });
        }
      }
    }
    
    // QR kod okuma listener'ı - zayıf referans kullan
    try {
      controller.scannedDataStream.listen(
        (scanData) {
          // İşlenip işlenmediğini kontrol et
          if (_isDisposed || !mounted || _isProcessing) return;
          
          _isProcessing = true;
          
          // QR veriyi işle
          final qrContent = scanData.code;
          print('DEBUG: QR içeriği alındı: $qrContent');
          
          if (qrContent != null) {
            // QR veriyi işle
            _processScannedQRContent(qrContent);
          } else {
            _isProcessing = false;
          }
        }, 
        onError: (error) {
          print('DEBUG: QR scanner hatası: $error');
          if (!_isDisposed && mounted) {
            _showError('QR tarayıcı hatası: $error');
          }
          _isProcessing = false;
        },
        cancelOnError: false,
      );
    } catch (e) {
      print('DEBUG: QR stream başlatma hatası: $e');
      if (!_isDisposed && mounted) {
        // Kamera başlatma hatası durumunda bilgilendirici mesaj göster
        Future.microtask(() {
          _showError('QR tarayıcısı çalıştırılamadı. Fotoğraf yükleme veya manuel giriş seçeneklerini kullanabilirsiniz.');
        });
      }
    }
  }
  
  // Platform özel kamera başlatma
  void _safeInitCameraForIOS(QRViewController controller) {
    try {
      print('DEBUG: iOS kamerası hazırlanıyor');
      controller.pauseCamera(); // Önce durdur
      
      if (!mounted || _isDisposed) return;
      
      // Zamanlayıcı ile kamerayı başlat
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted || _isDisposed) {
          print('DEBUG: iOS kamera başlatmadan önce widget dispose oldu');
          return;
        }
        
        try {
          print('DEBUG: iOS kamerası başlatılıyor');
          controller.resumeCamera();
        } catch (e) {
          print('DEBUG: iOS kamera başlatma hatası: $e');
          
          // Kamera hatası durumunda kullanıcıya bilgilendirici mesaj göster
          if (!_isDisposed && mounted) {
            Future.microtask(() {
              _showError('iOS kamerası başlatılamadı. Fotoğraf yükleme veya manuel giriş seçeneklerini kullanabilirsiniz.');
            });
          }
        }
      });
    } catch (e) {
      print('DEBUG: iOS kamera hazırlama hatası: $e');
      
      // Kamera hatası durumunda kullanıcıya bilgilendirici mesaj göster
      if (!_isDisposed && mounted) {
        Future.microtask(() {
          _showError('iOS kamerası hazırlanamadı. Fotoğraf yükleme veya manuel giriş seçeneklerini kullanabilirsiniz.');
        });
      }
    }
  }
  
  // Taranan QR içeriğini işle
  void _processScannedQRContent(String qrContent) {
    if (_isDisposed || !mounted) {
      _isProcessing = false;
      return;
    }
    
    try {
      // İşlemeden önce önce kamerayı durdur
      try {
        controller?.pauseCamera();
      } catch (e) {
        print('DEBUG: QR işleme öncesi kamera durdurma hatası: $e');
      }
      
      // Standart QR veri işleme
      _processQRContent(qrContent);
    } catch (e) {
      print('DEBUG: QR tarama işleme hatası: $e');
      _isProcessing = false;
    }
  }

  Future<void> _pickImage() async {
    if (_isDisposed || _isProcessing) return;

    try {
      _isProcessing = true;
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        // Görüntü kalitesini düşürerek performansı artırabilirsiniz
        imageQuality: 70, 
      );

      if (!mounted || _isDisposed) {
        _isProcessing = false;
        return;
      }

      if (image != null) {
        try {
          // QR kodunu doğrudan okumak için ML Kit Barcode Scanning kullanımı
          print('DEBUG: Fotoğraf seçildi, QR kodu taranıyor...');
          
          // Barcode Scanner oluştur
          final InputImage inputImage = InputImage.fromFilePath(image.path);
          final barcodeScanner = mlkit.BarcodeScanner(formats: [mlkit.BarcodeFormat.qrCode]);
          
          // Barcode taraması yap
          final List<mlkit.Barcode> barcodes = await barcodeScanner.processImage(inputImage);
          await barcodeScanner.close();
          
          // Eğer QR kod varsa işle
          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
            final String qrContent = barcodes.first.rawValue!;
            print('DEBUG: Fotoğraftan QR kod okundu: $qrContent');
            
            // QR bilgilerini işlemek için galleryMode bayrağını ekle
            Map<String, String> qrData = {};
            
            // URL mi diye kontrol et
            if (qrContent.startsWith('http://') || qrContent.startsWith('https://')) {
              try {
                // URL'yi parse et
                final uri = Uri.parse(qrContent);
                
                // Query parametrelerini al
                final params = uri.queryParameters;
                
                if (params.isNotEmpty) {
                  // Query parametrelerinden form alanları için veri çıkar
                  params.forEach((key, value) {
                    qrData[key] = value;
                  });
                  
                  print('DEBUG: URL verisi ayrıştırıldı: $qrData');
                } else {
                  // URL'de query parametresi yoksa ham URL'yi sakla
                  qrData['rawData'] = qrContent;
                  print('DEBUG: URL\'de parametre bulunamadı: $qrContent');
                }
              } catch (e) {
                // URL parse hatası durumunda ham içeriği sakla
                qrData['rawData'] = qrContent;
                print('DEBUG: URL ayrıştırma hatası: $e');
              }
            } 
            // Geleneksel format: RuhsatNo-Plaka-TC
            else if (qrContent.contains('-')) {
              final parts = qrContent.split('-');
              if (parts.length == 3) {
                qrData['ruhsatNo'] = parts[0].trim();
                qrData['plaka'] = parts[1].trim();
                qrData['tc'] = parts[2].trim();
                
                print('DEBUG: QR verisi ayrıştırıldı: RuhsatNo=${qrData['ruhsatNo']}, Plaka=${qrData['plaka']}, TC=${qrData['tc']}');
              } else {
                // Format uygun değilse ham veriyi sakla
                qrData['rawData'] = qrContent;
                print('DEBUG: Geçersiz QR format: $qrContent');
              }
            } 
            // Başka formatlar için
            else {
              // Ham veriyi sakla
              qrData['rawData'] = qrContent;
              print('DEBUG: Düz metin QR içeriği: $qrContent');
            }
            
            // Galeri modunda olduğunu belirt
            qrData['galleryMode'] = 'true';
            
            // Sonuçları işle ve sayfayı kapat
            if (widget.onResult != null) {
              widget.onResult!(qrData);
            } else {
              if (mounted) {
                Navigator.pop(context, qrData);
              }
            }
          } 
          // QR kod bulunamadı, yedek olarak Text Recognition dene
          else {
            print('DEBUG: QR kod bulunamadı, metin tanıma deneniyor...');
            
            // Metin tanımayı dene - bazı QR kodları metin olarak tanınabilir
            final textRecognizer = TextRecognizer();
            final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
            final String fullText = recognizedText.text;
            await textRecognizer.close();
            
            if (fullText.isNotEmpty) {
              print('DEBUG: Metin tanıma başarılı, içerik: $fullText');
              
              // QR veri işleme (yedek metod)
              Map<String, String> qrData = {};
              qrData['rawData'] = fullText;
              qrData['galleryMode'] = 'true';
              
              // Eğer format RuhsatNo-Plaka-TC ise tanı
              if (fullText.contains('-')) {
                final parts = fullText.split('-');
                if (parts.length == 3) {
                  qrData['ruhsatNo'] = parts[0].trim();
                  qrData['plaka'] = parts[1].trim();
                  qrData['tc'] = parts[2].trim();
                  
                  print('DEBUG: Metin ayrıştırıldı: RuhsatNo=${qrData['ruhsatNo']}, Plaka=${qrData['plaka']}, TC=${qrData['tc']}');
                }
              }
              
              // Sonuçları işle
              if (widget.onResult != null) {
                widget.onResult!(qrData);
              } else {
                if (mounted) {
                  Navigator.pop(context, qrData);
                }
              }
            } else {
              _showError('QR kod bulunamadı veya okunamadı. Daha net bir fotoğraf deneyin veya manuel giriş yapın.');
            }
          }
        } catch (e) {
          print('DEBUG: Fotoğraf QR okuma hatası: $e');
          _showError('QR kod okunamadı: $e');
        } finally {
          _isProcessing = false;
        }
      } else {
        _isProcessing = false;
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;
      _showError('Fotoğraf seçilirken hata oluştu: $e');
      _isProcessing = false;
    }
  }
  
  Future<void> _processQRContent(String content) async {
    if (_isDisposed || !mounted) {
      _isProcessing = false;
      return;
    }

    try {
      // Önce herhangi bir hata olmasın diye context erişimlerini güvence altına al
      final currentContext = context;
      if (!mounted || _isDisposed) {
        _isProcessing = false;
        return;
      }
      
      Map<String, String> qrData = {};
      
      // QR veri işleme (mevcut kodunuz)
      // URL mi diye kontrol et
      if (content.startsWith('http://') || content.startsWith('https://')) {
        try {
          // URL'yi parse et
          final uri = Uri.parse(content);
          
          // Query parametrelerini al
          final params = uri.queryParameters;
          
          if (params.isNotEmpty) {
            // Query parametrelerinden form alanları için veri çıkar
            params.forEach((key, value) {
              qrData[key] = value;
            });
            
            print('DEBUG: URL verisi ayrıştırıldı: $qrData');
          } else {
            // URL'de query parametresi yoksa ham URL'yi sakla
            qrData['rawData'] = content;
            print('DEBUG: URL\'de parametre bulunamadı: $content');
          }
        } catch (e) {
          // URL parse hatası durumunda ham içeriği sakla
          qrData['rawData'] = content;
          print('DEBUG: URL ayrıştırma hatası: $e');
        }
      } 
      // Geleneksel format: RuhsatNo-Plaka-TC
      else if (content.contains('-')) {
        final parts = content.split('-');
        if (parts.length == 3) {
          qrData['ruhsatNo'] = parts[0].trim(); // EK266102
          qrData['plaka'] = parts[1].trim();    // 06SS733
          qrData['tc'] = parts[2].trim();       // 4811012298
          
          print('DEBUG: QR verisi ayrıştırıldı: RuhsatNo=${qrData['ruhsatNo']}, Plaka=${qrData['plaka']}, TC=${qrData['tc']}');
        } else {
          // Format uygun değilse ham veriyi sakla
          qrData['rawData'] = content;
          print('DEBUG: Geçersiz QR format: $content');
        }
      } 
      // Başka formatlar için
      else {
        // Ham veriyi sakla
        qrData['rawData'] = content;
        print('DEBUG: Düz metin QR içeriği: $content');
      }
      
      // Fotoğraftan okuma özelliği
      if (content.contains('galleryMode')) {
        qrData['galleryMode'] = 'true';
      }

      print('DEBUG: QR işleme tamamlandı: $qrData');
      
      // Eğer callback tanımlıysa
      if (widget.onResult != null) {
        print('DEBUG: onResult callback kullanılıyor');
        
        // Context güvenli mi kontrol et
        if (mounted && !_isDisposed) {
          // Callback üzerinden veri dön
          widget.onResult!(qrData);
        }
      } else {
        // Context güvenli mi kontrol et
        if (mounted && !_isDisposed) {
          // Direkt olarak Navigator ile geri dön
          Navigator.pop(currentContext, qrData);
        }
      }
    } catch (e) {
      print('DEBUG: QR işleme hatası: $e');
      
      if (!_isDisposed && mounted) {
        _showError('QR kod işlenirken hata oluştu');
      }
    } finally {
      _isProcessing = false;
    }
  }

  // Güvenli SnackBar gösterimi
  void _showError(String message) {
    if (_isDisposed || !mounted) return;
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      print('DEBUG: SnackBar gösterme hatası: $e');
    }
  }

  // Manuel giriş butonuna basıldığında
  void _handleManualEntry() {
    if (_isDisposed) return;
    
    try {
      // Kamerayı güvenli şekilde temizle
      _disposeCamera();
      
      // Eğer onManualEntry callback tanımlanmışsa çağır
      if (widget.onManualEntry != null) {
        // QR tarayıcıyı kapat
        Navigator.of(context).pop();
        
        Future.microtask(() => widget.onManualEntry!());
      } else {
        // Callback tanımlı değilse ana sayfaya dön
        _navigateToDashboard();
      }
    } catch (e) {
      print('DEBUG: Manuel giriş hatası: $e');
      // Hata durumunda ana sayfaya dön
      _navigateToDashboard();
    }
  }
  
  // Yardım dialogu göster
  void _showHelpDialog() {
    if (_isDisposed) return;
    
    try {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: const Text('QR Kod Okutma Hakkında'),
          content: const Column(
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Anladım'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('DEBUG: Yardım dialog hatası: $e');
    }
  }
  
  // QR görünümü oluştur
  Widget _buildQRView() {
    try {
      print('DEBUG: QR görünümü oluşturuluyor');
      
      // QR paket kontrolü - bazı cihazlarda paketin yüklenmemesi durumuna karşı
      if (!_isQRPackageAvailable) {
        print('DEBUG: QR paketi kullanılamıyor, alternatif görünüm gösteriliyor');
        return _buildAlternativeQRView();
      }
      
      return QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
        overlay: QrScannerOverlayShape(
          borderColor: const Color(0xFF1C3879),
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: 250,
        ),
        onPermissionSet: (ctrl, permission) {
          print('DEBUG: Kamera izni durumu: $permission');
          if (!permission) {
            print('DEBUG: Kamera izni verilmedi.');
            // Kamera izni verilmediğinde hata dialogu göstermek yerine
            // ekranı karanlık bırakıp kullanıcıya mesaj gösteriyoruz
            // Kullanıcı isterse manuel giriş butonunu kendisi kullanabilir
            Future.microtask(() {
              if (!_isDisposed && mounted) {
                // Sadece bilgi mesajı göster
                _showError('Kamera izni verilmedi. Fotoğraf yükleme veya manuel giriş seçeneklerini kullanabilirsiniz.');
                
                // 3 saniye sonra ana sayfaya dön
                Future.delayed(const Duration(seconds: 3), () {
                  if (!_isDisposed && mounted) {
                    _navigateToDashboard();
                  }
                });
              }
            });
          }
        },
      );
    } catch (e) {
      print('DEBUG: QR görünümü oluşturma hatası: $e');
      // QR paketi sorunu olabilir, bayrağı güncelle
      _isQRPackageAvailable = false;
      
      // Alternatif görünüm göster
      return _buildAlternativeQRView();
    }
  }
  
  // Alternatif QR görünümü - qr_code_scanner paketi yüklenemediğinde gösterilir
  Widget _buildAlternativeQRView() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && !_isDisposed) {
        _showQRPackageErrorDialog();
      }
    });
    
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text(
              'QR tarayıcı hazırlanıyor...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
  
  // QR paketi hatası durumunda gösterilecek dialog
  void _showQRPackageErrorDialog() {
    if (_isDisposed || !mounted) return;
    
    try {
      // Zorla kapatmak yerine bilgilendirici mesaj göster
      _showError('QR tarayıcı kullanılamıyor. Lütfen fotoğraf yükleme veya manuel giriş seçeneklerini kullanın.');
      
      // 3 saniye sonra ana sayfaya dön
      Future.delayed(const Duration(seconds: 3), () {
        if (!_isDisposed && mounted) {
          _navigateToDashboard();
        }
      });
    } catch (e) {
      print('DEBUG: QR paketi hata mesajı gösterme hatası: $e');
    }
  }

  // Ana sayfaya (Dashboard) dönüş metodu
  void _navigateToDashboard() {
    if (_isDisposed || !mounted) return;
    
    try {
      // Kamerayı güvenli şekilde kapat
      _disposeCamera();
      
      // UI thread'i için Future.microtask kullan
      Future.microtask(() {
        if (mounted) {
          // Tüm route'ları temizleyerek ana sayfaya dön
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        }
      });
    } catch (e) {
      print('DEBUG: Ana sayfaya dönüş hatası: $e');
    }
  }
} 