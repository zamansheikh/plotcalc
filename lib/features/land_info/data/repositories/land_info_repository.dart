import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/land_info_model.dart';

class LandInfoRepository {
  static const _onlineUrl =
      'https://zamansheikh.github.io/plotcalc/land_info.json';
  static const _localAsset = 'docs/land_info.json';
  static const _networkTimeout = Duration(seconds: 4);

  /// Try to fetch the JSON from the network first (short timeout).
  /// If that fails or returns non-200, fall back to the bundled local file.
  Future<LandInfoData> loadLandInfo() async {
    // Try network
    try {
      final response = await http
          .get(Uri.parse(_onlineUrl))
          .timeout(_networkTimeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return LandInfoData.fromJson(data);
      }
      // if non-200, fall through to local
    } catch (e) {
      // network error or timeout -> fallback to local
    }

    // Fallback to bundled local asset
    try {
      final String response = await rootBundle.loadString(_localAsset);
      final data = json.decode(response);
      return LandInfoData.fromJson(data);
    } catch (e) {
      throw Exception('Failed to load land info (network and local): $e');
    }
  }

  Future<LandTopic?> getTopicById(String id) async {
    final data = await loadLandInfo();
    try {
      return data.topics.firstWhere((topic) => topic.id == id);
    } catch (e) {
      return null;
    }
  }
}
