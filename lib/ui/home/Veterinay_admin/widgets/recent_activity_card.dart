import 'package:flutter/material.dart';

class RecentActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;

  const RecentActivityCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 500;

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.green.shade200),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: const Icon(Icons.history, color: Colors.green),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: isWide ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade900,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: isWide ? 14 : 12, color: Colors.grey.shade700),
        ),
        trailing: Text(
          date,
          style: TextStyle(
            fontSize: isWide ? 13 : 11,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
