/* import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/payment_viewmodel.dart';
import '../models/payment_model.dart';
import 'sms_confirmation_view.dart';

class PaymentExampleView extends StatefulWidget {
  const PaymentExampleView({Key? key}) : super(key: key);

  @override
  _PaymentExampleViewState createState() => _PaymentExampleViewState();
}

class _PaymentExampleViewState extends State<PaymentExampleView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _holderTCController = TextEditingController();
  final TextEditingController _holderBDController = TextEditingController();
  
  final int _offerId = 4;
  final int _companyId = 7;

  @override
  void initState() {
    super.initState();
    // Test için örnek değerler

  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _holderTCController.dispose();
    _holderBDController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme Örneği'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'API Test Sayfası',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // Kart Sahibi
              TextFormField(
                controller: _cardHolderController,
                decoration: const InputDecoration(
                  labelText: 'Kart Sahibi',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kart sahibi giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Kart Numarası
              TextFormField(
                controller: _cardNumberController,
                decoration: const InputDecoration(
                  labelText: 'Kart Numarası',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kart numarası giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Son Kullanma Tarihi
              TextFormField(
                controller: _expiryDateController,
                decoration: const InputDecoration(
                  labelText: 'Son Kullanma Tarihi (AA/YY)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Son kullanma tarihi giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // CVV
              TextFormField(
                controller: _cvvController,
                decoration: const InputDecoration(
                  labelText: 'CVV',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'CVV giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // ID Bilgileri Göster
              Text(
                'OfferID: $_offerId, CompanyID: $_companyId',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),
              
              // Ödeme Butonu
              SizedBox(
                width: double.infinity,
                child: Consumer<PaymentViewModel>(
                  builder: (context, viewModel, child) {
                    return ElevatedButton(
                      onPressed: viewModel.isLoading ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: viewModel.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Ödemeyi Tamamla'),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Ödeme Sonucu
              Consumer<PaymentViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.isSuccess) {
                    return const Card(
                      color: Colors.green,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Ödeme Başarılı!',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  } else if (viewModel.isError) {
                    return Card(
                      color: Colors.red,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Hata: ${viewModel.errorMessage}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _processPayment() {
    if (_formKey.currentState!.validate()) {
      final paymentViewModel = Provider.of<PaymentViewModel>(context, listen: false);
      
      paymentViewModel.processPayment(
        offerId: _offerId,
        companyId: _companyId,
        installment: 1,
        holderTC: _cardHolderController.text,
        holderBD: _cardHolderController.text,
        holder: _cardHolderController.text,
        cardNumber: _cardNumberController.text.replaceAll(' ', ''),
        expDate: _expiryDateController.text,
        cvv: _cvvController.text,
      ).then((success) {
        if (success && paymentViewModel.isSmsConfirmationRequired) {
          // SMS onayı gerekiyorsa SMS onay sayfasına yönlendir
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SmsConfirmationView(
                offerId: _offerId,
                companyId: _companyId,
              ),
            ),
          );
        }
      });
    }
  }
} 
*/