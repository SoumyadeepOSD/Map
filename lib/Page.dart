// ignore_for_file: library_private_types_in_public_api, prefer_collection_literals

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

TextEditingController sourceController = TextEditingController();
TextEditingController destinationController = TextEditingController();

class _HomeState extends State<Home> {
  GoogleMapController? mapController; //contrller for Google map
  PolylinePoints polylinePoints = PolylinePoints();
  String googleAPiKey = "AIzaSyDXibrJBKsWyoaic2jpp93n8j9IRhJtXTI";
  Set<Marker> markers = Set(); //markers for google map
  Map<PolylineId, Polyline> polylines = {}; //polylines to show direction
  LatLng startLocation = const LatLng(25.618530, 88.125587);
  LatLng endLocation = const LatLng(22.572645, 88.363892);
  double distance = 0.0;

  @override
  void initState() {
    super.initState();
  }

  getDirections() async {
    List<LatLng> polylineCoordinates = [];
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleAPiKey,
      PointLatLng(startLocation.latitude, startLocation.longitude),
      PointLatLng(endLocation.latitude, endLocation.longitude),
      travelMode: TravelMode.walking,
    );
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      print(result.errorMessage);
    }
    //polulineCoordinates is the List of longitute and latidtude.
    double totalDistance = 0;
    for (var i = 0; i < polylineCoordinates.length - 1; i++) {
      totalDistance += calculateDistance(
          polylineCoordinates[i].latitude,
          polylineCoordinates[i].longitude,
          polylineCoordinates[i + 1].latitude,
          polylineCoordinates[i + 1].longitude);
    }
    print(totalDistance);

    setState(() {
      distance = totalDistance;
    });

    //add to the list of poly line coordinates
    addPolyLine(polylineCoordinates);
  }

  addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.deepPurpleAccent,
      points: polylineCoordinates,
      width: 8,
    );
    polylines[id] = polyline;
    setState(() {});
  }

  void findDistance() async {
    List<Location> SourceLocations =
        await locationFromAddress(sourceController.text.toString());
    var s_lat = SourceLocations[0].latitude;
    var s_lon = SourceLocations[0].longitude;

    List<Location> DestinationLocations =
        await locationFromAddress(destinationController.text.toString());
    var d_lat = DestinationLocations[0].latitude;
    var d_lon = DestinationLocations[0].longitude;
    String source = sourceController.text;
    String destination = destinationController.text;
    setState(() {
      startLocation = LatLng(s_lat, s_lon); // Calculate LatLng for source;
      endLocation = LatLng(d_lat, d_lon); // Calculate LatLng for destination;
      polylines.clear();
      markers.clear();
      markers.add(
        Marker(
          //add start location marker
          markerId: MarkerId(startLocation.toString()),
          position: startLocation, //position of marker
          infoWindow: const InfoWindow(
            //popup info
            title: 'Starting Point ',
            snippet: 'Start Marker',
          ),
          icon: BitmapDescriptor.defaultMarker, //Icon for Marker
        ),
      );
      markers.add(
        Marker(
          //add distination location marker
          markerId: MarkerId(endLocation.toString()),
          position: endLocation, //position of marker
          infoWindow: const InfoWindow(
            //popup info
            title: 'Destination Point ',
            snippet: 'Destination Marker',
          ),
          icon: BitmapDescriptor.defaultMarker, //Icon for Marker
        ),
      );
    });
    getDirections();
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 200, // Set this height
          flexibleSpace: Container(
            color: Colors.purple,
            child: Column(children: <Widget>[
              Row(children: const <Widget>[
                SizedBox(width: 15),
                SizedBox(width: 10),
                Text("Distance calculating app",
                    style: TextStyle(fontSize: 23, color: Colors.white))
              ]),
              const SizedBox(height: 8),
              Container(
                  height: 150,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Column(
                    children: [
                      TextField(
                        textAlign: TextAlign.center,
                        controller: sourceController,
                        decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.black),
                            border: const OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(40))),
                            hintStyle: new TextStyle(color: Colors.black38),
                            hintText: "Source"),
                      ),
                      TextField(
                        textAlign: TextAlign.center,
                        controller: destinationController,
                        decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                            filled: true,
                            fillColor: Colors.white,
                            border: const OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(40))),
                            hintStyle: new TextStyle(color: Colors.black38),
                            hintText: "destination"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          findDistance();
                        },
                        child: const Text('Find Distance'),
                      ),
                    ],
                  )),
            ]),
          ),
        ),
        body: Stack(
          children: [
            GoogleMap(
              zoomGesturesEnabled: true, //enable Zoom in, out on map
              initialCameraPosition: CameraPosition(
                target: startLocation, //initial position
                zoom: 14.0, //initial zoom level
              ),
              markers: markers, //markers to show on map
              polylines: Set<Polyline>.of(polylines.values), //polylines
              mapType: MapType.normal, //map type
              onMapCreated: (controller) {
                setState(() {
                  mapController = controller;
                });
              },
            ),
            Positioned(
              bottom: 200,
              left: 50,
              child: Card(
                child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                        "Total Distance: ${distance.toStringAsFixed(2)} KM",
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
