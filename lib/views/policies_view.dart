import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/offer_viewmodel.dart';
import '../viewmodels/policy_viewmodel.dart';
import '../models/policy_model.dart';
import 'notifications_view.dart';
import 'policy_detail_view.dart';
import 'webview_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class PoliciesView extends StatefulWidget {
  const PoliciesView({super.key});

  @override
  State<PoliciesView> createState() => _PoliciesViewState();
}

class _PoliciesViewState extends State<PoliciesView> {
  late PolicyViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel = Provider.of<PolicyViewModel>(context, listen: false);
      _viewModel.fetchPolicies();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PolicyViewModel>(
      builder: (context, viewModel, child) {
        _viewModel = viewModel;
        return Scaffold(
          backgroundColor: Theme.of(context).primaryColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).primaryColor,
            elevation: 0,
            title: const Text(
              'Poliçeler',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            leading:  IconButton(
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
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
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
          body: Column(
            children: [
              _buildTabSelector(),
              _buildStatusIDSelector(),
              _buildStatusColorSelector(),
              Expanded(
                child: _buildPoliciesContent(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                _viewModel.selectedTabIndex = 0;
                _viewModel.selectedStatusID = null;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: _viewModel.selectedTabIndex == 0 ? const Color(0xFF4CAF50) : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(7),
                    bottomLeft: Radius.circular(7),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Aktif',
                    style: TextStyle(
                      color: _viewModel.selectedTabIndex == 0 ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                _viewModel.selectedTabIndex = 1;
                _viewModel.selectedStatusID = null;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: _viewModel.selectedTabIndex == 1 ? const Color(0xFFFF7043) : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(7),
                    bottomRight: Radius.circular(7),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Pasif',
                    style: TextStyle(
                      color: _viewModel.selectedTabIndex == 1 ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIDSelector() {
    if (_viewModel.statusIDList.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildStatusColorSelector() {
    if (_viewModel.uniqueStatusColors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
     );
  }

  Widget _buildPoliciesContent() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: _viewModel.state == PolicyViewState.loading
          ? _buildLoadingIndicator()
          : _viewModel.state == PolicyViewState.error
              ? _buildErrorView()
              : Column(
                  children: [
                    _buildStatusIDSelector(),
                    _buildStatusColorSelector(),
                    Expanded(
                      child: _viewModel.isCurrentTabEmpty
                          ? _buildEmptyPoliciesList()
                          : _buildPoliciesList(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 40,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Bir hata oluştu',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              _viewModel.refreshPolicies();
            },
            child: const Text('Tekrar Dene', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPoliciesList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.file_copy_outlined,
            size: 40,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _viewModel.errorMessage,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _viewModel.errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoliciesList() {
    final policies = _viewModel.getFilteredPolicies();
    return RefreshIndicator(
      onRefresh: _viewModel.refreshPolicies,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        itemCount: policies.length,
        itemBuilder: (context, index) {
          return _buildPolicyCard(policies[index]);
        },
      ),
    );
  }

  Widget _buildPolicyCard(Policy policy) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PolicyDetailView(policyId: policy.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(policy),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPolicyInfo(policy),
                  const SizedBox(height: 12),
                  _buildPolicyDetails(policy),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(Policy policy) {
    // ViewModel'in renk metodunu kullan
    Color statusColor = _viewModel.getStatusColorAsColor(policy.statusColor);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          left: BorderSide(
            color: statusColor,
            width: 3,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Text(
                  policy.status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          if (policy.company.isNotEmpty && policy.company[0].logo.isNotEmpty)
            Container(
              height: 20,
              width: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2),
              child: Image.network(
                policy.company[0].logo,
                fit: BoxFit.contain,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPolicyInfo(Policy policy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          policy.policyType,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF1D3A70),
          ),
        ),
        if (policy.customer.isNotEmpty && policy.customer[0].adiSoyadi.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.person_outline, 
                  size: 13, 
                  color: Color(0xFF6E7491),
                ),
                const SizedBox(width: 4),
                Text(
                  policy.customer[0].adiSoyadi,
                  style: const TextStyle(
                    color: Color(0xFF6E7491),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPolicyDetails(Policy policy) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          _buildPolicyDetailRow('Poliçe No', policy.policyNO, Icons.confirmation_number_outlined),
          const Divider(height: 12, thickness: 0.5),
          if (policy.plaka.isNotEmpty) ...[
            _buildPolicyDetailRow('Plaka', policy.plaka, Icons.directions_car_outlined),
            const Divider(height: 12, thickness: 0.5),
          ],
          _buildPolicyDetailRow('Başlangıç Tarihi', _formatDate(policy.startDate), Icons.event_outlined),
          const Divider(height: 12, thickness: 0.5),
          _buildPolicyDetailRow('Bitiş Tarihi', _formatDate(policy.endDate), Icons.event_outlined),
        ],
      ),
    );
  }

  Widget _buildPolicyDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: const Color(0xFF1D3A70),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6E7491),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: Color(0xFF1D3A70),
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  void _launchUrl(String url) {
    // URL açma işlemi burada yapılacak
    // URL Launcher paketi kullanılabilir
    print('URL açılıyor: $url');
  }
} 