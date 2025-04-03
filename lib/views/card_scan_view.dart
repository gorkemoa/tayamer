import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../viewmodels/offer_viewmodel.dart';
import '../viewmodels/payment_viewmodel.dart';

class CardScanView extends StatefulWidget {
  final String detailUrl;
  final int offerId;
  final int wsPriceId;
  final int companyId;

  const CardScanView({
    Key? key, 
    required this.detailUrl,
    required this.offerId,
    required this.wsPriceId,
    required this.companyId,
  }) : super(key: key);

  @override
  State<CardScanView> createState() => _CardScanViewState();
}

class _CardScanViewState extends State<CardScanView> {
  MobileScannerController cameraController = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text(
          'Kartınızı Okutun',
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
      body: Stack(
        children: [
          // Kamera görüntüsü
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                // Kart bilgisi algılandığında yapılacak işlemler
                final String cardData = barcodes.first.rawValue ?? '';
                processCardData(cardData);
              }
            },
          ),
          
          // Kart alanını belirten çerçeve
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.width * 0.5,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.blue,
                  width: 3.0,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          // Manuel giriş butonu
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => CardManualEntryView(
                        detailUrl: widget.detailUrl,
                        offerId: widget.offerId,
                        wsPriceId: widget.wsPriceId,
                        companyId: widget.companyId,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E3A8A),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Manuel Giriş'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void processCardData(String cardData) {
    // TODO: Kart verisini işle, burada kredi kartı bilgilerini ayrıştırma kodları eklenir
    // Örnek: cardNumber, cardHolder, expiryDate, cvv gibi bilgileri parseCard fonksiyonu ile çıkarabilirsiniz
    
    // İşlem sonrası ödeme sayfasına yönlendir
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentConfirmationView(
          detailUrl: widget.detailUrl,
          offerId: widget.offerId,
          wsPriceId: widget.wsPriceId,
          companyId: widget.companyId,
          cardData: CardData(
            cardNumber: '4242 4242 4242 4242', // Örnek veri
            cardHolder: 'TEST KART',
            expiryDate: '12/25',
            cvv: '123',
          ),
        ),
      ),
    );
  }
}

// Manuel kart bilgileri giriş ekranı
class CardManualEntryView extends StatefulWidget {
  final String detailUrl;
  final int offerId;
  final int wsPriceId;
  final int companyId;

  const CardManualEntryView({
    Key? key, 
    required this.detailUrl,
    required this.offerId,
    required this.wsPriceId,
    required this.companyId,
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
                  if (value == null || value.isEmpty) {
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kart numarası gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              
              // SKT, CVV ve Taksit yan yana
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SKT
                  Expanded(
                    flex: 2,
                    child: Column(
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
                          keyboardType: TextInputType.datetime,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'SKT gerekli';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  
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
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'CVV gerekli';
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
                            items: List.generate(9, (index) {
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'TC No gerekli';
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Doğum tarihi gerekli';
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
        wsPriceId: widget.wsPriceId,
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
                wsPriceId: widget.wsPriceId,
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
  final int wsPriceId;
  final int companyId;

  const PaymentConfirmationView({
    Key? key, 
    required this.detailUrl,
    required this.offerId,
    required this.wsPriceId,
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
      wsPriceId: wsPriceId,
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