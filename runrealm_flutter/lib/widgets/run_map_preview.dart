import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../models/social.dart';

class RunMapPreview extends StatefulWidget {
  final Run run;
  final double height;

  const RunMapPreview({
    required this.run,
    this.height = 200,
  });

  @override
  _RunMapPreviewState createState() => _RunMapPreviewState();
}

class _RunMapPreviewState extends State<RunMapPreview> {
  MapboxMap? _mapboxMap;

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData data) async {
    // Disable interactions for preview
    await _mapboxMap?.gestures.updateSettings(
      GesturesSettings(
        scrollEnabled: false,
        rotateEnabled: false,
        pinchToZoomEnabled: false,
        doubleTapToZoomInEnabled: false,
      ),
    );
    
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
          id: "preview-path-source",
          data: jsonEncode(geoJson),
        )
      );

      await _mapboxMap?.style.addLayer(
        LineLayer(
          id: "preview-path-layer",
          sourceId: "preview-path-source",
          lineColor: Colors.blue.value,
          lineWidth: 3.0,
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
        )
      );
    } catch (e) {
      print("Error drawing preview path: $e");
    }
  }

  Future<void> _fitCamera() async {
    if (_mapboxMap == null || widget.run.path.isEmpty) return;

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

    final cameraOptions = await _mapboxMap?.cameraForCoordinateBounds(
      CoordinateBounds(
        southwest: Point(coordinates: Position(minLng, minLat)),
        northeast: Point(coordinates: Position(maxLng, maxLat)),
        infiniteBounds: false,
      ),
      MbxEdgeInsets(top: 20, left: 20, bottom: 20, right: 20),
      null, 
      null, 
      null, 
      null, 
    );

    if (cameraOptions != null) {
      await _mapboxMap?.setCamera(cameraOptions);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.run.path.isEmpty) {
      return Container(
        height: widget.height,
        color: Colors.grey[200],
        child: Center(child: Text('No path data')),
      );
    }

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: MapWidget(
          onMapCreated: _onMapCreated,
          onStyleLoadedListener: _onStyleLoaded,
          cameraOptions: CameraOptions(
            zoom: 12.0,
            center: Point(
              coordinates: Position(
                widget.run.path.first['longitude']!,
                widget.run.path.first['latitude']!,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
