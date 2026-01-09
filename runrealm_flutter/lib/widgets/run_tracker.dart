import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/social.dart';
import '../providers/auth_provider.dart';
import '../services/run_service.dart';
import '../services/territory_service.dart';
import '../theme/futuristic_theme.dart';
import '../widgets/futuristic_widgets.dart';

class RunTracker extends StatefulWidget {
  @override
  _RunTrackerState createState() => _RunTrackerState();
}

class _RunTrackerState extends State<RunTracker> {
  MapboxMap? _mapboxMap;
  geo.Position? _currentPosition;
  List<List<double>> _pathPoints = []; // Mapbox uses [lng, lat]
  double _distance = 0;
  int _elapsedTime = 0;
  bool _isRunning = false;
  bool _runStopped = false;
  bool _initialLocating = true; // New flag
  Timer? _timer;
  StreamSubscription<geo.Position>? _positionStream;
  
  final String _pathSourceId = "path-source";
  final String _pathLayerId = "path-layer";
  bool _isLayerAdded = false;

  @override
  void initState() {
    super.initState();
    _determineInitialPosition();
  }

  Future<void> _determineInitialPosition() async {
    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled don't continue
        return;
      }

      var permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          return;
        }
      }
      
      if (permission == geo.LocationPermission.deniedForever) {
        return;
      }

      final position = await geo.Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _initialLocating = false;
        });
      }
    } catch (e) {
      print("Error getting initial location: $e");
      if (mounted) setState(() => _initialLocating = false); // Fail open to default
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _mapboxMap!.location.updateSettings(
      LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData data) async {
    await _initMapLayers();
  }

  Future<void> _initMapLayers() async {
    if (_mapboxMap == null) return;
    final emptyGeoJson = {'type': 'FeatureCollection', 'features': []};

    try {
      await _mapboxMap!.style.addSource(
        GeoJsonSource(id: _pathSourceId, data: json.encode(emptyGeoJson)),
      );
      await _mapboxMap!.style.addLayer(
        LineLayer(
          id: _pathLayerId,
          sourceId: _pathSourceId,
          lineColor: FuturisticTheme.primaryCyan.value, // NEON CYAN TRAIL
          lineWidth: 5.0,
          lineOpacity: 0.9,
          lineJoin: LineJoin.ROUND,
          lineCap: LineCap.ROUND,
          lineBlur: 2.0, // Mild glow effect
        ),
      );
      _isLayerAdded = true;
    } catch (e) {
      debugPrint("Error adding layers: $e");
    }
  }

  Future<void> _updateTrailPath() async {
    if (!mounted || _mapboxMap == null || !_isLayerAdded) return;
    final geoJsonData = {
      'type': 'Feature',
      'geometry': {'type': 'LineString', 'coordinates': _pathPoints},
    };
    try {
      await _mapboxMap!.style.setStyleSourceProperty(
        _pathSourceId,
        'data',
        json.encode(geoJsonData),
      );
    } catch (e) {}
  }

  Future<void> _startRun() async {
    try {
      // Permission checks already done in init, but good to be safe
      final position = await geo.Geolocator.getCurrentPosition();
      if (!mounted) return;
      
      setState(() {
        _currentPosition = position;
        _pathPoints = [[position.longitude, position.latitude]];
        _distance = 0;
        _elapsedTime = 0;
        _isRunning = true;
        _runStopped = false;
      });

      _positionStream = geo.Geolocator.getPositionStream(
        locationSettings: geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((position) {
        setState(() {
          _currentPosition = position;
          _pathPoints.add([position.longitude, position.latitude]);
        });
        _updateDistance();
        _updateTrailPath();
        
        _mapboxMap?.flyTo(
          CameraOptions(
            center: Point.fromJson({
              'type': 'Point',
              'coordinates': [position.longitude, position.latitude],
            }),
            zoom: 16.0,
            pitch: 45.0, // Tilted view for 3D feel
          ),
          MapAnimationOptions(duration: 800),
        );

      }, onError: (e) {
        print('Location stream error: $e');
      });

      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _elapsedTime++;
        });
      });
    } catch (e) {
      print('Error starting run: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error starting run: $e')));
      }
    }
  }

  void _stopRun() {
    _timer?.cancel();
    _positionStream?.cancel();
    setState(() {
      _isRunning = false;
      _runStopped = true;
    });
  }

  Future<void> _saveRun() async {
    if (_pathPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No run data to save')));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.user?.uid;
    if (uid == null) return;

    final distanceKm = _distance / 1000;
    final pace = distanceKm > 0 ? (_elapsedTime / 60) / distanceKm : 0;

    final run = Run(
      uid: uid,
      distance: distanceKm,
      time: _elapsedTime,
      pace: pace.toDouble(),
      path: _pathPoints.map((p) => {
        'latitude': (p[1] as num).toDouble(),
        'longitude': (p[0] as num).toDouble(),
      }).toList(),
      createdAt: Timestamp.now(),
    );

    try {
      // Save run to Firebase
      final runId = await RunService.saveRun(run);
      await RunService.updateUserStats(uid, distanceKm);
      
      // Show initial success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Run saved successfully ✅ Calculating territory...'))
      );
      
      // Call territory API to calculate area
      if (runId != null) {
        final territoryResult = await TerritoryService.createTerritory(
          runId: runId,
          path: run.path,
        );
        
        if (territoryResult != null && territoryResult['ok'] == true) {
          final area = territoryResult['area_m2'] as double;
          final formattedArea = TerritoryService.formatArea(area);
          
          // Show success with calculated area
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Territory created! Area: $formattedArea'),
              duration: Duration(seconds: 4),
              backgroundColor: Colors.green,
            )
          );
        } else {
          print('Territory calculation failed, but run was saved');
        }
      }
      
      setState(() {
        _pathPoints = [];
        _distance = 0;
        _elapsedTime = 0;
        _isRunning = false;
        _runStopped = false;
        _currentPosition = null;
      });
      _updateTrailPath(); // Clear map
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving run')));
    }
  }

  void _updateDistance() {
    if (_pathPoints.length > 1) {
      final lastTwo = _pathPoints.sublist(_pathPoints.length - 2);
      final distanceCalc = latlong.Distance();
      final dist = distanceCalc.as(
        latlong.LengthUnit.Meter,
        latlong.LatLng(lastTwo[0][1], lastTwo[0][0]), // lat, lng
        latlong.LatLng(lastTwo[1][1], lastTwo[1][0]), // lat, lng
      );
      setState(() {
        _distance += dist;
      });
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLocating) {
      return Center(
        child: GlassContainer(
          isStrong: true,
          padding: EdgeInsets.all(24),
           child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: FuturisticTheme.primaryCyan),
              SizedBox(height: 16),
              Text('LOCATING SATELLITES...', style: TextStyle(color: FuturisticTheme.primaryCyan, letterSpacing: 1.2)),
            ],
          ),
        )
      );
    }
  
    final pace = _distance > 0 ? (_elapsedTime / 60) / (_distance / 1000) : 0;

    return Stack(
      children: [
        MapWidget(
          key: const ValueKey("mapWidget"),
          onMapCreated: _onMapCreated,
          onStyleLoadedListener: _onStyleLoaded,
          styleUri: MapboxStyles.DARK, 
          cameraOptions: CameraOptions(
            center: Point.fromJson({
              'type': 'Point',
              'coordinates': [
                _currentPosition?.longitude ?? -122.4194,
                _currentPosition?.latitude ?? 37.7749,
              ],
            }),
            zoom: 15.0,
          ),
        ),
        
        // --- STATS OVERLAY ---
        Positioned(
          top: 50,
          left: 16,
          right: 16,
          child: GlassContainer(
            isStrong: false,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('DISTANCE', '${(_distance / 1000).toStringAsFixed(2)}', 'km'),
                Container(width: 1, height: 40, color: Colors.white24),
                _buildStatItem('TIME', _formatTime(_elapsedTime), 'min'),
                Container(width: 1, height: 40, color: Colors.white24),
                _buildStatItem('PACE', pace.toStringAsFixed(2), 'm/km'),
              ],
            ),
          ),
        ),
        
        // --- CONTROLS ---
        Positioned(
          bottom: 120, // Move up because of bottom nav bar
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isRunning && !_runStopped)
                NeonButton(
                  onPressed: _startRun,
                  text: 'START RUN',
                  icon: Icons.play_arrow,
                  color: FuturisticTheme.primaryCyan,
                ),
                
              if (_isRunning)
                 NeonButton(
                  onPressed: _stopRun,
                  text: 'PAUSE',
                  icon: Icons.pause,
                  color: FuturisticTheme.secondaryViolet, // Violet for pause/stop
                ),
                
              if (!_isRunning && _runStopped) ...[
                 NeonButton(
                  onPressed: _startRun,
                  text: 'RESUME',
                  icon: Icons.play_arrow,
                  color: FuturisticTheme.primaryCyan,
                ),
                SizedBox(width: 20),
                 NeonButton(
                  onPressed: _saveRun,
                  text: 'FINISH',
                  icon: Icons.check,
                  color: Colors.greenAccent, // Green for save
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatItem(String label, String value, String unit) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
         Text(label, style: TextStyle(color: FuturisticTheme.textGrey, fontSize: 10, letterSpacing: 1.2)),
         SizedBox(height: 4),
         Row(
           crossAxisAlignment: CrossAxisAlignment.baseline,
           textBaseline: TextBaseline.alphabetic,
           children: [
             Text(value, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, shadows: [Shadow(color: FuturisticTheme.primaryCyan, blurRadius: 10)])),
             SizedBox(width: 2),
             Text(unit, style: TextStyle(color: FuturisticTheme.primaryCyan, fontSize: 12, fontWeight: FontWeight.bold)),
           ],
         )
      ],
    );
  }
}
