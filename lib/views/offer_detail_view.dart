import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/offer_viewmodel.dart';
import '../models/offer_model.dart';
import 'package:intl/intl.dart';
import 'card_scan_view.dart';

class OfferDetailView extends StatefulWidget {
  final String offerId;

  const OfferDetailView({super.key, required this.offerId});

  @override
  State<OfferDetailView> createState() => _OfferDetailViewState();
}

class _OfferDetailViewState extends State<OfferDetailView> {
  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında teklif detayını getir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OfferViewModel>().getOfferDetail(widget.offerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          'Teklif Detayı',
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
      body: Consumer<OfferViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.state == OfferViewState.loading) {
            return const Center(child: CircularProgressIndicator());
          } else if (viewModel.state == OfferViewState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Hata: ${viewModel.errorMessage}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => viewModel.getOfferDetail(widget.offerId),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          } else if (viewModel.selectedOffer == null) {
            return const Center(child: Text('Teklif bulunamadı'));
          }

          final offer = viewModel.selectedOffer!;
          final formatter = NumberFormat.currency(
            locale: 'tr_TR',
            symbol: '₺',
            decimalDigits: 2,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Teklif Bilgileri
                Card(
                  elevation: 2,
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          offer.policyType,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            _buildInfoRow('Teklif Kodu', offer.code),
                            _buildInfoRow('Plaka', offer.plaka),
                            const SizedBox(height: 16),
                            if (offer.pdfUrl.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.file_download),
                                    label: const Text('PDF İndir'),
                                    onPressed: () => viewModel.openPdfUrl(offer.pdfUrl),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                // Sigorta Teklifleri
                if (offer.offers != null && offer.offers!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Sigorta Teklifleri',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...offer.offers!.map((price) => _buildOfferPriceCard(price, viewModel, formatter)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

  Widget _buildOfferPriceCard(OfferPrice price, OfferViewModel viewModel, NumberFormat formatter) {
    // Fiyatı double'a çevirip formatlama
    double priceValue = 0;
    try {
      priceValue = double.parse(price.price);
    } catch (e) {
      // Hata durumunda 0 kullanılacak
    }

    // Taksit sayısını int'e çevir, hata durumunda 1 kullan
    int installmentCount = 1;
    try {
      installmentCount = int.parse(price.installment);
    } catch (e) {
      // Hata durumunda 1 taksit kullan
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                // Şirket logosu
                SizedBox(
                  width: 80,
                  height: 40,
                  child: Image.network(
                    price.image,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.business,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        price.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        price.shortDesc,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Taksit',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '${price.installment} taksit',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Fiyat',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      formatter.format(priceValue),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CardManualEntryView(
                        detailUrl: price.detailUrl,
                        offerId: int.parse(widget.offerId),
                        companyId: int.parse(price.companyID),
                        holderTC: '',
                        holderBD: '',
                        maxInstallment: installmentCount,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                ),
                child: const Text('İlerle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 