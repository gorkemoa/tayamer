import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/offer_viewmodel.dart';
import '../models/offer_model.dart';
import 'package:intl/intl.dart';
import 'card_form_view.dart';

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
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
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
                  Text('Hata: ${viewModel.errorMessage}', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => viewModel.getOfferDetail(widget.offerId),
                    child: const Text('Tekrar Dene', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            );
          } else if (viewModel.selectedOffer == null) {
            return const Center(child: Text('Teklif bulunamadı', style: TextStyle(fontSize: 14)));
          }

          final offer = viewModel.selectedOffer!;
          final formatter = NumberFormat.currency(
            locale: 'tr_TR',
            symbol: '₺',
            decimalDigits: 2,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 0.8,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    iconColor: Theme.of(context).primaryColor,
                    collapsedIconColor: Colors.grey[500],
                    initiallyExpanded: true,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          offer.policyType,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0).copyWith(bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            _buildInfoRow('Teklif Kodu', offer.code, labelSize: 11, valueSize: 11),
                            _buildInfoRow('Plaka', offer.plaka, labelSize: 11, valueSize: 11),
                            const SizedBox(height: 8),
                            if (offer.pdfUrl.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 14),
                                    label: const Text('Teklifi Paylaş', style: TextStyle(fontSize: 11)),
                                    onPressed: () => viewModel.openPdfUrl(offer.pdfUrl),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.5)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3))
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                if (offer.offers != null && offer.offers!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Text(
                      'Sigorta Teklifleri',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700]
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...offer.offers!.map((price) => _buildOfferPriceCard(price, viewModel, formatter)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {double labelSize = 12, double valueSize = 12}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                fontSize: labelSize,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: valueSize,
                color: Colors.black87
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferPriceCard(OfferPrice price, OfferViewModel viewModel, NumberFormat formatter) {
    double priceValue = 0;
    try {
      priceValue = double.parse(price.price);
    } catch (e) {}

    int installmentCount = 1;
    try {
      installmentCount = int.parse(price.installment);
    } catch (e) {}

    return Card(
      margin: const EdgeInsets.only(bottom: 6, left: 1, right: 1),
      elevation: 0.8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 50,
                  height: 25,
                  child: price.image.isNotEmpty 
                      ? Image.network(
                          price.image,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.business_center_outlined,
                            size: 20,
                            color: Colors.grey,
                          ),
                        )
                      : const Icon(
                          Icons.business_center_outlined,
                          size: 20,
                          color: Colors.grey,
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        price.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      if(price.shortDesc.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          price.shortDesc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 0.5, thickness: 0.3),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Taksit',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '${price.installment} taksit',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
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
                        fontSize: 9,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      formatter.format(priceValue),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
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
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3))
                ),
                child: const Text('İlerle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 