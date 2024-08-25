import 'dart:math';

import 'package:latlong2/latlong.dart';
import 'package:sqflite/sqflite.dart';

class Point {
  final double latitude;
  final double longitude;

  const Point(this.latitude, this.longitude);

  @override
  String toString() {
    return '{lat: $latitude, lng: $longitude}';
  }

  /// ### Haversine formula to calculate distance between two points in meters
  double distanceTo(Point other) {
    const double radius = 6378137.0; // Earth's radius in meters
    const double pi = 3.141592653589793; // Pi constant
    final double lat1 = latitude * (pi / 180.0);
    final double lon1 = longitude * (pi / 180.0);
    final double lat2 = other.latitude * (pi / 180.0);
    final double lon2 = other.longitude * (pi / 180.0);
    final double dlat = lat2 - lat1;
    final double dlon = lon2 - lon1;

    final double a =
        pow(sin(dlat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dlon / 2), 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return radius * c;
  }
}

class FlightPlan {
  final List<Point> _points;

  FlightPlan(List<Point> points) : _points = points;
  FlightPlan.empty() : _points = <Point>[];
  FlightPlan.defaultPlan() : _points = List<Point>.from(defaultFlightPlan);

  List<Point> get points => _points;

  void add(Point point) {
    _points.add(point);
  }

  void remove(Point point) {
    _points.remove(point);
  }

  void clear() {
    _points.clear();
  }

  @override
  String toString() {
    return _points.toString();
  }

  void dispose() {
    _points.clear();
  }

  FlightPlan copy() {
    return FlightPlan(List<Point>.from(_points));
  }

  double flightLength() {
    double length = 0;
    for (int i = 0; i < _points.length - 1; i++) {
      length += _points[i].distanceTo(_points[i + 1]);
    }
    return length;
  }

  double flightTime(double speed) {
    return flightLength() / speed;
  }
}

// * The default flight plan starts from northern italy and goes to sardinia
final List<Point> defaultFlightPlan = <Point>[
  const Point(45.40373829840437, 11.405826259439367),
  const Point(44.68136382520045, 10.569349763592665),
  const Point(44.505995050760426, 9.99211293579551),
  const Point(44.466847453394365, 9.718325641853001),
  const Point(44.28800902926218, 9.667878192946304),
  const Point(44.28137135605846, 9.643435985649889),
  const Point(44.182663670217956, 9.571073393000308),
  const Point(43.902348859810736, 9.56020686670257),
  const Point(43.272364691579824, 9.736566340782785),
  const Point(43.17207225362332, 9.779229922610387),
  const Point(43.032130002184246, 9.81843880279695),
  const Point(42.75989374039259, 10.240555181998714),
  const Point(41.56033049003835, 10.743184890865573),
  const Point(40.771211292188134, 10.356555856079025),
  const Point(40.580428768720786, 10.017328664904609),
  const Point(40.44872844822123, 9.849944362358887),
  const Point(40.34817652148873, 9.54971021775118)
];

Future<(Map<String, Object?>, double)> queryClosestAirport(
    Database airportsDB, Point latlng) async {
  double latitude = latlng.latitude;
  double longitude = latlng.longitude;
  List<Map<String, Object?>> queryRes = await airportsDB.rawQuery('''
SELECT *,
    (
      ((latitude_deg - $latitude)*(latitude_deg - $latitude)) + ((longitude_deg - $longitude)*(longitude_deg - $longitude))
    ) AS distance_approx
FROM 
    airports
ORDER BY 
    distance_approx ASC
LIMIT 1;
''');
  double? airportLat = double.tryParse(queryRes[0]['latitude_deg'].toString());
  double? airportLon = double.tryParse(queryRes[0]['longitude_deg'].toString());
  if (airportLat == null || airportLon == null) {
    return Future.error('Error parsing airport coordinates');
  }
  double distance = Point(airportLat, airportLon).distanceTo(latlng);
  return Future.value((queryRes[0], distance));
}
