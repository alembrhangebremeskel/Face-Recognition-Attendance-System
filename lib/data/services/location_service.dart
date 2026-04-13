import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class LocationService {
  static Future<String> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return "Location Services Off";

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return "Permission Denied";
      }

      // Use the highest accuracy to help the phone find the building footprint
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      try {
        await setLocaleIdentifier("en_US"); 
        
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          String bestFoundName = "";

          for (var place in placemarks) {
            String name = place.name ?? "";
            String street = place.thoroughfare ?? "";
            String neighborhood = place.subLocality ?? "";
            String city = place.locality ?? "";

            // 1. Filter out useless data
            if (name.contains('+')) name = "";

            // 2. THE CAMPUS LOGIC (Priority Search)
            // We search for keywords that indicate a University or Campus
            List<String> keywords = ["university", "institute", "technology", "campus", "mit", "college"];
            
            bool isCampusMatch = keywords.any((k) => 
              name.toLowerCase().contains(k) || 
              street.toLowerCase().contains(k));

            if (isCampusMatch) {
              // If we find a campus keyword, this is our winner!
              return "${name.isNotEmpty ? name : street}, $city";
            }

            // 3. Keep track of the most specific name that isn't just a number
            if (bestFoundName.isEmpty && 
                name.isNotEmpty && 
                !name.contains(RegExp(r'^[0-9-]+$')) &&
                name.toLowerCase() != neighborhood.toLowerCase()) {
              bestFoundName = "$name, $neighborhood";
            }
          }

          // 4. Return the best name we found, otherwise fallback to the neighborhood
          return bestFoundName.isNotEmpty ? bestFoundName : "${placemarks[0].subLocality}, Mekelle";
        }
      } catch (geoError) {
        return "Mekelle, Ethiopia";
      }

      return "Mekelle, Ethiopia";
    } catch (e) {
      return "Location Error"; 
    }
  }
}