import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/futuristic_theme.dart';
import '../widgets/futuristic_widgets.dart';
import '../providers/auth_provider.dart';
import '../services/follow_service.dart';
import '../services/group_service.dart';

class CreateGroupScreen extends StatefulWidget {
  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final Set<String> _selectedUserIds = {};
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final uid = authProvider.user?.uid;

    return Scaffold(
      backgroundColor: FuturisticTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: GlowingText('NEW SQUAD', fontSize: 20),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: uid == null
          ? Center(child: Text("Please login", style: TextStyle(color: Colors.white)))
          : Column(
              children: [
                // 1. Group Name Input
                Padding(
                  padding: EdgeInsets.all(20),
                  child: GlassContainer(
                    child: TextField(
                      controller: _nameController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "SQUAD NAME (e.g. Weekend Warriors)",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                        prefixIcon: Icon(Icons.group, color: FuturisticTheme.primaryCyan),
                      ),
                    ),
                  ),
                ),

                // 2. Select Members Label
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        "SELECT MEMBERS",
                        style: TextStyle(
                          color: FuturisticTheme.textGrey,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Spacer(),
                      Text(
                        "${_selectedUserIds.length} SELECTED",
                        style: TextStyle(color: FuturisticTheme.primaryCyan),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),

                // 3. Friends List
                Expanded(
                  child: StreamBuilder<List<String>>(
                    stream: FollowService.subscribeFollowing(uid),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red)));
                      if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: FuturisticTheme.primaryCyan));

                      final friendIds = snapshot.data!;
                      if (friendIds.isEmpty) {
                        return Center(
                          child: Text(
                            "You are not following anyone yet.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: friendIds.length,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        itemBuilder: (context, index) {
                          final friendId = friendIds[index];
                          final isSelected = _selectedUserIds.contains(friendId);
                          
                          // TODO: Fetch user profile details for name/avatar. For now using ID.
                          
                          return Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedUserIds.remove(friendId);
                                  } else {
                                    _selectedUserIds.add(friendId);
                                  }
                                });
                              },
                              child: GlassContainer(
                                color: isSelected ? FuturisticTheme.primaryCyan.withOpacity(0.2) : null,
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: FuturisticTheme.surface,
                                      child: Icon(Icons.person, color: Colors.white),
                                    ),
                                    SizedBox(width: 15),
                                    Expanded(
                                      child: Text(
                                        friendId.substring(0, 8), // Show ID slice for now
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(Icons.check_circle, color: FuturisticTheme.primaryCyan)
                                    else
                                      Icon(Icons.circle_outlined, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // 4. Create Button
                Padding(
                  padding: EdgeInsets.all(20),
                  child: _isLoading
                      ? CircularProgressIndicator(color: FuturisticTheme.primaryCyan)
                      : NeonButton(
                          onPressed: _createGroup,
                          text: "CREATE SQUAD",
                          color: FuturisticTheme.secondaryViolet,
                          icon: Icons.add,
                        ),
                ),
              ],
            ),
    );
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter a group name")));
      return;
    }
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Select at least one friend")));
      return;
    }

    setState(() => _isLoading = true);

    final groupId = await GroupService.createGroup(name, _selectedUserIds.toList());

    setState(() => _isLoading = false);

    if (groupId != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Squad Created!"), backgroundColor: Colors.green));
        context.pop(); // Go back
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to create group")));
    }
  }
}
