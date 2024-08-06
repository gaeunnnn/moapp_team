import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _searchController = TextEditingController();
  final Set<Marker> _markers = {};
  LatLng? _selectedLocation;

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 20.4746,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for a place',
            suffixIcon: IconButton(
              icon: Icon(Icons.search),
              onPressed: _searchAndNavigate,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, _selectedLocation);
            },
          ),
        ],
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _kGooglePlex,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: _markers,
        onTap: (LatLng location) {
          setState(() {
            _selectedLocation = location;
            _markers.clear();
            _markers.add(Marker(
              markerId: MarkerId(location.toString()),
              position: location,
              infoWindow: InfoWindow(
                title: 'Selected Location',
                snippet: '${location.latitude}, ${location.longitude}',
              ),
            ));
          });
        },
      ),
    );
  }

  Future<void> _searchAndNavigate() async {
    final GoogleMapController controller = await _controller.future;
    List<Location> locations =
        await locationFromAddress(_searchController.text);
    if (locations.isNotEmpty) {
      Location location = locations.first;
      LatLng target = LatLng(location.latitude, location.longitude);

      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 14.0),
      ));

      setState(() {
        _markers.clear();
        _selectedLocation = target;
        _markers.add(Marker(
          markerId: MarkerId(target.toString()),
          position: target,
          infoWindow: InfoWindow(
            title: _searchController.text,
          ),
        ));
      });
    }
  }
}
