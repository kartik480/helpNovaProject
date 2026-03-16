import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  // Google Maps API Key (used for Geocoding, Places, Distance Matrix APIs)
  static const String _apiKey = 'AIzaSyBSt7L3j1Gtxi_nNhXz8pTcxCXv6niBieg';
  static const String _geocodingBaseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';
  static const String _placesBaseUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';

  // Cache to avoid repeated API calls for same coordinates
  static final Map<String, String> _addressCache = {};

  /// Reverse geocode: Convert latitude/longitude to address
  static Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      // Check cache first
      final cacheKey = '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';
      if (_addressCache.containsKey(cacheKey)) {
        return _addressCache[cacheKey];
      }

      // Make API call
      final url = Uri.parse(
        '$_geocodingBaseUrl?latlng=$latitude,$longitude&key=$_apiKey',
      );

      final response = await http.get(url).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Geocoding request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (data['status'] == 'OK' && data['results'] != null) {
          final results = data['results'] as List;
          if (results.isNotEmpty) {
            // Get the first result (most accurate)
            final formattedAddress = results[0]['formatted_address'] as String?;
            
            if (formattedAddress != null) {
              // Cache the result
              _addressCache[cacheKey] = formattedAddress;
              return formattedAddress;
            }
          }
        } else if (data['status'] == 'ZERO_RESULTS') {
          return 'Location not found';
        } else {
          print('Geocoding API error: ${data['status']}');
        }
      } else {
        print('Geocoding API HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Geocoding error: $e');
    }
    
    return null;
  }

  /// Get a short address (street name + area) instead of full address
  static Future<String?> getShortAddress(
    double latitude,
    double longitude,
  ) async {
    try {
      final fullAddress = await getAddressFromCoordinates(latitude, longitude);
      if (fullAddress == null) return null;

      // Try to extract a shorter version
      // Format: "Street, Area, City, State, Country"
      final parts = fullAddress.split(',');
      if (parts.length >= 2) {
        // Return "Street, Area" or just "Area" if street is too long
        final street = parts[0].trim();
        final area = parts[1].trim();
        
        if (street.length > 30) {
          return area; // Just return area if street name is too long
        }
        return '$street, $area';
      }
      
      return fullAddress;
    } catch (e) {
      print('Error getting short address: $e');
      return null;
    }
  }

  /// Clear the address cache
  static void clearCache() {
    _addressCache.clear();
  }

  /// Search for addresses using Google Places Autocomplete API
  /// Returns a list of address suggestions with their coordinates
  static Future<List<Map<String, dynamic>>> searchAddresses(String query) async {
    if (query.isEmpty) return [];
    
    try {
      final url = Uri.parse(
        '$_placesBaseUrl?input=${Uri.encodeComponent(query)}&key=$_apiKey',
      );

      final response = await http.get(url).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Places Autocomplete request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (data['status'] == 'OK' && data['predictions'] != null) {
          final predictions = data['predictions'] as List;
          
          List<Map<String, dynamic>> results = [];
          for (var prediction in predictions) {
            final description = prediction['description'] as String?;
            final placeId = prediction['place_id'] as String?;
            
            if (description != null && placeId != null) {
              // Get coordinates for this place
              final coords = await _getPlaceCoordinates(placeId);
              if (coords != null) {
                results.add({
                  'address': description,
                  'placeId': placeId,
                  'latitude': coords['lat'],
                  'longitude': coords['lng'],
                });
              }
            }
          }
          
          return results;
        } else if (data['status'] == 'ZERO_RESULTS') {
          return [];
        } else {
          print('Places Autocomplete API error: ${data['status']}');
        }
      } else {
        print('Places Autocomplete API HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Places Autocomplete error: $e');
    }
    
    return [];
  }

  /// Get coordinates for a place using Place Details API
  static Future<Map<String, double>?> _getPlaceCoordinates(String placeId) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$_apiKey',
      );

      final response = await http.get(url).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Place Details request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (data['status'] == 'OK' && data['result'] != null) {
          final result = data['result'] as Map<String, dynamic>;
          final geometry = result['geometry'] as Map<String, dynamic>?;
          final location = geometry?['location'] as Map<String, dynamic>?;
          
          if (location != null) {
            final lat = location['lat'] as double?;
            final lng = location['lng'] as double?;
            
            if (lat != null && lng != null) {
              return {'lat': lat, 'lng': lng};
            }
          }
        }
      }
    } catch (e) {
      print('Place Details error: $e');
    }
    
    return null;
  }

  /// Calculate road distance between two coordinates using Google Maps Distance Matrix API
  /// Returns distance in kilometers, or null if API call fails
  static Future<double?> getRoadDistance(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/distancematrix/json'
        '?origins=$originLat,$originLng'
        '&destinations=$destLat,$destLng'
        '&units=metric'
        '&key=$_apiKey',
      );

      final response = await http.get(url).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Distance Matrix API request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (data['status'] == 'OK' && data['rows'] != null) {
          final rows = data['rows'] as List;
          if (rows.isNotEmpty) {
            final elements = rows[0]['elements'] as List;
            if (elements.isNotEmpty) {
              final element = elements[0] as Map<String, dynamic>;
              if (element['status'] == 'OK' && element['distance'] != null) {
                // Distance is in meters, convert to kilometers
                final distanceInMeters = element['distance']['value'] as int;
                return distanceInMeters / 1000.0;
              }
            }
          }
        }
      }
    } catch (e) {
      print('Distance Matrix API error: $e');
    }
    
    return null;
  }

  /// Batch calculate road distances using Google Maps Distance Matrix API
  /// Can handle up to 25 destinations per request (API limit)
  /// Returns a map of index -> distance in kilometers
  /// Returns empty map if API call fails
  static Future<Map<int, double>> getBatchRoadDistances(
    double originLat,
    double originLng,
    List<Map<String, double>> destinations, // List of {lat: double, lng: double}
  ) async {
    final Map<int, double> distances = {};
    
    if (destinations.isEmpty) return distances;
    
    try {
      // Google Maps Distance Matrix API allows up to 25 destinations per request
      const int batchSize = 25;
      
      // Process in batches
      for (int i = 0; i < destinations.length; i += batchSize) {
        final endIndex = (i + batchSize < destinations.length) ? i + batchSize : destinations.length;
        final batch = destinations.sublist(i, endIndex);
        
        // Build destinations string: "lat1,lng1|lat2,lng2|..."
        final destinationsStr = batch.map((dest) => '${dest['lat']},${dest['lng']}').join('|');
        
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/distancematrix/json'
          '?origins=$originLat,$originLng'
          '&destinations=$destinationsStr'
          '&units=metric'
          '&key=$_apiKey',
        );

        final response = await http.get(url).timeout(
          Duration(seconds: 15),
          onTimeout: () {
            throw Exception('Distance Matrix API batch request timeout');
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          
          if (data['status'] == 'OK' && data['rows'] != null) {
            final rows = data['rows'] as List;
            if (rows.isNotEmpty) {
              final elements = rows[0]['elements'] as List;
              
              for (int j = 0; j < elements.length && j < batch.length; j++) {
                final element = elements[j] as Map<String, dynamic>;
                if (element['status'] == 'OK' && element['distance'] != null) {
                  // Distance is in meters, convert to kilometers
                  final distanceInMeters = element['distance']['value'] as int;
                  final distanceInKm = distanceInMeters / 1000.0;
                  distances[i + j] = distanceInKm; // Store with original index
                }
              }
            }
          } else {
            print('Distance Matrix API batch error: ${data['status']}');
            if (data['error_message'] != null) {
              print('Error message: ${data['error_message']}');
            }
          }
        } else {
          print('Distance Matrix API HTTP error: ${response.statusCode}');
        }
        
        // Small delay between batches to avoid rate limiting
        if (endIndex < destinations.length) {
          await Future.delayed(Duration(milliseconds: 200));
        }
      }
    } catch (e) {
      print('Distance Matrix API batch error: $e');
    }
    
    return distances;
  }

  /// Get route between two points using Google Directions API
  /// Returns a list of LatLng points representing the route polyline
  static Future<List<Map<String, double>>?> getRoute(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$originLat,$originLng'
        '&destination=$destLat,$destLng'
        '&mode=driving'
        '&key=$_apiKey',
      );

      final response = await http.get(url).timeout(
        Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Directions API request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (data['status'] == 'OK' && data['routes'] != null) {
          final routes = data['routes'] as List;
          if (routes.isNotEmpty) {
            final route = routes[0] as Map<String, dynamic>;
            final overviewPolyline = route['overview_polyline'] as Map<String, dynamic>?;
            
            if (overviewPolyline != null) {
              final encodedPolyline = overviewPolyline['points'] as String?;
              if (encodedPolyline != null) {
                // Decode polyline to get list of LatLng points
                return _decodePolyline(encodedPolyline);
              }
            }
          }
        } else {
          print('Directions API error: ${data['status']}');
          if (data['error_message'] != null) {
            print('Error message: ${data['error_message']}');
          }
        }
      } else {
        print('Directions API HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Directions API error: $e');
    }
    
    return null;
  }

  /// Decode Google Maps polyline string to list of coordinates
  /// Polyline encoding algorithm: https://developers.google.com/maps/documentation/utilities/polylinealgorithm
  static List<Map<String, double>> _decodePolyline(String encoded) {
    List<Map<String, double>> points = [];
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
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add({
        'lat': lat / 1e5,
        'lng': lng / 1e5,
      });
    }

    return points;
  }

  /// Get place coordinates from place ID (public method for external use)
  static Future<Map<String, double>?> getPlaceCoordinates(String placeId) async {
    return _getPlaceCoordinates(placeId);
  }
}
