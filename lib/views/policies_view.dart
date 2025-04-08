import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/offer_viewmodel.dart';
import '../viewmodels/policy_viewmodel.dart';
import '../models/policy_model.dart';
import 'notifications_view.dart';
import 'policy_detail_view.dart';
import 'webview_screen.dart';

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
          backgroundColor: const Color(0xFF1D3A70),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1D3A70),
            elevation: 0,
            title: const Text(
              'Poliçeler',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            leading: IconButton(
          icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
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
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _viewModel.selectedTabIndex == 0 ? const Color(0xFF4CAF50) : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(9),
                    bottomLeft: Radius.circular(9),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Aktif',
                    style: TextStyle(
                      color: _viewModel.selectedTabIndex == 0 ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _viewModel.selectedTabIndex == 1 ? const Color(0xFFFF7043) : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(9),
                    bottomRight: Radius.circular(9),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Pasif',
                    style: TextStyle(
                      color: _viewModel.selectedTabIndex == 1 ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
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
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildStatusColorSelector() {
    if (_viewModel.uniqueStatusColors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
     );
  }

  Widget _buildPoliciesContent() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
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
            size: 60,
            color: Colors.red[300],
          ),
          const SizedBox(height: 20),
          Text(
            'Bir hata oluştu',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              _viewModel.refreshPolicies();
            },
            child: const Text('Tekrar Dene'),
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
            size: 60,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            _viewModel.errorMessage,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _viewModel.errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
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
        padding: const EdgeInsets.all(16),
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
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(policy),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPolicyInfo(policy),
                  const SizedBox(height: 20),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          left: BorderSide(
            color: statusColor,
            width: 4,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Text(
                  policy.status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (policy.company.isNotEmpty && policy.company[0].logo.isNotEmpty)
            Container(
              height: 30,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4),
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
            fontSize: 18,
            color: Color(0xFF1D3A70),
          ),
        ),
        if (policy.customer.isNotEmpty && policy.customer[0].adiSoyadi.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(
                  Icons.person_outline, 
                  size: 16, 
                  color: Color(0xFF6E7491),
                ),
                const SizedBox(width: 6),
                Text(
                  policy.customer[0].adiSoyadi,
                  style: const TextStyle(
                    color: Color(0xFF6E7491),
                    fontSize: 15,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildPolicyDetailRow('Poliçe No', policy.policyNO, Icons.confirmation_number_outlined),
          const Divider(height: 16),
          if (policy.plaka.isNotEmpty) ...[
            _buildPolicyDetailRow('Plaka', policy.plaka, Icons.directions_car_outlined),
            const Divider(height: 16),
          ],
          _buildPolicyDetailRow('Başlangıç Tarihi', _formatDate(policy.startDate), Icons.event_outlined),
          const Divider(height: 16),
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
          size: 18,
          color: const Color(0xFF1D3A70),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6E7491),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
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