import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:date_format/date_format.dart';
import '../theme/futuristic_theme.dart';
import '../widgets/futuristic_widgets.dart';
import '../providers/auth_provider.dart';
import '../services/run_service.dart';
import '../models/social.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Run> _runs = [];
  bool _loading = true;
  StreamSubscription<List<Run>>? _runsSub;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.user?.uid;
    
    if (uid != null) {
      _runsSub = RunService.subscribeUserRuns(uid).listen((runs) {
        if (mounted) {
          setState(() {
            _runs = runs;
            _loading = false;
          });
        }
      }, onError: (e) {
        if (mounted) setState(() => _loading = false);
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _runsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    
    // Calculate Stats
    final totalDistance = _runs.fold<double>(0, (sum, run) => sum + run.distance);
    final runCount = _runs.length;
    
    // Recent activity (take top 2)
    final recentRuns = _runs.take(2).toList();
    
    return Scaffold(
      backgroundColor: FuturisticTheme.background,
      body: Stack(
        children: [
          // Background Gradient effect
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: FuturisticTheme.primaryCyan.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: FuturisticTheme.primaryCyan.withOpacity(0.2),
                    blurRadius: 100,
                    spreadRadius: 50,
                  )
                ]
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GlowingText('RUNREALM', fontSize: 28),
                          SizedBox(height: 4),
                          Text(
                            user?.displayName != null ? 'WELCOME BACK, ${user!.displayName!.toUpperCase()}' : 'READY TO DOMINATE?',
                            style: TextStyle(
                              color: FuturisticTheme.textGrey,
                              letterSpacing: 1.5,
                              fontSize: 12
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: FuturisticTheme.neonGradient,
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: FuturisticTheme.surface,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                      )
                    ],
                  ),
                  
                  SizedBox(height: 40),
                  
                  // MAIN ACTION
                  GlassContainer(
                    isStrong: true,
                    child: Column(
                      children: [
                        Text(
                          'START YOUR RUN',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 20),
                        NeonButton(
                          text: 'GO NOW',
                          icon: Icons.play_arrow,
                          onPressed: () => context.go('/run'),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Territory War Active • 2X Points',
                          style: TextStyle(color: FuturisticTheme.primaryCyan, fontSize: 12),
                        )
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 30),
                  
                  // STATS ROW
                  Text(
                    'LIFETIME STATS',
                    style: TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2
                    ),
                  ),
                  SizedBox(height: 15),
                  if (_loading) 
                    Center(child: CircularProgressIndicator(color: FuturisticTheme.primaryCyan))
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'DISTANCE',
                            value: totalDistance.toStringAsFixed(1),
                            unit: 'km',
                            color: FuturisticTheme.primaryCyan,
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: _StatCard(
                            label: 'RUNS',
                            value: '$runCount',
                            unit: 'total',
                            color: FuturisticTheme.secondaryViolet,
                          ),
                        ),
                      ],
                    ),
                  
                  SizedBox(height: 30),
                  
                  // RECENT ACTIVITY
                  Text(
                    'RECENT DROPS',
                    style: TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2
                    ),
                  ),
                  SizedBox(height: 15),
                  if (_loading)
                     Center(child: CircularProgressIndicator(color: FuturisticTheme.primaryCyan))
                  else if (recentRuns.isEmpty)
                     Text("No recent runs yet. Go for it!", style: TextStyle(color: Colors.grey))
                  else
                    ...recentRuns.map((run) => Column(
                      children: [
                        _ActivityItem(
                          title: 'Run on ${formatDate(run.createdAt?.toDate() ?? DateTime.now(), [MM, ' ', dd])}',
                          subtitle: '${run.distance.toStringAsFixed(2)} km • ${run.pace.toStringAsFixed(2)} min/km',
                          time: formatDate(run.createdAt?.toDate() ?? DateTime.now(), [HH, ':', nn]),
                        ),
                        SizedBox(height: 10),
                      ],
                    )).toList(),
                  
                  SizedBox(height: 100), // Bottom padding for nav bar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: 6)]),
              ),
              SizedBox(width: 8),
              Text(label, style: TextStyle(color: FuturisticTheme.textGrey, fontSize: 10, letterSpacing: 1.5)),
            ],
          ),
          SizedBox(height: 12),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(unit, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;

  const _ActivityItem({required this.title, required this.subtitle, required this.time});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.directions_run, color: FuturisticTheme.primaryCyan),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: FuturisticTheme.textGrey, fontSize: 12)),
              ],
            ),
          ),
          Text(time, style: TextStyle(color: FuturisticTheme.textGrey, fontSize: 12)),
        ],
      ),
    );
  }
}
