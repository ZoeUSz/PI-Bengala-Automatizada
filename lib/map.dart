import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  const MapScreen({super.key, required this.latitude, required this.longitude});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  LatLng? _center;
  final Set<Marker> _markers = {};
  bool _isMapCreated = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      if (await Permission.location.request().isGranted) {
        _getCurrentLocation();
      }
    } else if (status.isGranted) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    print(
        'Localização atual: ${position.latitude}, ${position.longitude}, ${position.altitude}');
    if (_center == null) {
      setState(() {
        _center = LatLng(position.latitude, position.longitude);
        if (_isMapCreated) {
          mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: _center!, zoom: 11.0),
            ),
          );
        }
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _isMapCreated = true;
    _loadMarkers();
    if (_center == null) {
      _center = LatLng(widget.latitude, widget.longitude);
    }
    if (_center != null) {
      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _center!, zoom: 11.0),
        ),
      );
    }
  }

  void _loadMarkers() async {
    try {
      final response = await http.get(Uri.parse(
          'http://ip_do_local_host/api/localizacoes')); //caso voce for testar em um celular fisico coloque o ip da maquina
      if (response.statusCode == 200) {
        List<dynamic> locations = json.decode(response.body);
        print('Localizações recebidas: $locations');

        List<double> latitudes = [];
        List<double> longitudes = [];
        List<double> altitudes = [];

        for (var location in locations) {
          if (location.startsWith('Latitude:')) {
            latitudes.add(double.parse(location.split('Latitude: ')[1].trim()));
          } else if (location.startsWith('Longitude:')) {
            longitudes
                .add(double.parse(location.split('Longitude: ')[1].trim()));
          } else if (location.startsWith('Altitude:')) {
            altitudes.add(double.parse(location.split('Altitude: ')[1].trim()));
          }
        }

        if (latitudes.length == longitudes.length &&
            longitudes.length == altitudes.length) {
          setState(() {
            _markers.clear();
            for (int i = 0; i < latitudes.length; i++) {
              _markers.add(
                Marker(
                  markerId: MarkerId('$i'),
                  position: LatLng(latitudes[i], longitudes[i]),
                  infoWindow: InfoWindow(
                    title: 'Local $i',
                    snippet:
                        'Latitude: ${latitudes[i]}, Longitude: ${longitudes[i]}, Altitude: ${altitudes[i]}',
                  ),
                ),
              );
            }
          });
        } else {
          print('Número de latitudes, longitudes e altitudes não correspondem');
        }
      } else {
        print('Falha ao carregar localizações: ${response.statusCode}');
        throw Exception('Falha ao carregar localizações');
      }
    } catch (e) {
      print('Erro ao carregar localizações: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center ?? LatLng(widget.latitude, widget.longitude),
          zoom: 11.0,
        ),
        markers: _markers,
        myLocationEnabled: true,
      ),
    );
  }
}
