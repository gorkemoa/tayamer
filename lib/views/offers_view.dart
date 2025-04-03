import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/offer_viewmodel.dart';
import 'offer_detail_view.dart';
import 'webview_screen.dart';

class OffersView extends StatefulWidget {
  const OffersView({super.key});

  @override
  State<OffersView> createState() => _OffersViewState();
}

class _OffersViewState extends State<OffersView> {
  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında teklifleri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OfferViewModel>().loadOffers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text(
          'Teklifler',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
        ],
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
                    onPressed: () => viewModel.loadOffers(),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          } else if (viewModel.offers.isEmpty) {
            return const Center(child: Text('Henüz teklifiniz bulunmuyor'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: viewModel.offers.length,
              itemBuilder: (context, index) {
                final offer = viewModel.offers[index];
                
                // GENEL SOHBET (id: -1) için farklı tasarım kullan
                final isGeneralChat = offer.id.toString() == '-1';
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: isGeneralChat
                          ? Colors.grey[300]
                          : const Color(0xFF1E3A8A).withOpacity(0.8),
                        child: Icon(
                          isGeneralChat ? Icons.chat : Icons.directions_car,
                          color: isGeneralChat ? Colors.grey : Colors.white,
                        ),
                      ),
                      title: Text(
                        isGeneralChat ? offer.tcNo : offer.plaka,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(offer.code),
                          const SizedBox(height: 4),
                          if (!isGeneralChat && offer.statusText.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _parseColor(offer.statusColor, fallbackColor: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                offer.statusText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: isGeneralChat
                        ? const Icon(Icons.arrow_forward_ios)
                        : offer.chatUrl.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.chat_bubble_outline),
                              tooltip: 'Sohbeti Başlat',
                              color: Theme.of(context).primaryColor,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WebViewScreen(
                                      url: offer.chatUrl,
                                      title: 'Sohbet - ${offer.plaka}',
                                    ),
                                  ),
                                );
                              },
                            )
                          : const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                      onTap: () {
                        if (isGeneralChat) {
                          // GENEL SOHBET için WebView açılacak
                          if (offer.chatUrl.isNotEmpty) {
                             Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WebViewScreen(
                                  url: offer.chatUrl,
                                  title: 'Genel Sohbet',
                                ),
                              ),
                            );
                          } else {
                             // URL yoksa kullanıcıya bilgi ver
                             ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sohbet bağlantısı bulunamadı.')),
                            );
                          }
                        } else {
                          // Normal teklifler için detay sayfasına git
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OfferDetailView(
                                offerId: offer.id.toString(),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

Color _parseColor(String hexColor, {Color fallbackColor = Colors.black}) {
  try {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor"; // Opak alfa kanalı ekle
    }
    if (hexColor.length == 8) {
      return Color(int.parse("0x$hexColor"));
    }
  } catch (e) {
    // Hata durumunda konsola yazdır ve varsayılan rengi kullan
    debugPrint("Renk parse hatası: '$hexColor'. Hata: $e");
  }
  // Geçersiz format veya hata durumunda fallback rengi döndür
  return fallbackColor;
} 