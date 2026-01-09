import 'package:flutter/material.dart';
import '../models/social.dart';
import '../services/club_service.dart';
import 'create_club_screen.dart';
import 'club_details_screen.dart';

class ClubsScreen extends StatefulWidget {
  @override
  _ClubsScreenState createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen> {
  List<Club> _clubs = [];
  List<Club> _filteredClubs = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  void _loadClubs() async {
    final clubs = await ClubService.getAllClubs();
    setState(() {
      _clubs = clubs;
      _filteredClubs = clubs;
    });
  }

  void _filterClubs(String query) {
    setState(() {
      _search = query;
      if (query.isEmpty) {
        _filteredClubs = _clubs;
      } else {
        _filteredClubs = _clubs.where((club) =>
            club.name.toLowerCase().contains(query.toLowerCase()) ||
            (club.city?.toLowerCase().contains(query.toLowerCase()) ?? false)).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Run Clubs'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateClubScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search clubs or city',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterClubs,
            ),
          ),
          Expanded(
            child: _filteredClubs.isEmpty
                ? Center(child: Text('No clubs found 👀'))
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredClubs.length,
                    itemBuilder: (context, index) {
                      final club = _filteredClubs[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: club.logoURL != null ? NetworkImage(club.logoURL!) : null,
                            child: club.logoURL == null ? Icon(Icons.group) : null,
                          ),
                          title: Text(club.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(club.city ?? ''),
                              Text(club.description ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                              Text('${club.memberCount ?? 0} members'),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ClubDetailsScreen(club: club),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
