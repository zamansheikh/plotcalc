import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/land_info_model.dart';

class LandInfoRepository {
  Future<LandInfoData> loadLandInfo() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/land_info.json',
      );
      final data = await json.decode(response);
      return LandInfoData.fromJson(data);
    } catch (e) {
      throw Exception('Failed to load land info: $e');
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
