import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ml_card_scanner/ml_card_scanner.dart';
import 'package:card_scanner/card_scanner.dart';
import '../viewmodels/offer_viewmodel.dart';
import '../viewmodels/payment_viewmodel.dart';

// Manuel kart bilgileri giriş ekranı
class CardManualEntryView extends StatefulWidget {
  final String detailUrl;
  final int offerId;
  final int companyId;
  final String holderTC;
  final String holderBD;
  final int maxInstallment;
  final CardInfo? scanResult; // ml_card_scanner paketi kullanılıyorsa
  final String? cardNumber; // Direkt olarak kart numarası da alabilir
  final String? cardHolder; // Kart sahibi adı
  final String? expiryDate; // Son kullanma tarihi

  const CardManualEntryView({
    Key? key,
    required this.detailUrl,
    required this.offerId,
    required this.companyId,
    required this.holderTC,
    required this.holderBD,
    this.maxInstallment = 1,
    this.scanResult,
    this.cardNumber,
    this.cardHolder,
    this.expiryDate,
  }) : super(key: key);

  @override
  State<CardManualEntryView> createState() => _CardManualEntryViewState();
}

class _CardManualEntryViewState extends State<CardManualEntryView> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _tcNoController = TextEditingController();
  final _birthDateController = TextEditingController();
  String _instalmentValue = "1";
  late PaymentViewModel _paymentViewModel;
  bool _isScanning = false; // Tarama durumu için flag

  @override
  void initState() {
    super.initState();
    _paymentViewModel = Provider.of<PaymentViewModel>(context, listen: false);

    // TC ve doğum tarihi bilgilerini widget parametrelerinden al
    _tcNoController.text = widget.holderTC;
    _birthDateController.text = widget.holderBD;
    
    // Tarama sonucu varsa, form alanlarını doldur
    if (widget.scanResult != null) {
      _processScannedCardData(widget.scanResult!);
    } else if (widget.cardNumber != null || widget.expiryDate != null || widget.cardHolder != null) {
      // Direkt olarak kart bilgileri verildiyse
      _processDirectCardData();
    }
  }
  
  // Doğrudan gelen kart bilgilerini işle
  void _processDirectCardData() {
    try {
      // Kart numarası
      if (widget.cardNumber != null && widget.cardNumber!.isNotEmpty) {
        _cardNumberController.text = widget.cardNumber!;
        
        // Gerekirse kart numarası formatlaması yapılabilir
        if (!_cardNumberController.text.contains(' ')) {
          final formattedNumber = _formatCardNumber(widget.cardNumber!);
          _cardNumberController.text = formattedNumber;
        }
      }
      
      // Kart sahibi adı
      if (widget.cardHolder != null && widget.cardHolder!.isNotEmpty) {
        _cardHolderController.text = widget.cardHolder!;
      }
      
      // Son kullanma tarihi
      if (widget.expiryDate != null && widget.expiryDate!.isNotEmpty) {
        String expiryDate = widget.expiryDate!;
        
        // Eksik formatı düzelt (bazen MM/YY yerine sadece MMYY olabilir)
        if (!expiryDate.contains('/') && expiryDate.length >= 4) {
          expiryDate = "${expiryDate.substring(0, 2)}/${expiryDate.substring(2, 4)}";
        }
        
        _expiryDateController.text = expiryDate;
        
        // Formatlama uygula
        _expiryDateController.text = CardExpiryInputFormatter().formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(text: _expiryDateController.text),
        ).text;
      }
      
      debugPrint('Kart bilgileri direkt olarak işlendi: ${_cardNumberController.text}');
    } catch (e) {
      debugPrint('Kart bilgileri işlenirken hata: $e');
    }
  }
  
  // Kart numarası formatlama (4 hanede bir boşluk)
  String _formatCardNumber(String number) {
    String cleanNumber = number.replaceAll(RegExp(r'\D'), '');
    StringBuffer buffer = StringBuffer();
    
    for (int i = 0; i < cleanNumber.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(cleanNumber[i]);
    }
    
    return buffer.toString();
  }
  
  // Tarama sonucunu işleme
  void _processScannedCardData(CardInfo scanResult) {
    try {
      // Kart numarası
      if (scanResult.number.isNotEmpty) {
        _cardNumberController.text = scanResult.numberFormatted();
      }
      
      // Son kullanma tarihi
      if (scanResult.expiry.isNotEmpty) {
        // Tarih formatını kontrol et
        String expiryDate = scanResult.expiry;
        
        // Eksik formatı düzelt (bazen MM/YY yerine sadece MMYY olabilir)
        if (!expiryDate.contains('/') && expiryDate.length >= 4) {
          expiryDate = "${expiryDate.substring(0, 2)}/${expiryDate.substring(2, 4)}";
        }
        
        _expiryDateController.text = expiryDate;
        
        // Formatlama uygula
        _expiryDateController.text = CardExpiryInputFormatter().formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(text: _expiryDateController.text),
        ).text;
      }
    } catch (e) {
      // Tarama sonucu işlenirken hata olursa sessizce geç
      debugPrint('Kart verileri işlenirken hata: $e');
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _tcNoController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  // Kart tarama fonksiyonu
  Future<void> _scanCard() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
    });

    try {
      // Önce kamera izinlerini kontrol et
      final status = await Permission.camera.status;
      
      if (!status.isGranted) {
        // İzin iste
        final result = await Permission.camera.request();
        if (!result.isGranted) {
          // Kullanıcıya bildirim göster
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Kart tarama işlemi için kamera izni gereklidir.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _isScanning = false;
          });
          return;
        }
      }
      
      // Önce card_scanner paketini deneyelim
      try {
        debugPrint('Card Scanner paketi ile taramayı deniyorum...');
        
        // Doğrudan CardScanner.scanCard() çağrısı yapılıyor
        final cardDetails = await CardScanner.scanCard();
        
        if (cardDetails != null) {
          if (mounted) {
            debugPrint('Card Scanner ile kart tarandı: ${cardDetails.cardNumber}');
            
            if (cardDetails.cardNumber != null) {
              _cardNumberController.text = _formatCardNumber(cardDetails.cardNumber!);
            }
            
            if (cardDetails.expiryDate != null) {
              _expiryDateController.text = cardDetails.expiryDate!;
              
              // Formatlama uygula
              _expiryDateController.text = CardExpiryInputFormatter().formatEditUpdate(
                TextEditingValue.empty,
                TextEditingValue(text: _expiryDateController.text),
              ).text;
            }
            
            if (cardDetails.cardHolderName != null) {
              _cardHolderController.text = cardDetails.cardHolderName!;
            }
            
            setState(() {
              _isScanning = false;
            });
            return;
          }
        }
      } catch (e) {
        debugPrint('Card Scanner paketi ile tarama başarısız: $e');
        // CardScanner başarısız olursa, ml_card_scanner'ı deneyelim
      }
      
      // ml_card_scanner paketi ile tarama (yedek yöntem)
      final CardInfo? cardInfo = await showDialog<CardInfo>(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          final controller = ScannerWidgetController();
          
          // Card tarandığında kontrol için
          controller.setCardListener((cardInfo) {
            if (cardInfo != null) {
              Navigator.of(context).pop(cardInfo);
            }
          });
          
          return AlertDialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            contentPadding: EdgeInsets.zero,
            content: SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.8,
              child: ScannerWidget(
                overlayOrientation: CardOrientation.portrait,
                oneShotScanning: true,
                cardScanTries: 4,  // Tarama denemesi sayısı
                cameraResolution: CameraResolution.high,
                usePreprocessingFilters: true,
                controller: controller,
              ),
            ),
          );
        },
      );

      if (mounted && cardInfo != null && cardInfo.isValid()) {
        debugPrint('ML Card Scanner ile kart tarandı');
        // Tarama sonucunu işle
        _processScannedCardData(cardInfo);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kart tarama hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          'Kart Bilgileri',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Kart bilgilerinizi kontrol ederek, ödemeyi tamamlayabilirsiniz.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),

              // Kart Üzerindeki Ad Soyad
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Kart Üzerideki Ad Soyad',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cardHolderController,
                decoration: InputDecoration(
                  hintText: 'Örn: Ahmet Yılmaz',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.person_outline, color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Kart sahibi adı gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              
              // Kart Numarası
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Kart Numarası',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cardNumberController,
                decoration: InputDecoration(
                  hintText: 'Örn: "1234 5678 9012 3456"',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.credit_card, color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(19), // 16 digit + 3 spaces
                  CardNumberInputFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kart numarası gerekli';
                  }
                  final cleanValue = value.replaceAll(' ', '');
                  if (cleanValue.length != 16) {
                    return 'Kart numarası 16 haneli olmalı';
                  }
                  if (!RegExp(r'^\d+$').hasMatch(cleanValue)) {
                    return 'Sadece rakam girilmelidir';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              
              // SKT Tek satırda
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SKT',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _expiryDateController,
                    decoration: InputDecoration(
                      hintText: 'AA/YY',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.date_range_outlined, size: 20, color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Theme.of(context).primaryColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      CardExpiryInputFormatter(),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'SKT gerekli';
                      }
                      if (!RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$').hasMatch(value)) {
                        return 'Geçersiz format (AA/YY)';
                      }
                      final parts = value.split('/');
                      final month = int.tryParse(parts[0]);
                      final year = int.tryParse('20${parts[1]}'); // YY -> YYYY
                      if (month == null || year == null) {
                        return 'Geçersiz tarih';
                      }
                      final now = DateTime.now();
                      // Ayın son gününü kontrol et
                      final expiryDate = DateTime(year, month + 1, 0); // Bir sonraki ayın 0. günü = bu ayın son günü
                      if (expiryDate.isBefore(DateTime(now.year, now.month))) {
                        return 'Kartın süresi dolmuş';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // CVV ve Taksit yan yana
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CVV
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CVV',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _cvvController,
                          decoration: InputDecoration(
                            hintText: '123',
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(Icons.lock_outline, size: 20, color: Colors.grey[600]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Theme.of(context).primaryColor),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4), // Genellikle 4 haneli
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'CVV gerekli';
                            }
                            if (!RegExp(r'^\d{3}$').hasMatch(value)) {
                              return 'CVV 3 haneli olmalı';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  
                  // Taksit
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Taksit',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _instalmentValue,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 0),
                            ),
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                            items: List.generate(widget.maxInstallment, (index) {
                              final count = index + 1;
                              return DropdownMenuItem(
                                value: count.toString(),
                                child: Text(
                                  count == 1 ? "Tek Çekim" : "$count Taksit",
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _instalmentValue = value;
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Taksit seçimi gerekli';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 15),
              
              // TC No
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Kart Sahibi TC No',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tcNoController,
                decoration: InputDecoration(
                  hintText: 'Örn: 12345678900',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.badge_outlined, color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'TC No gerekli';
                  }
                  if (value.length != 11) {
                    return 'TC No 11 haneli olmalı';
                  }
                  if (!RegExp(r'^\d{11}$').hasMatch(value)) {
                    return 'Sadece rakam girilmelidir';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 15),
              
              // Doğum Tarihi
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Kart Sahibi Doğum Tarihi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _birthDateController,
                decoration: InputDecoration(
                  hintText: 'Örn: GG.AA.YYYY',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.cake_outlined, color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                ),
                keyboardType: TextInputType.datetime,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                  BirthDateInputFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Doğum tarihi gerekli';
                  }
                  if (!RegExp(r'^(0[1-9]|[12][0-9]|3[01])\.(0[1-9]|1[0-2])\.\d{4}$').hasMatch(value)) {
                    return 'Geçersiz format (GG.AA.YYYY)';
                  }
                  try {
                    final parts = value.split('.');
                    final day = int.parse(parts[0]);
                    final month = int.parse(parts[1]);
                    final year = int.parse(parts[2]);
                    // Basit tarih geçerlilik kontrolü
                    DateTime(year, month, day);
                  } catch (e) {
                    return 'Geçersiz tarih';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 30),
              
              // Ödemeyi Tamamla butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Ödemeyi Tamamla'),
                ),
              ),
              
              const SizedBox(height: 15),
              
              const Text(
                'Ödemeyi Tamamla butonuna tıklayarak, yukarıdaki bilgilerin doğruluğunu onaylamış olursunuz.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Form validasyonu başarılı ise
      final cardData = CardData(
        cardNumber: _cardNumberController.text,
        cardHolder: _cardHolderController.text,
        expiryDate: _expiryDateController.text,
        cvv: _cvvController.text,
        tcNo: _tcNoController.text,
        birthDate: _birthDateController.text,
        instalment: _instalmentValue,
      );
      
      // Önce ödeme işlemini başlat
      final paymentViewModel = Provider.of<PaymentViewModel>(context, listen: false);
      
      // Yükleme göstergesi ile birlikte işlemi başlat
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );
      
      // Ödeme işlemini başlat
      paymentViewModel.processPaymentFromCardData(
        cardData,
        offerId: widget.offerId,
        companyId: widget.companyId,
      ).then((success) {
        // Dialog'u kapat
        Navigator.pop(context);
        
        if (success) {
          // Başarılı ise onay sayfasına git
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentConfirmationView(
                detailUrl: widget.detailUrl,
                offerId: widget.offerId, 
                companyId: widget.companyId,
                cardData: cardData,
              ),
            ),
          );
        } else {
          // Hata varsa göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ödeme hatası: ${paymentViewModel.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }
}

// Ödeme onay ekranı
class PaymentConfirmationView extends StatelessWidget {
  final String detailUrl;
  final CardData cardData;
  final int offerId;
  final int companyId;

  const PaymentConfirmationView({
    Key? key, 
    required this.detailUrl,
    required this.offerId,
    required this.companyId,
    required this.cardData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text(
          'Ödeme Onayı',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kart Bilgileri:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Kart bilgileri gösterimi
            _buildInfoRow('Kart Numarası', _maskCardNumber(cardData.cardNumber)),
            _buildInfoRow('Kart Sahibi', cardData.cardHolder),
            _buildInfoRow('Son Kullanma Tarihi', cardData.expiryDate),
            if (cardData.tcNo != null && cardData.tcNo!.isNotEmpty)
              _buildInfoRow('TC Kimlik No', _maskTCNo(cardData.tcNo!)),
            if (cardData.instalment != null && cardData.instalment != "1")
              _buildInfoRow('Taksit', '${cardData.instalment} Taksit'),
            
            const SizedBox(height: 40),
            
            // Ödeme butonu
            SizedBox(
              width: double.infinity,
              child: Consumer<PaymentViewModel>(
                builder: (context, paymentViewModel, child) {
                  return ElevatedButton(
                    onPressed: paymentViewModel.isLoading 
                        ? null 
                        : () => _processPayment(context, paymentViewModel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: paymentViewModel.isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'İşleniyor...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Ödemeyi Tamamla',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Ödeme işlemini gerçekleştir
  Future<void> _processPayment(BuildContext context, PaymentViewModel paymentViewModel) async {
    final success = await paymentViewModel.processPaymentFromCardData(
      cardData,
      offerId: offerId,
      companyId: companyId,
    );
    
    if (success) {
      // Başarılı ise URL'i aç
      final viewModel = Provider.of<OfferViewModel>(context, listen: false);
      await viewModel.openDetailUrl(detailUrl);
      
      // Başarı mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ödeme işlemi başarıyla tamamlandı.'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Ana sayfaya dön
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      // Hata mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ödeme hatası: ${paymentViewModel.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _maskCardNumber(String cardNumber) {
    // Kart numarasının son 4 hanesini göster, diğerlerini maskele
    cardNumber = cardNumber.replaceAll(' ', '');
    if (cardNumber.length > 4) {
      final visiblePart = cardNumber.substring(cardNumber.length - 4);
      return '**** **** **** $visiblePart';
    }
    return cardNumber;
  }
  
  String _maskTCNo(String tcNo) {
    // TC No'nun ilk 3 ve son 3 hanesini göster, diğerlerini maskele
    if (tcNo.length >= 6) {
      final firstPart = tcNo.substring(0, 3);
      final lastPart = tcNo.substring(tcNo.length - 3);
      final middleAsterisks = '*' * (tcNo.length - 6);
      return '$firstPart$middleAsterisks$lastPart';
    }
    return tcNo;
  }
}

// Kart bilgileri modeli
class CardData {
  final String cardNumber;
  final String cardHolder;
  final String expiryDate;
  final String cvv;
  final String? tcNo;
  final String? birthDate;
  final String? instalment;

  String get holderTC => tcNo ?? '';
  String get holderBD => birthDate ?? '';

  CardData({
    required this.cardNumber,
    required this.cardHolder,
    required this.expiryDate,
    required this.cvv,
    this.tcNo,
    this.birthDate,
    this.instalment,
  });
}

// InputFormatters için helper sınıfları
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' '); // Add space after every 4 digits
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length));
  }
}

class CardExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var newText = newValue.text;

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    
    var buffer = StringBuffer();
    for (int i = 0; i < newText.length; i++) {
      buffer.write(newText[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 2 == 0 && nonZeroIndex != newText.length) {
        buffer.write('/'); // Add slash after 2 digits (month)
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class BirthDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var newText = newValue.text;

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var buffer = StringBuffer();
    int digitCount = 0;
    for (int i = 0; i < newText.length; i++) {
       if (RegExp(r'\d').hasMatch(newText[i])) {
         buffer.write(newText[i]);
         digitCount++;
         if ((digitCount == 2 || digitCount == 4) && digitCount != newText.replaceAll(RegExp(r'\D'), '').length) {
             buffer.write('.'); // Add dot after day and month
         }
       }
    }
    
    var string = buffer.toString();
     // Limit total digits to 8 (DDMMAAAA)
    if (string.replaceAll(RegExp(r'\D'), '').length > 8) {
        string = oldValue.text; // Revert if more than 8 digits entered
    }

    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
} 