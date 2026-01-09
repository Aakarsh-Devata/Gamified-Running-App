import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/social.dart';
import '../services/user_service.dart';
import '../services/club_service.dart';
import 'public_profile_screen.dart';

class ClubDetailsScreen extends StatefulWidget {
  final Club club;

  const ClubDetailsScreen({required this.club});

  @override
  _ClubDetailsScreenState createState() => _ClubDetailsScreenState();
}

class _ClubDetailsScreenState extends State<ClubDetailsScreen> {
  bool _isMember = false;
  bool _isLoading = true;
  int _memberCount = 0;
  late Club _currentClub;

  @override
  void initState() {
    super.initState();
    _currentClub = widget.club;
    _memberCount = widget.club.memberCount ?? 0;
    _checkMembership();
  }

  Future<void> _checkMembership() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && widget.club.id != null) {
      final profile = await UserService.getUserProfile(user.uid);
      if (profile != null && profile.clubsJoined != null) {
        if (mounted) {
          setState(() {
            _isMember = profile.clubsJoined!.contains(widget.club.id);
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleMembership() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.club.id == null) return;

    setState(() => _isLoading = true);

    try {
      if (_isMember) {
        await ClubService.leaveClub(widget.club.id!, user.uid);
        if (mounted) {
          setState(() {
            _isMember = false;
            _memberCount--;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Left club')));
        }
      } else {
        await ClubService.joinClub(widget.club.id!, user.uid);
        if (mounted) {
          setState(() {
            _isMember = true;
            _memberCount++;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Joined club!')));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_currentClub.name)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _currentClub.logoURL != null ? NetworkImage(_currentClub.logoURL!) : null,
                child: _currentClub.logoURL == null ? Icon(Icons.group, size: 50) : null,
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                _currentClub.name,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                _currentClub.city ?? 'No City',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'About',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              _currentClub.description ?? 'No description available.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statCard('$_memberCount', 'Members'),
                // Placeholder for future stats like "Runs", "Events"
              ],
            ),
            SizedBox(height: 24),
            Text(
              'Members',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            if (_currentClub.id == null)
              Text('Error: Club ID missing')
            else
              FutureBuilder<List<UserProfile>>(
                // Re-fetch members when membership changes to update the list
                future: UserService.getMembersOfClub(_currentClub.id!), 
                builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final members = snapshot.data!;
                if (members.isEmpty) return Text('No members yet.');
                
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: members.map((user) {
                    return Tooltip(
                      message: user.displayName ?? 'Unknown',
                      child: InkWell(
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
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            (user.displayName?.substring(0, 2) ?? '??').toUpperCase(),
                            style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _toggleMembership,
                child: _isLoading 
                  ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isMember ? 'Leave Club' : 'Join Club'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _isMember ? Colors.grey.shade300 : Colors.blue,
                  foregroundColor: _isMember ? Colors.black : Colors.white,
                ),
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
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}
