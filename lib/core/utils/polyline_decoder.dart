import 'package:latlong2/latlong.dart';

/// Decodes an Encoded Polyline string (Google / Goong.io format, precision 5)
/// into a list of LatLng points. Mirrors ELog-FE's src/utils/polyline.ts so
/// both clients read the same `routePolyline` field identically.
List<LatLng> decodePolyline(String encoded) {
  if (encoded.isEmpty) return [];
  final points = <LatLng>[];
  int index = 0;
  int lat = 0;
  int lng = 0;

  while (index < encoded.length) {
    int shift = 0;
    int result = 0;
    int b;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lng += dlng;

    points.add(LatLng(lat / 1e5, lng / 1e5));
  }

  return points;
}

/// A `routePolyline` value may join multiple legs (warehouse→stop1,
/// stop1→stop2, ...) with ';' — decode and concatenate all of them in order.
List<LatLng> decodeMultiLegPolyline(String? encoded) {
  if (encoded == null || encoded.isEmpty) return [];
  final points = <LatLng>[];
  for (final leg in encoded.split(';')) {
    final trimmed = leg.trim();
    if (trimmed.isEmpty) continue;
    points.addAll(decodePolyline(trimmed));
  }
  return points;
}
