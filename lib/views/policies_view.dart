import 'package:flutter/material.dart';

class PoliciesView extends StatefulWidget {
  const PoliciesView({super.key});

  @override
  State<PoliciesView> createState() => _PoliciesViewState();
}

class _PoliciesViewState extends State<PoliciesView> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
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
          icon: const Icon(Icons.chat_outlined, color: Colors.white),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
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
                      setState(() {
                        _selectedTabIndex = 0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 0 ? const Color(0xFF4CAF50) : Colors.transparent,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(9),
                          bottomLeft: Radius.circular(9),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Aktif',
                          style: TextStyle(
                            color: _selectedTabIndex == 0 ? Colors.white : Colors.black,
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
                      setState(() {
                        _selectedTabIndex = 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 1 ? const Color(0xFFFF7043) : Colors.transparent,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(9),
                          bottomRight: Radius.circular(9),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Pasif',
                          style: TextStyle(
                            color: _selectedTabIndex == 1 ? Colors.white : Colors.black,
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
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: _buildPoliciesContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoliciesContent() {
    return _buildEmptyPoliciesList();
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
            'Henüz bir poliçeniz bulunmuyor',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Yeni bir teklif oluşturun ve onaylayarak poliçeye dönüştürün.',
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
} 