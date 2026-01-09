import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:date_format/date_format.dart';
import '../models/social.dart';
import '../providers/auth_provider.dart';
import '../services/run_service.dart';
import 'run_details_screen.dart';

class HistoryScreen extends StatelessWidget {
  final bool selectionMode;
  final Function(Run)? onRunSelected;

  const HistoryScreen({
    this.selectionMode = false,
    this.onRunSelected,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.user?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(selectionMode ? 'Select Run' : 'History')),
        body: Center(child: Text('Please log in to view history.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(selectionMode ? 'Select Run' : 'History')),
      body: StreamBuilder<List<Run>>(
        stream: RunService.subscribeUserRuns(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading history: ${snapshot.error}'));
          }

          final runs = snapshot.data ?? [];

          if (runs.isEmpty) {
            return Center(child: Text('No runs recorded yet.'));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: runs.length,
            itemBuilder: (context, index) {
              final run = runs[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(formatDate(run.createdAt?.toDate() ?? DateTime.now(), [MM, ' ', dd, ', ', yyyy, ' ', HH, ':', nn])),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🏃 Distance: ${run.distance.toStringAsFixed(2)} km'),
                      Text('⏱ Time: ${_formatTime(run.time)}'),
                      Text('⚡ Pace: ${run.pace.toStringAsFixed(2)} min/km'),
                    ],
                  ),
                  onTap: () {
                    if (selectionMode && onRunSelected != null) {
                      onRunSelected!(run);
                      Navigator.pop(context);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RunDetailsScreen(run: run),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}:${s.toString().padLeft(2, '0')}';
  }
}
