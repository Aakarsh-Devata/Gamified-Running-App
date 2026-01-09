import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/social.dart';
import '../services/user_service.dart';
import '../services/follow_service.dart';
import '../services/club_service.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  final UserProfile? initialUser;

  const PublicProfileScreen({required this.userId, this.initialUser});

  @override
  _PublicProfileScreenState createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  UserProfile? _profile;
  bool _isLoading = true;
  String _followStatus = 'none'; // none, pending, accepted
  bool _isMe = false;
  
  @override
  void initState() {
    super.initState();
    _profile = widget.initialUser;
    _checkIfMe();
    _loadData();
  }

  void _checkIfMe() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.uid == widget.userId) {
      _isMe = true;
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // 1. Fetch Profile if needed
    if (_profile == null) {
      _profile = await UserService.getUserProfile(widget.userId);
    }

    // 2. Check Follow Status
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && !_isMe) {
      final status = await FollowService.checkFollowStatus(currentUser.uid, widget.userId);
      if (mounted) {
        setState(() => _followStatus = status);
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      if (_followStatus == 'accepted' || _followStatus == 'pending') {
        // Unfollow or Cancel Request
        await FollowService.unfollowUser(currentUser.uid, widget.userId);
        if (mounted) {
          setState(() => _followStatus = 'none');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unfollowed')));
        }
      } else {
        // Follow (Send Request)
        await FollowService.followUser(currentUser.uid, widget.userId);
        if (mounted) {
          setState(() => _followStatus = 'pending');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request Sent')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getButtonText() {
    switch (_followStatus) {
      case 'accepted': return 'Unfollow';
      case 'pending': return 'Requested';
      default: return 'Follow';
    }
  }

  Color _getButtonColor() {
    switch (_followStatus) {
      case 'accepted': return Colors.grey.shade300;
      case 'pending': return Colors.orange.shade100;
      default: return Colors.blue;
    }
  }

  Color _getButtonTextColor() {
    switch (_followStatus) {
      case 'accepted': return Colors.black;
      case 'pending': return Colors.orange.shade900;
      default: return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _profile == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(_profile?.displayName ?? 'Profile')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                (_profile?.displayName?.substring(0, 2) ?? '??').toUpperCase(),
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
              ),
            ),
            SizedBox(height: 16),
            
            // Name
            Text(
              _profile?.displayName ?? 'Unknown User',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            
            // City
            if (_profile?.city != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _profile!.city!,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),

            SizedBox(height: 24),

            // Follow Button (only if not me)
            if (!_isMe)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _toggleFollow,
                  child: Text(_getButtonText()),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: _getButtonColor(),
                    foregroundColor: _getButtonTextColor(),
                  ),
                ),
              ),
            
            SizedBox(height: 24),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statCard('${_profile?.totalRuns ?? 0}', 'Runs'),
                _statCard('${(_profile?.totalDistanceKm ?? 0).toStringAsFixed(1)}', 'km'),
              ],
            ),

            SizedBox(height: 24),

            // Clubs
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Clubs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  if (_profile?.clubsJoined?.isNotEmpty == true)
                    ..._profile!.clubsJoined!.map((clubId) => FutureBuilder<Club?>(
                      future: ClubService.getClub(clubId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(Icons.group, size: 16, color: Colors.grey),
                              SizedBox(width: 8),
                              Text(snapshot.data?.name ?? 'Unknown Club'),
                            ],
                          ),
                        );
                      },
                    )).toList()
                  else
                    Text('No clubs joined yet.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String value, String label) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}
