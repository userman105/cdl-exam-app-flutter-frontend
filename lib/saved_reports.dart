import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:convert';
import 'services/report_storage.dart'; // Assuming this file is in the same directory

// ===================================
// ReportHistoryScreen
// ===================================

class ReportHistoryScreen extends StatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = ReportCardPersistence.loadAllReportCards();
  }

  // Helper function to format duration from seconds
  String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  // Helper function to format the timestamp
  String _formatTimestamp(String isoString) {
    final dateTime = DateTime.parse(isoString).toLocal();
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Exam History",
          style: GoogleFonts.robotoSlab(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF64B2EF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _confirmClearReports,
            tooltip: "Clear All Reports",
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error loading reports: ${snapshot.error}"));
          }

          final reports = snapshot.data ?? [];

          if (reports.isEmpty) {
            return const Center(
              child: Text(
                "No exam reports saved yet.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // Sort by timestamp descending (most recent first)
          reports.sort((a, b) => b["timestamp"].compareTo(a["timestamp"]));

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return _buildReportCard(report);
            },
          );
        },
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final passed = (report["percentage"] as double) >= 60;
    final statusColor = passed ? Colors.green[700] : Colors.red[700];
    final correct = report["correctAnswers"] as int;
    final wrong = report["wrongAnswers"] as int;
    final total = correct + wrong;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Title and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    report["unitName"] ?? "Unit Exam",
                    style: GoogleFonts.robotoSlab(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor?.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor!),
                  ),
                  child: Text(
                    passed ? "PASSED" : "FAILED",
                    style: GoogleFonts.robotoSlab(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Row 2: Dashboard Name and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Dashboard: ${report["dashboardName"] ?? "N/A"}",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  _formatTimestamp(report["timestamp"] ?? DateTime.now().toIso8601String()),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const Divider(height: 20),

            // Row 3: Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  label: "Score",
                  value: "${(report["percentage"] as double).toStringAsFixed(1)}%",
                  color: statusColor,
                ),
                _buildStatColumn(
                  label: "Correct",
                  value: "$correct/$total",
                  color: Colors.green,
                ),
                _buildStatColumn(
                  label: "Wrong",
                  value: "$wrong/$total",
                  color: Colors.red,
                ),
                _buildStatColumn(
                  label: "Time",
                  value: _formatDuration(report["timeElapsedSeconds"] as int),
                  color: Colors.blueGrey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn({required String label, required String value, required Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.robotoSlab(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Future<void> _confirmClearReports() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear History"),
        content: const Text("Are you sure you want to delete all saved exam reports? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ReportCardPersistence.clearAllReports();
      setState(() {
        _reportsFuture = ReportCardPersistence.loadAllReportCards();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Exam history cleared.")),
        );
      }
    }
  }
}
