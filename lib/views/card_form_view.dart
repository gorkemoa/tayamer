import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:credit_card_scanner/credit_card_scanner.dart';
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

  const CardManualEntryView({
    Key? key,
    required this.detailUrl,
    required this.offerId,
    required this.companyId,
    required this.holderTC,
    required this.holderBD,
    this.maxInstallment = 1,
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
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _paymentViewModel = Provider.of<PaymentViewModel>(context, listen: false);

    // TC ve doğum tarihi bilgilerini widget parametrelerinden al
    _tcNoController.text = widget.holderTC;
    _birthDateController.text = widget.holderBD;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text(
          'Kart Bilgileri',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isScanning 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5)
                )
              : const Icon(Icons.camera_alt, color: Colors.white, size: 22),
            tooltip: 'Kartı Tarayarak Doldur',
            onPressed: _isScanning ? null : _scanCard,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Kart bilgilerinizi kontrol ederek, ödemeyi tamamlayabilirsiniz.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Kart Üzerindeki Ad Soyad
              _buildLabel('Kart Üzerideki Ad Soyad'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _cardHolderController,
                style: const TextStyle(fontSize: 14),
                decoration: _inputDecoration(
                  hintText: 'Örn: Ahmet Yılmaz',
                  prefixIcon: Icons.person_outline,
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Kart sahibi adı gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              // Kart Numarası
              _buildLabel('Kart Numarası'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _cardNumberController,
                style: const TextStyle(fontSize: 14),
                decoration: _inputDecoration(
                  hintText: 'Örn: "1234 5678 9012 3456"',
                  prefixIcon: Icons.credit_card,
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
              const SizedBox(height: 12),
              
              // SKT Tek satırda
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('SKT'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _expiryDateController,
                    style: const TextStyle(fontSize: 14),
                    decoration: _inputDecoration(
                      hintText: 'AA/YY',
                      prefixIcon: Icons.date_range_outlined,
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
              const SizedBox(height: 12),

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
                        _buildLabel('CVV'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _cvvController,
                          style: const TextStyle(fontSize: 14),
                          decoration: _inputDecoration(
                            hintText: '123',
                            prefixIcon: Icons.lock_outline,
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
                  const SizedBox(width: 8),
                  
                  // Taksit
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Taksit'),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _instalmentValue,
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                            ),
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600], size: 20),
                            items: List.generate(widget.maxInstallment, (index) {
                              final count = index + 1;
                              return DropdownMenuItem(
                                value: count.toString(),
                                child: Text(
                                  count == 1 ? "Tek Çekim" : "$count Taksit",
                                  style: const TextStyle(fontSize: 13),
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
              
              const SizedBox(height: 12),
              
              // TC No
              _buildLabel('Kart Sahibi TC No'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _tcNoController,
                style: const TextStyle(fontSize: 14),
                decoration: _inputDecoration(
                  hintText: 'Örn: 12345678900',
                  prefixIcon: Icons.badge_outlined,
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
              
              const SizedBox(height: 12),
              
              // Doğum Tarihi
              _buildLabel('Kart Sahibi Doğum Tarihi'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _birthDateController,
                style: const TextStyle(fontSize: 14),
                decoration: _inputDecoration(
                  hintText: 'Örn: GG.AA.YYYY',
                  prefixIcon: Icons.cake_outlined,
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
              
              const SizedBox(height: 24),
              
              // Ödemeyi Tamamla butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 3,
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Ödemeyi Tamamla'),
                ),
              ),
              
              const SizedBox(height: 12),
              
              const Text(
                'Ödemeyi Tamamla butonuna tıklayarak, yukarıdaki bilgilerin doğruluğunu onaylamış olursunuz.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
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

  // Kart tarama fonksiyonu
  Future<void> _scanCard() async {
    try {
      setState(() {
        _isScanning = true;
      });
      
      // Bilgilendirme mesajı göster
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Kart Tarama'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text(
                  'Lütfen kartınızı kamera çerçevesine yerleştirin. '
                  'Kart bilgileri otomatik olarak okunacaktır.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
      
      final CardDetails? cardDetails = await CardScanner.scanCard(
        scanOptions: const CardScanOptions(
          scanCardHolderName: true,
          enableDebugLogs: true,
          validCardsToScanBeforeFinishingScan: 3,
          considerPastDatesInExpiryDateScan: false,
        ),
      );
      
      // Dialog'u kapat
      if (!mounted) return;
      Navigator.pop(context);
      
      setState(() {
        _isScanning = false;
      });
      
      if (cardDetails != null) {
        setState(() {
          if (cardDetails.cardNumber != null && cardDetails.cardNumber!.isNotEmpty) {
            _cardNumberController.text = cardDetails.cardNumber!;
          }
          
          if (cardDetails.cardHolderName != null && cardDetails.cardHolderName!.isNotEmpty) {
            _cardHolderController.text = cardDetails.cardHolderName!.toUpperCase();
          }
          
          if (cardDetails.expiryDate != null && cardDetails.expiryDate!.isNotEmpty) {
            // Tarih formatını kontrol et ve düzenle
            final expiry = cardDetails.expiryDate!;
            if (expiry.length >= 4) {
              final month = expiry.substring(0, 2);
              final year = expiry.substring(2, 4);
              _expiryDateController.text = '$month/$year';
            }
          }
        });
        
        // Başarı mesajı göster
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kart bilgileri başarıyla tarandı'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kart tarama hatası: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Helper widget for labels
  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  // Helper for InputDecoration
  InputDecoration _inputDecoration({required String hintText, IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey[600], size: 18) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    );
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
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kart Bilgileri:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Kart bilgileri gösterimi
            _buildInfoRow('Kart Numarası', _maskCardNumber(cardData.cardNumber)),
            _buildInfoRow('Kart Sahibi', cardData.cardHolder),
            _buildInfoRow('Son Kullanma Tarihi', cardData.expiryDate),
            if (cardData.tcNo != null && cardData.tcNo!.isNotEmpty)
              _buildInfoRow('TC Kimlik No', _maskTCNo(cardData.tcNo!)),
            if (cardData.instalment != null && cardData.instalment != "1")
              _buildInfoRow('Taksit', '${cardData.instalment} Taksit'),
            
            const SizedBox(height: 30),
            
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                    ),
                    child: paymentViewModel.isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 1.5,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'İşleniyor...',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Ödemeyi Tamamla',
                            style: TextStyle(
                              fontSize: 14,
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
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
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