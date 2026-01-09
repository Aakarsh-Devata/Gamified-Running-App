import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/territory_service.dart';
import '../services/follow_service.dart';
import '../services/group_service.dart';
import '../providers/auth_provider.dart';
import 'dart:convert';
import 'dart:math';
import '../theme/futuristic_theme.dart';
import '../widgets/futuristic_widgets.dart';

class TerritoryScreen extends StatefulWidget {
  @override
  _TerritoryScreenState createState() => _TerritoryScreenState();
}

class _TerritoryScreenState extends State<TerritoryScreen> with SingleTickerProviderStateMixin {
  MapboxMap? _mapboxMap;
  List<Map<String, dynamic>> _territories = [];
  bool _isLoading = true;
  double _totalArea = 0;
  
  // Context Management
  bool _isDropdownOpen = false; // New State for Top Dropdown
  String _selectedContextId = 'personal'; 
  String _selectedContextName = 'Personal Stats';
  List<Map<String, dynamic>> _userGroups = [];
  List<Map<String, dynamic>> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
    _loadTerritories();
  }

  void _loadGroups() {
    GroupService.getUserGroups().listen((groups) {
      if (mounted) {
        setState(() {
          _userGroups = groups;
        });
      }
    });
  }

  Future<void> _loadTerritories() async {
    setState(() => _isLoading = true);
    _clearMapLayers(); 

    List<Map<String, dynamic>>? territories;
    List<Map<String, dynamic>>? leaderboardData;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.user?.uid;

    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    // 1. FETCH BASED ON CONTEXT
    if (_selectedContextId == 'personal') {
      territories = await TerritoryService.fetchUserTerritories();
    } else if (_selectedContextId == 'world') {
      final following = await FollowService.subscribeFollowing(uid).first;
      final uids = [uid, ...following];
      territories = await TerritoryService.fetchWorldTerritories(uids);
    } else {
      final group = _userGroups.firstWhere((g) => g['id'] == _selectedContextId, orElse: () => {});
      if (group.isNotEmpty) {
        final memberIds = List<String>.from(group['members'] ?? []);
        final result = await TerritoryService.fetchContextTerritories(memberIds);
        if (result != null) {
          territories = List<Map<String, dynamic>>.from(result['territories']);
          leaderboardData = List<Map<String, dynamic>>.from(result['leaderboard']);
        }
      }
    }
    
    // 2. PROCESS RESULTS
    if (territories != null) {
      double total = 0;
      for (var t in territories) {
        if (_selectedContextId == 'personal' || t['userId'] == uid) {
          total += (t['area_m2'] as num).toDouble();
        }
      }
      
      if (mounted) {
        setState(() {
          _territories = territories!;
          _leaderboard = leaderboardData ?? []; 
          _totalArea = total;
          _isLoading = false;
        });
        _drawTerritories();
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clearMapLayers() async {
     if (_mapboxMap != null) {
      try {
        final layersToRemove = ["territories-outline", "territories-fill", "my-territories-outline", "my-territories-fill", "other-territories-outline", "other-territories-fill"];
        final sourcesToRemove = ["territories-source", "my-territories-source", "other-territories-source"];

        for (final layer in layersToRemove) {
          if (await _mapboxMap!.style.styleLayerExists(layer)) await _mapboxMap!.style.removeStyleLayer(layer);
        }
        for (final source in sourcesToRemove) {
          if (await _mapboxMap!.style.styleSourceExists(source)) await _mapboxMap!.style.removeStyleSource(source);
        }
      } catch (e) {
        print("Error clearing map: $e");
      }
    }
  }


  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _mapboxMap!.location.updateSettings(
      LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData data) async {
    if (_territories.isNotEmpty) {
      await _drawTerritories();
    }
  }

  Future<void> _drawTerritories() async {
    if (_mapboxMap == null || _territories.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final myUid = authProvider.user?.uid;

    try {
      if (_selectedContextId == 'personal') {
        final features = _territories.map((t) => {
          "type": "Feature", "geometry": t['geojson'], "properties": {"id": t['id']}
        }).toList();

        await _mapboxMap?.style.addSource(GeoJsonSource(id: "territories-source", data: jsonEncode({"type": "FeatureCollection", "features": features})));
        await _mapboxMap?.style.addLayer(FillLayer(id: "territories-fill", sourceId: "territories-source", fillColor: Colors.blue.withOpacity(0.3).value, fillOpacity: 0.5));
        await _mapboxMap?.style.addLayer(LineLayer(id: "territories-outline", sourceId: "territories-source", lineColor: Colors.blue.value, lineWidth: 2.0));
      } else {
        final myTerritories = _territories.where((t) => t['userId'] == myUid).toList();
        final otherTerritories = _territories.where((t) => t['userId'] != myUid).toList();

        if (otherTerritories.isNotEmpty) {
           final features = otherTerritories.map((t) => {"type": "Feature", "geometry": t['geojson'], "properties": {"id": t['id']}}).toList();
           await _mapboxMap?.style.addSource(GeoJsonSource(id: "other-territories-source", data: jsonEncode({"type": "FeatureCollection", "features": features})));
           await _mapboxMap?.style.addLayer(FillLayer(id: "other-territories-fill", sourceId: "other-territories-source", fillColor: Colors.red.withOpacity(0.5).value, fillOpacity: 0.5));
           await _mapboxMap?.style.addLayer(LineLayer(id: "other-territories-outline", sourceId: "other-territories-source", lineColor: Colors.white.value, lineWidth: 1.0));
        }

        if (myTerritories.isNotEmpty) {
           final features = myTerritories.map((t) => {"type": "Feature", "geometry": t['geojson'], "properties": {"id": t['id']}}).toList();
           await _mapboxMap?.style.addSource(GeoJsonSource(id: "my-territories-source", data: jsonEncode({"type": "FeatureCollection", "features": features})));
           await _mapboxMap?.style.addLayer(FillLayer(id: "my-territories-fill", sourceId: "my-territories-source", fillColor: Colors.blue.withOpacity(0.5).value, fillOpacity: 0.6)); 
           await _mapboxMap?.style.addLayer(LineLayer(id: "my-territories-outline", sourceId: "my-territories-source", lineColor: Colors.white.value, lineWidth: 2.0));
        }
      }
    } catch (e) {
      print("Error drawing territories: $e");
    }
  }

  void _toggleDropdown() {
    setState(() => _isDropdownOpen = !_isDropdownOpen);
  }

  Widget _contextOption(String id, String label, IconData icon) {
    final isSelected = _selectedContextId == id;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedContextId = id;
          _selectedContextName = label;
          _isDropdownOpen = false;
        });
        _loadTerritories();
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1)))
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? FuturisticTheme.primaryCyan : Colors.white70, size: 20),
            SizedBox(width: 15),
            Expanded(child: Text(label, style: TextStyle(color: isSelected ? FuturisticTheme.primaryCyan : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
            if (isSelected) Icon(Icons.check, color: FuturisticTheme.primaryCyan, size: 18)
          ],
        ),
      ),
    );
  }

  void _showLeaderboard() {
    if (_leaderboard.isEmpty) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
       builder: (context) => Container(
        height: 400,
        decoration: BoxDecoration(
          color: FuturisticTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: FuturisticTheme.primaryCyan.withOpacity(0.3))
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("SQUAD LEADERBOARD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
             SizedBox(height: 20),
             Expanded(
               child: ListView.builder(
                 itemCount: _leaderboard.length,
                 itemBuilder: (context, index) {
                   final entry = _leaderboard[index];
                   final userId = entry['userId']; 
                   final area = TerritoryService.formatArea((entry['area'] as num).toDouble());
                   
                   return ListTile(
                     leading: CircleAvatar(
                       backgroundColor: FuturisticTheme.surface,
                       child: Text('${index + 1}', style: TextStyle(color: Colors.white)),
                     ),
                     title: Text(userId.substring(0, 8), style: TextStyle(color: Colors.white)), 
                     trailing: Text(area, style: TextStyle(color: FuturisticTheme.primaryCyan, fontWeight: FontWeight.bold)),
                   );
                 },
               ),
             )
          ],
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: GestureDetector(
          onTap: _toggleDropdown,
          child: GlassContainer(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_selectedContextName.toUpperCase(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Icon(_isDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16)
              ],
            ),
          ),
        ),
        actions: [
          if (_leaderboard.isNotEmpty)
             IconButton(
              icon: Icon(Icons.leaderboard, color: FuturisticTheme.secondaryViolet),
              onPressed: _showLeaderboard,
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadTerritories,
          ),
        ],
      ),
      body: Stack(
        children: [
           // 1. MAP LAYER
           _isLoading
                ? Center(child: CircularProgressIndicator())
                : MapWidget(
                    onMapCreated: _onMapCreated,
                    onStyleLoadedListener: _onStyleLoaded,
                    cameraOptions: CameraOptions(zoom: 12.0, center: Point(coordinates: Position(78.4004, 17.4428))),
                  ),
            
            // 2. STATS OVERLAY (Bottom Left)
            Positioned(
              bottom: 100,
              left: 20,
              child: GlassContainer(
                isStrong: true,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Icon(Icons.landscape, color: FuturisticTheme.primaryCyan, size: 20),
                     SizedBox(height: 4),
                     Text('MY AREA', style: TextStyle(color: FuturisticTheme.textGrey, fontSize: 10)),
                     Text(TerritoryService.formatArea(_totalArea), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

            // 3. TOP DROPDOWN OVERLAY (Group Selector)
            if (_isDropdownOpen)
              Positioned(
                top: kToolbarHeight + 50, // Below AppBar
                left: 20,
                right: 20,
                child: GlassContainer(
                  isStrong: true,
                  padding: EdgeInsets.all(0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(padding: EdgeInsets.all(16), child: Text("SELECT VIEW MODE", style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.5))),
                      _contextOption('personal', 'Personal Stats', Icons.person),
                      _contextOption('world', 'Friends (Turf War)', Icons.public),
                      if (_userGroups.isNotEmpty) ...[
                        Divider(color: Colors.white12, height: 1),
                        Padding(padding: EdgeInsets.all(12), child: Text("MY SQUADS", style: TextStyle(color: FuturisticTheme.primaryCyan, fontSize: 10, fontWeight: FontWeight.bold))),
                        ..._userGroups.map((g) => _contextOption(g['id'], g['name'] ?? 'Unnamed Group', Icons.group)).toList(),
                      ],
                      Divider(color: Colors.white12, height: 1),
                      InkWell(
                        onTap: () {
                          setState(() => _isDropdownOpen = false);
                          context.push('/create-group');
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          color: FuturisticTheme.secondaryViolet.withOpacity(0.1),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle, color: FuturisticTheme.secondaryViolet, size: 18),
                              SizedBox(width: 8),
                              Text("CREATE NEW SQUAD", style: TextStyle(color: FuturisticTheme.secondaryViolet, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
