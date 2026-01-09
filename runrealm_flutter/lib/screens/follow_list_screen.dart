import 'dart:async';
import 'package:flutter/material.dart';
import '../models/social.dart';
import '../services/user_service.dart';
import '../services/follow_service.dart';
import 'public_profile_screen.dart';

class FollowListScreen extends StatefulWidget {
  final String userId;
  final String type; // 'followers' or 'following'

  const FollowListScreen({
    required this.userId,
    required this.type,
  });

  @override
  _FollowListScreenState createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  List<UserProfile> _allUsers = [];
  List<UserProfile> _filteredUsers = [];
  bool _loading = true;
  String _searchQuery = '';
  StreamSubscription? _subscription;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterUsers();
    });
  }

  void _filterUsers() {
    if (_searchQuery.isEmpty) {
      _filteredUsers = List.from(_allUsers);
    } else {
      _filteredUsers = _allUsers.where((user) {
        final name = user.displayName?.toLowerCase() ?? '';
        return name.contains(_searchQuery);
      }).toList();
    }
  }

  void _loadData() {
    Stream<List<String>> stream;
    if (widget.type == 'followers') {
      stream = FollowService.subscribeFollowers(widget.userId);
    } else {
      stream = FollowService.subscribeFollowing(widget.userId);
    }

    _subscription = stream.listen((uids) async {
      if (uids.isEmpty) {
        if (mounted) {
          setState(() {
            _allUsers = [];
            _filteredUsers = [];
            _loading = false;
          });
        }
        return;
      }

      try {
        final users = await UserService.getUsers(uids);
        if (mounted) {
          setState(() {
            _allUsers = users;
            _filterUsers();
            _loading = false;
          });
        }
      } catch (e) {
        print("Error loading users: $e");
        if (mounted) {
          setState(() => _loading = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == 'followers' ? 'Followers' : 'Following';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search $title...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No users found.'
                              : 'No matches found.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.withOpacity(0.3),
                              child: Text(
                                (user.displayName?.substring(0, 2) ?? '??')
                                    .toUpperCase(),
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
                      ),
          ),
        ],
      ),
    );
  }
}
