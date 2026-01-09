import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:date_format/date_format.dart';
import '../models/social.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import '../services/run_service.dart';
import '../services/follow_service.dart';
import '../services/club_service.dart';
import 'public_profile_screen.dart';
import 'create_post_screen.dart';
import 'follow_requests_screen.dart';
import 'follow_list_screen.dart';
import '../theme/futuristic_theme.dart';
import '../widgets/futuristic_widgets.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  List<Run> _runs = [];
  int _followersCount = 0;
  int _followingCount = 0;
  bool _loading = true;

  // Stream Subscriptions
  StreamSubscription<UserProfile?>? _profileSub;
  StreamSubscription<List<Run>>? _runsSub;
  StreamSubscription<List<String>>? _followersSub;
  StreamSubscription<List<String>>? _followingSub;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    _runsSub?.cancel();
    _followersSub?.cancel();
    _followingSub?.cancel();
    super.dispose();
  }

  void _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.user?.uid;
    if (uid == null) return;

    _profileSub = UserService.subscribeUserProfile(uid).listen((profile) {
      if (mounted) {
        setState(() {
          _profile = profile;
        });
      }
    });

    _runsSub = RunService.subscribeUserRuns(uid).listen((runs) {
      if (mounted) {
        setState(() {
          _runs = runs;
          _loading = false;
        });
      }
    }, onError: (e) {
      print("Error loading runs: $e");
      if (mounted) {
        setState(() => _loading = false);
      }
    });

    _followersSub = FollowService.subscribeFollowers(uid).listen((followers) {
      if (mounted) {
        setState(() {
          _followersCount = followers.length;
        });
      }
    });

    _followingSub = FollowService.subscribeFollowing(uid).listen((following) {
      if (mounted) {
        setState(() {
          _followingCount = following.length;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: FuturisticTheme.background,
        body: Center(child: CircularProgressIndicator(color: FuturisticTheme.primaryCyan)),
      );
    }

    final totalRuns = _runs.length;
    final totalDistance = _runs.fold<double>(0, (sum, r) => sum + r.distance);
    final totalTime = _runs.fold<int>(0, (sum, r) => sum + r.time);
    
    // Filter out runs with 0 distance or pace for stats
    final validRuns = _runs.where((r) => r.distance > 0 && r.pace > 0).toList();
    
    final longestRun = totalRuns > 0 ? _runs.map((r) => r.distance).reduce((a, b) => a > b ? a : b) : 0;
    
    // Fix: Filter out 0 pace values before finding min, otherwise 0 becomes best pace
    final bestPace = validRuns.isNotEmpty 
        ? validRuns.map((r) => r.pace).reduce((a, b) => a < b ? a : b) 
        : 0;
        
    final avgPace = totalDistance > 0 ? (totalTime / 60) / totalDistance : 0;
    
    final recentRun = _runs.isNotEmpty ? _runs.first : null;

    return Scaffold(
      backgroundColor: FuturisticTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: GlowingText('PROFILE', fontSize: 20),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: FuturisticTheme.primaryCyan),
            onPressed: () {
              showSearch(
                context: context,
                delegate: UserSearchDelegate(),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.person_add, color: FuturisticTheme.secondaryViolet),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FollowRequestsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            GlassContainer(
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: FuturisticTheme.neonGradient),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: FuturisticTheme.surface,
                      child: Text(
                        (_profile?.displayName?.substring(0, 2) ?? 'AA').toUpperCase(),
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: FuturisticTheme.primaryCyan),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_profile?.displayName ?? 'Runner', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 4),
                        Text('Member of ${_profile?.clubsJoined?.length ?? 0} clubs', style: TextStyle(color: FuturisticTheme.textGrey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Followers/Following
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statButton('Followers', '$_followersCount', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => FollowListScreen(userId: _profile!.uid, type: 'followers')));
                }),
                _statButton('Following', '$_followingCount', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => FollowListScreen(userId: _profile!.uid, type: 'following')));
                }),
              ],
            ),
            SizedBox(height: 20),
            // Summary
            Text('STATS OVERVIEW', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
            SizedBox(height: 10),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _summaryCard('$totalRuns', 'RUNS')),
                SizedBox(width: 10),
                Expanded(child: _summaryCard(totalDistance.toStringAsFixed(1), 'KM')),
                SizedBox(width: 10),
                Expanded(child: _summaryCard(_formatTime(totalTime), 'TIME')),
              ],
            ),
            SizedBox(height: 20),
            // Clubs
            Text('CLUBS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
            SizedBox(height: 10),
            GlassContainer(
              padding: EdgeInsets.all(16),
              child: _profile?.clubsJoined?.isNotEmpty == true
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _profile!.clubsJoined!.take(3).map((clubId) {
                        return FutureBuilder<Club?>(
                          future: ClubService.getClub(clubId),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return Padding(padding:EdgeInsets.symmetric(vertical:4), child:Text('• Loading...', style: TextStyle(color:Colors.grey)));
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  Icon(Icons.shield, size: 14, color: FuturisticTheme.secondaryViolet),
                                  SizedBox(width: 8),
                                  Text(snapshot.data?.name ?? 'Unknown Club', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            );
                          },
                        );
                      }).toList(),
                    )
                  : Text('You have not joined any clubs yet.', style: TextStyle(color: FuturisticTheme.textGrey)),
            ),
            SizedBox(height: 20),
            // Stats
            Text('RECORDS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
            SizedBox(height: 10),
            _statCard('Longest Run', '${longestRun.toStringAsFixed(2)} km'),
            _statCard('Best Pace', '${bestPace.toStringAsFixed(2)} min/km'),
            _statCard('Average Pace', '${avgPace.toStringAsFixed(2)} min/km'),
            if (recentRun != null) ...[
              SizedBox(height: 10),
              _statCard('Most Recent Run',
                  'Date: ${formatDate(recentRun.createdAt?.toDate() ?? DateTime.now(), [MM, ' ', dd, ', ', yyyy])}\n'
                  'Distance: ${recentRun.distance.toStringAsFixed(2)} km\n'
                  'Time: ${_formatTime(recentRun.time)}\n'
                  'Pace: ${recentRun.pace.toStringAsFixed(2)} min/km'),
            ],
            SizedBox(height: 20),
            NeonButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreatePostScreen()),
                );
              },
              text: 'CREATE POST',
              icon: Icons.edit,
              color: FuturisticTheme.primaryCyan,
            ),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _statButton(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: GlassContainer(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(label, style: TextStyle(color: FuturisticTheme.textGrey)),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String value, String label) {
    return GlassContainer(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FuturisticTheme.primaryCyan)),
          SizedBox(height: 4),
          Text(label, style: TextStyle(color: FuturisticTheme.textGrey, fontSize: 10, letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: FuturisticTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: FuturisticTheme.secondaryViolet)),
          SizedBox(height: 4),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }
}

class UserSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return Center(child: Text('Search for users...'));
    }

    return FutureBuilder<List<UserProfile>>(
      future: UserService.searchUsers(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return Center(child: Text('No users found.'));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withOpacity(0.3),
                child: Text(
                  (user.displayName?.substring(0, 2) ?? '??').toUpperCase(),
                  style: TextStyle(color: Colors.blue),
                ),
              ),
              title: Text(user.displayName ?? 'Unknown'),
              subtitle: Text(user.city ?? 'No city'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PublicProfileScreen(
                      userId: user.uid,
                      initialUser: user,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
