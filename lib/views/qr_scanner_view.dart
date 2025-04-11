import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:mobile_scanner/mobile_scanner.dart' as mobile_scanner;
import 'package:permission_handler/permission_handler.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

// QR tarayıcı köşe kutusu widget'ı
class _CornerBox extends StatelessWidget {
  final bool isTopLeft;
  final bool isTopRight;
  final bool isBottomLeft;
  final bool isBottomRight;
  
  const _CornerBox({
    Key? key,
    this.isTopLeft = false,
    this.isTopRight = false,
    this.isBottomLeft = false,
    this.isBottomRight = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border(
          left: isTopLeft || isBottomLeft 
              ? const BorderSide(color: Color(0xFF1C3879), width: 3)
              : BorderSide.none,
          top: isTopLeft || isTopRight 
              ? const BorderSide(color: Color(0xFF1C3879), width: 3)
              : BorderSide.none,
          right: isTopRight || isBottomRight 
              ? const BorderSide(color: Color(0xFF1C3879), width: 3)
              : BorderSide.none,
          bottom: isBottomLeft || isBottomRight 
              ? const BorderSide(color: Color(0xFF1C3879), width: 3)
              : BorderSide.none,
        ),
      ),
    );
  }
}

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
  mobile_scanner.MobileScannerController? controller;
  bool _isProcessing = false;
  bool _isDisposed = false;
  final ImagePicker _picker = ImagePicker();
  
  // Kamera kontrolü için bayraklar
  bool _isCameraInitialized = false;
  bool _isCameraPermissionDenied = false;
  bool _isCameraPermissionRequested = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isDisposed = false;
    
    // Kamera izni kontrolü ve başlatma
    _checkCameraPermission();
  }
  
  // Kamera iznini kontrol et ve gerekirse iste
  Future<void> _checkCameraPermission() async {
    try {
      // Kamera izni kontrolü
      var status = await Permission.camera.status;
      
      // İzin durumuna göre işlem yap
      if (status.isGranted) {
        // İzin verilmiş, kamerayı başlat
        _initializeMobileScanner();
      } else if (status.isDenied && !_isCameraPermissionRequested) {
        // İzin istenmemiş veya reddedilmiş, izin iste
        _isCameraPermissionRequested = true;
        
        status = await Permission.camera.request();
        
        if (status.isGranted) {
          // İzin alındı, kamerayı başlat
          if (mounted) {
            setState(() {
              _isCameraPermissionDenied = false;
            });
            _initializeMobileScanner();
          }
        } else {
          // İzin reddedildi
          if (mounted) {
            setState(() {
              _isCameraPermissionDenied = true;
            });
          }
        }
      } else {
        // İzin kalıcı olarak reddedilmiş
        if (mounted) {
          setState(() {
            _isCameraPermissionDenied = true;
          });
        }
      }
    } catch (e) {
      // Hata durumunda kamera erişilemez olarak işaretle
      if (mounted) {
        setState(() {
          _isCameraPermissionDenied = true;
        });
      }
    }
  }
  
  void _initializeMobileScanner() {
    try {
      controller = mobile_scanner.MobileScannerController(
        facing: mobile_scanner.CameraFacing.back,
        torchEnabled: false,
        returnImage: true,
      );
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isCameraPermissionDenied = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _isCameraPermissionDenied = true;
        });
      }
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (controller == null || _isDisposed) return;
    
    // Uygulamadan çıkıldığında kamerayı durdur
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _disposeCamera();
    }
    
    // Uygulama tekrar aktif olduğunda kamerayı yeniden başlat
    else if (state == AppLifecycleState.resumed && _isCameraInitialized) {
      _initializeCamera();
    }
  }
  
  // Kamerayı güvenli şekilde dispose et
  void _disposeCamera() {
    if (_isDisposed) return;
    
    try {
      if (controller == null || !_isCameraInitialized) {
        return;
      }
      
      try {
        controller?.stop();
      } catch (e) {
        // Hata durumunu sessizce geç
      }
    } catch (e) {
      // Hata durumunu sessizce geç
    }
  }
  
  // Kamerayı güvenli şekilde başlat
  void _initializeCamera() {
    if (_isDisposed || controller == null) return;
    
    try {
      controller?.start();
    } catch (e) {
      // Hata durumunda kamera erişilemez olarak işaretle
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _isCameraPermissionDenied = true;
        });
      }
    }
  }
  
  @override
  void dispose() {
    // Önce Observer'ı kaldır
    WidgetsBinding.instance.removeObserver(this);
    
    // Sonra kamerayı temizle
    if (controller != null) {
      try {
        controller?.stop();
        controller?.dispose();
      } catch (e) {
        // Hata durumunu sessizce geç
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
        controller?.stop();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!_isDisposed && mounted && controller != null) {
            controller?.start();
          }
        });
      } catch (e) {
        // Hata durumunu sessizce geç
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return const SizedBox.shrink();
    }
    return WillPopScope(
      onWillPop: () async {
        if (_isProcessing) return false;
        _disposeCamera();
        return true;
      },
      child: Scaffold(
        body: Stack(
          children: [
            // QR kod tarayıcı veya kamera izni yoksa alternatif görünüm
            if (_isCameraPermissionDenied || !_isCameraInitialized)
              _buildCameraUnavailableView()
            else
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
                              _disposeCamera();
                              Navigator.of(context).pop();
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
                  
                  // Alt butonlar - Kamera izni yoksa bu kısmı gösterme (tam ekran CameraUnavailable görünümünü tercih et)
                  if (!_isCameraPermissionDenied && _isCameraInitialized)
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

  // Taranan QR içeriğini işle
  void _processScannedQRContent(String qrContent) {
    if (_isDisposed || !mounted) {
      _isProcessing = false;
      return;
    }
    
    try {
      controller?.stop();
      _processQRContent(qrContent);
    } catch (e) {
      _isProcessing = false;
    }
  }

  Future<void> _pickImage() async {
    if (_isDisposed || _isProcessing || !mounted) return;
    
    try {
      _isProcessing = true;
      
      // Kamerayı durdur
      _disposeCamera();
      
      // Resim seçici aç
      final List<AssetEntity>? result = await AssetPicker.pickAssets(
        context,
        pickerConfig: const AssetPickerConfig(
          maxAssets: 1,
          requestType: RequestType.image,
        ),
      );
      
      if (result == null || result.isEmpty || !mounted) {
        _isProcessing = false;
        return;
      }
      
      // Seçilen resim
      final AssetEntity asset = result.first;
      
      // Resmin dosya yolunu al
      final File? file = await asset.file;
      
      if (file == null || !mounted) {
        _isProcessing = false;
        if (mounted) _showMessage('Resim dosyası alınamadı.');
        return;
      }
      
      // QR kod tespiti yap
      final qrData = await _detectQRFromFile(file.path);
      
      if (!mounted) {
        _isProcessing = false;
        return;
      }
      
      if (qrData != null) {
        // QR kod bulundu
        _showMessage('QR kod başarıyla okundu!', isError: false);
        
        // Galeri işlemi bitince güvenli navigasyon
        _safeNavigateWithResult(qrData);
      } else {
        // QR kod bulunamadı
        _showMessage('QR kod tespit edilemedi. Manuel giriş yapabilirsiniz.');
        
        // Galeri modu verisi oluştur
        final emptyData = {'galleryMode': 'true', 'tc': '', 'plaka': '', 'ruhsatNo': ''};
        
        // Galeri işlemi bitince güvenli navigasyon
        _safeNavigateWithResult(emptyData);
      }
    } catch (e) {
      if (mounted) _showMessage('Hata: $e');
      _isProcessing = false;
    }
  }
  
  Future<void> _pickImageWithRawData() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    
    // iOS'ta Uint8List ile çalışma
    final bytes = await pickedFile.readAsBytes();
    
    // ML Kit ile bytes kullanarak tarama
    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(800, 800), 
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.yuv420,
        bytesPerRow: 800 * 4,
      ),
    );
    
    // QR tarama işlemi...
  }
  
  // QR kod tespiti için file_picker ile seçilmiş dosyayı işleyen metod
  Future<Map<String, String>?> _detectQRFromFile(String filePath) async {
    try {
      // Önce file doğrulama
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }
      
      // iOS'ta raw data kullanımı
      final Uint8List bytes = await file.readAsBytes();
      
      // InputImage.fromBytes kullanımı
      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(800, 800), 
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.yuv420,
          bytesPerRow: 800 * 4,
        ),
      );
      
      final barcodeScanner = GoogleMlKit.vision.barcodeScanner();
      final barcodes = await barcodeScanner.processImage(inputImage);
      await barcodeScanner.close();
      
      if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
        return _parseQRContent(barcodes.first.rawValue!);
      }
      return null;
    } catch (e) {
      print('QR okuma hatası: $e');
      return null;
    }
  }
  
  // Eski _detectQRFromImage metodunu kaldır veya güncelle
  Future<Map<String, String>?> _detectQRFromImage(XFile image) async {
    return _detectQRFromFile(image.path);
  }
  
  // Basit mesaj gösterimi (hata veya bilgi)
  void _showMessage(String message, {bool isError = true}) {
    if (!mounted || _isDisposed) return;
    print("DEBUG: SimpleMessage gösteriliyor: $message");
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.blue,
        duration: Duration(seconds: isError ? 3 : 1),
      ),
    );
  }
  
  Map<String, String> _parseQRContent(String content) {
    Map<String, String> qrData = {};
    
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
        } else {
          // URL'de query parametresi yoksa ham URL'yi sakla
          qrData['rawData'] = content;
        }
      } catch (e) {
        // URL parse hatası durumunda ham içeriği sakla
        qrData['rawData'] = content;
      }
    } 
    // Geleneksel format: RuhsatNo-Plaka-TC
    else if (content.contains('-')) {
      final parts = content.split('-');
      if (parts.length == 3) {
        qrData['ruhsatNo'] = parts[0].trim();
        qrData['plaka'] = parts[1].trim();
        qrData['tc'] = parts[2].trim();
      } else {
        // Format uygun değilse ham veriyi sakla
        qrData['rawData'] = content;
      }
    } 
    // Başka formatlar için
    else {
      // Ham veriyi sakla
      qrData['rawData'] = content;
    }
    
    return qrData;
  }
  
  Future<void> _processQRContent(String content) async {
    if (_isDisposed || !mounted) {
      _isProcessing = false;
      return;
    }

    try {
      // Kamerayı durdur
      _disposeCamera();
      
      if (!mounted || _isDisposed) {
        _isProcessing = false;
        return;
      }
      
      Map<String, String> qrData = _parseQRContent(content);
      
      if (!mounted || _isDisposed) {
        _isProcessing = false;
        return;
      }
      
      // Galeri işlemi bitince güvenli navigasyon
      _safeNavigateWithResult(qrData);
    } catch (e) {
      if (!_isDisposed && mounted) {
        _showError('QR kod işlenirken hata oluştu');
      }
    } finally {
      _isProcessing = false;
    }
  }

  // Galeri işlemi bitince güvenli navigasyon
  void _safeNavigateWithResult(Map<String, String> result) {
    if (!mounted) return;
    
    // Önce durumu al, sonra widget'a erişme
    final onResultCallback = widget.onResult;
    
    if (onResultCallback != null) {
      // Context yok context kullanmadan geri çağrı
      onResultCallback(result);
    } else if (mounted) {
      // Context'e erişmeden önce mounted kontrolü
      Navigator.of(context).pop(result);
    }
  }

  // Güvenli SnackBar gösterimi
  void _showError(String message, {bool isError = true}) {
    if (_isDisposed || !mounted) return;
    
    try {
      final currentContext = context;
      Future.microtask(() {
        if (!_isDisposed && mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: isError ? Colors.red : Colors.blue,
            ),
          );
        }
      });
    } catch (e) {
      // Hata durumunu sessizce geç
    }
  }

  // Manuel giriş butonuna basıldığında
  void _handleManualEntry() {
    if (_isDisposed || !mounted) return;
    
    try {
      _disposeCamera();
      final currentContext = context;
      
      if (widget.onManualEntry != null) {
        if (mounted && !_isDisposed) {
          Navigator.of(currentContext).maybePop();
          
          Future.microtask(() {
            if (widget.onManualEntry != null) {
              widget.onManualEntry!();
            }
          });
        }
      } else if (mounted && !_isDisposed) {
        Navigator.of(currentContext).maybePop();
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        Navigator.of(context).maybePop();
      }
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
      // Hata durumunu sessizce geç
    }
  }
  
  // QR görünümü oluştur
  Widget _buildQRView() {
    // Kamera başlatılmadıysa alternatif görünümü göster
    if (!_isCameraInitialized) {
      return _buildCameraUnavailableView();
    }
    
    return mobile_scanner.MobileScanner(
      controller: controller,
      onDetect: (mobile_scanner.BarcodeCapture capture) {
        if (_isDisposed || !mounted || _isProcessing) return;
        
        final List<mobile_scanner.Barcode> barcodes = capture.barcodes;
        if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
          _isProcessing = true;
          _processScannedQRContent(barcodes.first.rawValue!);
        }
      },
      overlay: Stack(
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5), 
              BlendMode.srcOut
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 250,
                    width: 250,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // QR tarama çerçevesi
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF1C3879),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  // Köşe işaretleri
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _CornerBox(isTopLeft: true),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _CornerBox(isTopRight: true),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: _CornerBox(isBottomLeft: true),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _CornerBox(isBottomRight: true),
                  ),
                ],
              ),
            ),
          ),
          // Tarama talimatı
          Positioned(
            bottom: 300,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'QR Kodunuzu Çerçeveye Getirin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  backgroundColor: Colors.black.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Kamera kullanılamadığında gösterilecek görünüm
  Widget _buildCameraUnavailableView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.no_photography,
              color: Colors.white,
              size: 80,
            ),
            const SizedBox(height: 20),
            const Text(
              'Kamera kullanılamıyor',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                _isCameraPermissionDenied 
                    ? 'Kamera izni reddedildi. Ayarlardan izin vermeniz gerekebilir.'
                    : 'QR tarayıcı başlatılamadı. Lütfen cihaz ayarlarınızı kontrol edin veya aşağıdaki seçenekleri kullanın.',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            if (_isCameraPermissionDenied)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () async {
                  // Ayarlar sayfasına yönlendir
                  await openAppSettings();
                },
                child: const Text('Ayarları Aç'),
              ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => _handleManualEntry(),
                  child: const Text('Manuel Giriş'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => _pickImage(),
                  child: const Text('Fotoğraf Yükle'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 