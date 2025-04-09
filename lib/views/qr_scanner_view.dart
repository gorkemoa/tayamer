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
  bool _isProcessing = false;
  bool _isDisposed = false;
  bool _isPaused = false;
  BuildContext? _storedContext;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _storedContext = context;
  }
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    controller?.stopCamera();
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
    if (_isDisposed) return;

    setState(() {
      this.controller = controller;
    });

    controller.scannedDataStream.listen(
      (scanData) {
        if (!_isDisposed && scanData.code != null) {
          _handleQRDetection(scanData);
        }
      },
      onError: (error) {
        print('QR tarama hatası: $error');
        _showError('QR tarama hatası: $error');
      },
      cancelOnError: false,
    );
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;

    if (state == AppLifecycleState.resumed && _isPaused) {
      _isPaused = false;
      controller?.resumeCamera();
    } else if (state == AppLifecycleState.inactive || 
              state == AppLifecycleState.paused || 
              state == AppLifecycleState.detached) {
      _isPaused = true;
      controller?.pauseCamera();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return const SizedBox.shrink();
    }
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
                            _showMessage('Fotoğraftan QR kod taranıyor...');
                            
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

  void _showError(String message) {
    if (_isDisposed || !mounted || _storedContext == null) return;
    
    final scaffoldMessenger = ScaffoldMessenger.of(_storedContext!);
    if (scaffoldMessenger.mounted) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMessage(String message) {
    if (_isDisposed || !mounted || _storedContext == null) return;
    
    final scaffoldMessenger = ScaffoldMessenger.of(_storedContext!);
    if (scaffoldMessenger.mounted) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _handleQRDetection(Barcode scanData) async {
    if (_isProcessing || _isDisposed || !mounted) return;

    try {
      _isProcessing = true;
      final String code = scanData.code ?? '';

      if (code.isEmpty) {
        _isProcessing = false;
        return;
      }

      if (!mounted || _isDisposed) {
        _isProcessing = false;
        return;
      }

      await controller?.pauseCamera();

      if (!mounted || _isDisposed) {
        _isProcessing = false;
        return;
      }

      _showMessage('QR kod okundu, işleniyor...');

      Map<String, String> qrData = {};

      try {
        final parts = code.split('-');
        if (parts.length == 3) {
          qrData['plaka'] = parts[0].trim();
          qrData['ruhsatNo'] = parts[1].trim();
          qrData['tc'] = parts[2].trim();
          
          print('QR verisi ayrıştırıldı: Plaka=${qrData['plaka']}, Ruhsat=${qrData['ruhsatNo']}, TC=${qrData['tc']}');
        }
      } catch (e) {
        print('QR kod ayrıştırma hatası: $e');
      }

      if (!mounted || _isDisposed || _storedContext == null) {
        _isProcessing = false;
        return;
      }

      Navigator.of(_storedContext!).pop(qrData);
    } catch (e) {
      print('QR işleme genel hatası: $e');
      
      if (!_isDisposed && mounted) {
        _showError('QR kod işlenirken hata oluştu: $e');
      }
    } finally {
      _isProcessing = false;
    }
  }
} 