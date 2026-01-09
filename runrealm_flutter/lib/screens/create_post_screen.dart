import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/social.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import '../services/club_service.dart';
import '../providers/auth_provider.dart';
import 'history_screen.dart';
import 'package:date_format/date_format.dart';
import '../widgets/run_map_preview.dart';

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  String _visibility = 'global'; // global, friends, club
  String? _selectedClubId;
  bool _isPosting = false;
  List<Club> _myClubs = [];
  Run? _attachedRun;

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.user?.uid;
    if (uid != null) {
      final profile = await UserService.getUserProfile(uid);
      if (profile?.clubsJoined != null && profile!.clubsJoined!.isNotEmpty) {
        final clubs = <Club>[];
        for (var clubId in profile.clubsJoined!) {
          final club = await ClubService.getClub(clubId);
          if (club != null) clubs.add(club);
        }
        if (mounted) {
          setState(() {
            _myClubs = clubs;
            if (_myClubs.isNotEmpty) {
              _selectedClubId = _myClubs.first.id;
            }
          });
        }
      }
    }
  }

  void _submitPost() async {
    if (_contentController.text.trim().isEmpty) return;
    if (_visibility == 'club' && _selectedClubId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a club')));
      return;
    }

    setState(() => _isPosting = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.user?.uid;

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: Not logged in')));
      setState(() => _isPosting = false);
      return;
    }

    final post = Post(
      authorUid: uid,
      content: _contentController.text.trim(),
      createdAt: Timestamp.now(),
      visibility: _visibility,
      clubId: _visibility == 'club' ? _selectedClubId : null,
      linkedRunId: _attachedRun?.id,
      likeCount: 0,
      commentCount: 0,
    );

    try {
      await PostService.createPost(post);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post created!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating post: $e')));
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Post'),
        actions: [
          IconButton(
            icon: _isPosting ? CircularProgressIndicator(color: Colors.white) : Icon(Icons.send),
            onPressed: _isPosting ? null : _submitPost,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text('Visibility: '),
                DropdownButton<String>(
                  value: _visibility,
                  items: [
                    DropdownMenuItem(value: 'global', child: Text('Global')),
                    DropdownMenuItem(value: 'friends', child: Text('Friends Only')),
                    DropdownMenuItem(value: 'club', child: Text('Club')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _visibility = val);
                  },
                ),
              ],
            ),
            if (_visibility == 'club')
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Text('Select Club: '),
                    _myClubs.isEmpty
                        ? Text('No clubs joined', style: TextStyle(color: Colors.red))
                        : DropdownButton<String>(
                            value: _selectedClubId,
                            items: _myClubs.map((club) {
                              return DropdownMenuItem(
                                value: club.id,
                                child: Text(club.name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedClubId = val);
                            },
                          ),
                  ],
                ),
              ),
            SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                hintText: 'What\'s on your mind?',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            SizedBox(height: 16),
            if (_attachedRun == null)
              OutlinedButton.icon(
                icon: Icon(Icons.directions_run),
                label: Text('Attach Run'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HistoryScreen(
                        selectionMode: true,
                        onRunSelected: (run) {
                          setState(() {
                            _attachedRun = run;
                          });
                        },
                      ),
                    ),
                  );
                },
              )
            else
              Card(
                color: Colors.blue.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Attached Run',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, size: 20),
                            onPressed: () {
                              setState(() {
                                _attachedRun = null;
                              });
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      RunMapPreview(run: _attachedRun!, height: 150),
                      SizedBox(height: 8),
                      Text('Date: ${formatDate(_attachedRun!.createdAt?.toDate() ?? DateTime.now(), [MM, ' ', dd, ', ', yyyy])}'),
                      SizedBox(height: 4),
                      Text('Distance: ${_attachedRun!.distance.toStringAsFixed(2)} km'),
                      Text('Time: ${_formatTime(_attachedRun!.time)}'),
                      Text('Pace: ${_attachedRun!.pace.toStringAsFixed(2)} min/km'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}:${s.toString().padLeft(2, '0')}';
  }
}
