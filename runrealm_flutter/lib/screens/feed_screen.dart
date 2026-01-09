import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:date_format/date_format.dart';
import '../models/social.dart';
import '../providers/auth_provider.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import '../services/follow_service.dart';
import '../services/run_service.dart';
import 'public_profile_screen.dart';
import '../widgets/run_map_preview.dart';

class FeedScreen extends StatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Post> _posts = [];
  String _filter = 'global';
  Map<String, String> _authorCache = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  void _loadFeed() async {
    setState(() => _loading = true);
    Stream<List<Post>> stream;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.user?.uid;

    if (_filter == 'global') {
      stream = PostService.subscribeGlobalFeed();
    } else if (_filter == 'friends') {
      if (uid == null) {
        stream = Stream.value([]);
      } else {
        // Fetch following list first
        final following = await FollowService.subscribeFollowing(uid).first;
        stream = PostService.subscribeFriendsFeed(following);
      }
    } else {
      // Clubs
      if (uid == null) {
        stream = Stream.value([]);
      } else {
        // Fetch user profile to get clubs
        final profile = await UserService.getUserProfile(uid);
        if (profile?.clubsJoined != null && profile!.clubsJoined!.isNotEmpty) {
          stream = PostService.subscribeMultiClubFeed(profile.clubsJoined!);
        } else {
          stream = Stream.value([]);
        }
      }
    }

    stream.listen((posts) async {
      for (var post in posts) {
        if (!_authorCache.containsKey(post.authorUid)) {
          final profile = await UserService.getUserProfile(post.authorUid);
          _authorCache[post.authorUid] = profile?.displayName ?? post.authorUid;
        }
      }
      if (mounted) {
        setState(() {
          _posts = posts;
          _loading = false;
        });
      }
    });
  }

  void _changeFilter(String filter) {
    setState(() => _filter = filter);
    _loadFeed();
  }

  Widget _buildTag(String visibility) {
    Color color;
    String text;
    if (visibility == 'global') {
      color = Colors.blue;
      text = 'GLOBAL';
    } else if (visibility == 'friends') {
      color = Colors.purple;
      text = 'FRIENDS';
    } else {
      color = Colors.green;
      text = 'CLUB';
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Feed')),
      body: Column(
        children: [
          // Filter buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _filterButton('Global', 'global'),
              _filterButton('Friends', 'friends'),
              _filterButton('Clubs', 'clubs'),
            ],
          ),
          Expanded(
            child: _posts.isEmpty
                ? Center(child: Text('No posts to show'))
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      final post = _posts[index];
                      final authorName = _authorCache[post.authorUid] ?? post.authorUid;
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PublicProfileScreen(
                                            userId: post.authorUid,
                                            // We don't have the full profile object here easily without fetching, 
                                            // but PublicProfileScreen fetches it if initialUser is null.
                                          ),
                                        ),
                                      );
                                    },
                                    child: CircleAvatar(
                                      child: Text(authorName.substring(0, 2).toUpperCase()),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PublicProfileScreen(
                                            userId: post.authorUid,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(authorName, style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  Spacer(),
                                  _buildTag(post.visibility),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(post.content),
                              SizedBox(height: 4),
                              Text(
                                post.createdAt != null
                                    ? formatDate(post.createdAt!.toDate(), [MM, ' ', dd, ', ', HH, ':', nn])
                                    : 'Just now',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              if (post.linkedRunId != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: FutureBuilder<Run?>(
                                    future: RunService.getRun(post.linkedRunId!),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
                                      }
                                      if (snapshot.hasError || !snapshot.hasData) {
                                        return SizedBox.shrink();
                                      }
                                      final run = snapshot.data!;
                                      return Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.blue.withOpacity(0.2)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.directions_run, color: Colors.blue, size: 16),
                                                SizedBox(width: 4),
                                                Text('Attached Run', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                            RunMapPreview(run: run, height: 150),
                                            SizedBox(height: 8),
                                            Text('Distance: ${run.distance.toStringAsFixed(2)} km'),
                                            Text('Time: ${_formatTime(run.time)}'),
                                            Text('Pace: ${run.pace.toStringAsFixed(2)} min/km'),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterButton(String label, String filter) {
    final isActive = _filter == filter;
    return TextButton(
      onPressed: () => _changeFilter(filter),
      style: TextButton.styleFrom(
        backgroundColor: isActive ? Colors.blue : Colors.grey[200],
        foregroundColor: isActive ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}:${s.toString().padLeft(2, '0')}';
  }
}
