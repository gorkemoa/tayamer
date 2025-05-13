import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/offer_viewmodel.dart';
import 'offer_detail_view.dart';
import 'webview_screen.dart';
import 'notifications_view.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          'Teklifler',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(FontAwesomeIcons.comments, color: Colors.white),
          onPressed: () {
            final viewModel = context.read<OfferViewModel>();
            // Genel sohbet teklifini (id: -1) bul
            // Teklif listesi boşsa veya id -1 içermiyorsa try-catch kullan
            try {
              final generalChatOffer = viewModel.offers.firstWhere(
                (offer) => offer.id.toString() == '-1',
              );

              if (generalChatOffer.chatUrl.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WebViewScreen(
                      url: generalChatOffer.chatUrl,
                      title: 'Genel Sohbet',
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Genel sohbet bağlantısı bulunamadı.')),
                );
              }
            } catch (e) {
              // Teklifin bulunamadığı durumları ele al
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Genel sohbet şu anda mevcut değil.')),
              );
              debugPrint("Genel sohbet offer bulunamadı: $e");
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.bell, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsView(),
                ),
              );
            },
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
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            child: ListView.builder(
              itemCount: viewModel.offers.length,
              itemBuilder: (context, index) {
                final offer = viewModel.offers[index];
                
                final isGeneralChat = offer.id.toString() == '-1';
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      leading: Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: Center(
                            child: isGeneralChat 
                              ? Icon(
                                    FontAwesomeIcons.comments,
                                    color: Colors.grey[700],
                                    size: 18,
                                  )
                              : offer.chatUrl.isNotEmpty
                                ? IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      FontAwesomeIcons.comments,
                                      color: Theme.of(context).primaryColor,
                                      size: 18,
                                    ),
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
                                : CircleAvatar( 
                                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.7),
                                    radius: 14,
                                    child: const Icon(
                                      Icons.directions_car,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      title: Text(
                        isGeneralChat ? offer.tcNo : offer.plaka,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(offer.code, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          const SizedBox(height: 3),
                          if (!isGeneralChat && offer.statusText.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: _parseColor(offer.statusColor, fallbackColor: Colors.grey),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                offer.statusText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: isGeneralChat
                        ? Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600])
                        : null, 
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