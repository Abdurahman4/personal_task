import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Task Statistics"),
      ),
      body: user == null
          ? const Center(child: Text("User not logged in"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('tasks')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tasks = snapshot.data!.docs;

                Map<String, int> counts = {
                  'completed': 0,
                  'pending': 0,
                  'uncompleted': 0,
                  'canceled': 0,
                };

                for (var task in tasks) {
                  final status = task['status'] ?? 'uncompleted';
                  if (counts.containsKey(status)) {
                    counts[status] = counts[status]! + 1;
                  }
                }

                final chartSections = counts.entries
                    .where((entry) => entry.value > 0)
                    .map((entry) => PieChartSectionData(
                          color: _getColor(entry.key),
                          value: entry.value.toDouble(),
                          title: '${entry.value} ${_getEmoji(entry.key)}',
                          radius: 60,
                          titleStyle: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ))
                    .toList();

                if (chartSections.isEmpty) {
                  return const Center(child: Text("No tasks available."));
                }

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        "Live Task Overview",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 300,
                        child: PieChart(
                          PieChartData(
                            sections: chartSections,
                            centerSpaceRadius: 40,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  static Color _getColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'uncompleted':
        return Colors.red;
      case 'canceled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  static String _getEmoji(String status) {
    switch (status) {
      case 'completed':
        return '✅';
      case 'pending':
        return '🕓';
      case 'uncompleted':
        return '❌';
      case 'canceled':
        return '🚫';
      default:
        return '❓';
    }
  }
}
