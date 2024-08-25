import 'package:five_flight/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_mbtiles/flutter_map_mbtiles.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sqflite/sqflite.dart';

class OFMMap extends StatefulWidget {
  const OFMMap({super.key});

  @override
  State<OFMMap> createState() => _OFMMapState();
}

class _OFMMapState extends State<OFMMap> with ChangeNotifier {
  late MapController _mapController;
  final _futureTileProvider = MbTilesTileProvider.fromPath(
      path: 'assets/mbtiles/italy_256.mbtiles', silenceTileNotFound: true);
  late ValueNotifier<FlightPlan> currentFlightPlan;
  late Database airportsDB;

  @override
  void initState() {
    super.initState();
    currentFlightPlan = ValueNotifier<FlightPlan>(FlightPlan.defaultPlan());
    _mapController = MapController();
    openDatabase(
            '/home/giulianbiolo/Scrivania/Informatica/Flutter/five_flight/assets/airports/airports.db',
            version: 2)
        .then((db) {
      airportsDB = db;
    });
  }

  @override
  void dispose() {
    airportsDB.close();
    _mapController.dispose();
    currentFlightPlan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: currentFlightPlan,
        builder: (context, value, widget) {
          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(45.5457, 11.2848),
              initialZoom: 10.0,
              minZoom: 7,
              maxZoom: 11,
              keepAlive: true,
              cameraConstraint: CameraConstraint.contain(
                  bounds: LatLngBounds(
                      const LatLng(48.9, 5.6), const LatLng(34.36, 19.67))),
              interactionOptions:
                  const InteractionOptions(flags: InteractiveFlag.all),
              onTap: (tapPos, latlng) async {
                // print('Tapped at $latlng with $tapPos');
                // ? Get the nearest airport from the DB and print it here
                (Map<String, Object?>, double) airport =
                    await queryClosestAirport(
                        airportsDB, Point(latlng.latitude, latlng.longitude));
                Map<String, Object?> value = airport.$1;
                double distanceToAirport = airport.$2;
                print(value);
                //print('Distance to airport: $distanceToAirport');
                if (distanceToAirport > 5000) {
                  // print("No airport found within 5km");
                  return;
                }
                if (context.mounted) {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                  'Closest airport: ${value['name']} (${value['ident']})'),
                              ElevatedButton(
                                child: const Text('Close BottomSheet'),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
                return;
              },
              onLongPress: (tapPos, latlng) {
                Point currPoint = Point(latlng.latitude, latlng.longitude);
                // ? Toggle from the flight plan
                // for each latlng in the plan, see if the current latlng is near any of them
                // if it is, remove it from the plan
                // if it isn't, add it to the plan
                // print('Long pressed at $latlng with $tapPos');
                for (final point in currentFlightPlan.value.points) {
                  if (point.distanceTo(currPoint) < 100) {
                    currentFlightPlan.value.remove(point);
                    currentFlightPlan.notifyListeners();
                    // print('Removed $point from the flight plan');
                    // print('Current flight plan: $currentFlightPlan');
                    // print('Current flight length: ${currentFlightPlan.value.flightLength()}');
                    return;
                  }
                }
                currentFlightPlan.value.add(currPoint);
                currentFlightPlan.notifyListeners();
                // print('Added $currPoint to the flight plan');
                // print('Current flight plan: $currentFlightPlan');
                // print('Current flight length: ${currentFlightPlan.value.flightLength()}');
                return;
              },
            ),
            children: [
              _tileLayer,
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: currentFlightPlan.value.points
                        .map((e) => LatLng(e.latitude, e.longitude))
                        .toList(),
                    strokeWidth: 2.0,
                    color: Colors.red,
                  ),
                ],
              ),
              _credits,
            ],
          );
        });
  }

  TileLayer get _tileLayer => TileLayer(
        //urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        tileProvider: _futureTileProvider,
        //maxNativeZoom: 11,
        //minNativeZoom: 7,
        //evictErrorTileStrategy: EvictErrorTileStrategy.dispose,
        userAgentPackageName: 'com.five_flight.app',
      );

  RichAttributionWidget get _credits => RichAttributionWidget(
        attributions: [
          TextSourceAttribution(
            'OpenFlightMaps contributors',
            onTap: () =>
                launchUrl(Uri.parse('https://www.openflightmaps.org/about/')),
          ),
        ],
      );
}
