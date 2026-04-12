import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class LocationService {
  static Future<String> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // 1. Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return "Location Services Off";

      // 2. Handle Permissions
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return "Permission Denied";
      }

      if (permission == LocationPermission.deniedForever) {
        return "Permission Permanently Denied";
      }

      // 3. Get current coordinates with the highest accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      // 4. Reverse Geocoding (Convert coordinates to address)
      try {
        // Force English results
        await setLocaleIdentifier("en_US"); 
        
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          
          // Extract specific address layers
          String building = place.name ?? ""; 
          String neighborhood = place.subLocality ?? "";
          String city = place.locality ?? "";

          // --- FIX FOR MIT CAMPUS / AYNALEM ---
          // Maps often label the Aynalem area as "Arato" district.
          // This check ensures we use the correct campus name.
          if (neighborhood.toLowerCase().contains("arato") || 
              building.toLowerCase().contains("arato") ||
              (position.latitude > 13.475 && position.latitude < 13.490 && 
               position.longitude > 39.485 && position.longitude < 39.500)) {
            return "MIT Campus, Aynalem";
          }

          // --- DYNAMIC HUNT (For locations outside of campus) ---
          
          // 1. Look for a specific building name (e.g., "Mekelle Airport")
          // We ignore it if it's just a number
          if (building.isNotEmpty && !building.contains(RegExp(r'^[0-9-]+$'))) {
            return city.isNotEmpty ? "$building, $city" : building;
          }

          // 2. Look for the neighborhood/town name
          if (neighborhood.isNotEmpty) {
            return city.isNotEmpty ? "$neighborhood, $city" : neighborhood;
          }

          // 3. Fallback to just the City
          return city.isNotEmpty ? city : "Mekelle";
        }
      } catch (geoError) {
        debugPrint("Geocoding failed: $geoError");
        // Offline fallback
        return "MIT Campus, Aynalem";
      }

      return "Mekelle, Ethiopia";

    } catch (e) {
      debugPrint("Location Logic Error: $e");
      return "MIT Campus, Aynalem"; 
    }
  }
}