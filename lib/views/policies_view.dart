import 'package:flutter/material.dart';

class PoliciesView extends StatelessWidget {
  const PoliciesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Poliçelerim',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: _buildEmptyPoliciesList(),
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