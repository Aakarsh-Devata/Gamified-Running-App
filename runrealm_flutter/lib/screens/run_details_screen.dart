import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:date_format/date_format.dart';
import '../models/social.dart';

class RunDetailsScreen extends StatefulWidget {
  final Run run;

  const RunDetailsScreen({required this.run});

  @override
  _RunDetailsScreenState createState() => _RunDetailsScreenState();
}

class _RunDetailsScreenState extends State<RunDetailsScreen> {
  MapboxMap? _mapboxMap;
  bool _isMapReady = false;

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData data) async {
    setState(() => _isMapReady = true);
    await _drawPath();
    await _fitCamera();
  }

  Future<void> _drawPath() async {
    if (_mapboxMap == null || widget.run.path.isEmpty) return;

    final coordinates = widget.run.path.map((p) {
      return [p['longitude'], p['latitude']];
    }).toList();

    final geoJson = {
      "type": "Feature",
      "properties": {},
      "geometry": {
        "type": "LineString",
        "coordinates": coordinates
      }
    };

    try {
      await _mapboxMap?.style.addSource(
        GeoJsonSource(
          id: "run-path-source",
          data: jsonEncode(geoJson),
        )
      );

      await _mapboxMap?.style.addLayer(
        LineLayer(
          id: "run-path-layer",
          sourceId: "run-path-source",
          lineColor: Colors.blue.value,
          lineWidth: 4.0,
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
        )
      );
    } catch (e) {
      print("Error drawing run path: $e");
    }
  }

  Future<void> _fitCamera() async {
    if (_mapboxMap == null || widget.run.path.isEmpty) return;

    // Calculate bounds
    double minLat = 90.0;
    double maxLat = -90.0;
    double minLng = 180.0;
    double maxLng = -180.0;

    for (var p in widget.run.path) {
      final lat = p['latitude']!;
      final lng = p['longitude']!;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    // Add some padding
    final cameraOptions = await _mapboxMap?.cameraForCoordinateBounds(
      CoordinateBounds(
        southwest: Point(coordinates: Position(minLng, minLat)),
        northeast: Point(coordinates: Position(maxLng, maxLat)),
        infiniteBounds: false,
      ),
      MbxEdgeInsets(top: 50, left: 50, bottom: 50, right: 50),
      null, // bearing
      null, // pitch
      null, // maxZoom
      null, // offset
    );

    if (cameraOptions != null) {
      await _mapboxMap?.setCamera(cameraOptions);
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(formatDate(widget.run.createdAt?.toDate() ?? DateTime.now(), [MM, ' ', dd, ', ', yyyy])),
      ),
      body: Column(
        children: [
          // Map Section
          Expanded(
            flex: 3,
            child: MapWidget(
              onMapCreated: _onMapCreated,
              onStyleLoadedListener: _onStyleLoaded,
              cameraOptions: CameraOptions(
                zoom: 14.0,
                center: widget.run.path.isNotEmpty 
                  ? Point(coordinates: Position(widget.run.path.first['longitude']!, widget.run.path.first['latitude']!))
                  : Point(coordinates: Position(0, 0)),
              ),
            ),
          ),
          
          // Stats Section
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Run Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statItem('Distance', '${widget.run.distance.toStringAsFixed(2)} km'),
                      _statItem('Time', _formatTime(widget.run.time)),
                      _statItem('Pace', '${widget.run.pace.toStringAsFixed(2)} /km'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey, fontSize: 16)),
      ],
    );
  }
}
