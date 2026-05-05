import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/error/exceptions.dart';
import '../models/measurement_model.dart';

abstract class MeasurementLocalDataSource {
  Future<void> saveMeasurement(MeasurementModel measurement);
  Future<List<MeasurementModel>> getAllMeasurements();
  Future<MeasurementModel> getMeasurementById(String id);
  Future<void> deleteMeasurement(String id);
  Future<void> updateMeasurement(MeasurementModel measurement);
}

@Injectable(as: MeasurementLocalDataSource)
class MeasurementLocalDataSourceImpl implements MeasurementLocalDataSource {
  final DatabaseHelper databaseHelper;

  MeasurementLocalDataSourceImpl(this.databaseHelper);

  @override
  Future<void> saveMeasurement(MeasurementModel measurement) async {
    try {
      final db = await databaseHelper.database;
      await db.insert(
        DatabaseHelper.tableName,
        measurement.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException('Failed to save measurement: $e');
    }
  }

  @override
  Future<List<MeasurementModel>> getAllMeasurements() async {
    try {
      final db = await databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableName,
        orderBy: 'createdAt DESC',
      );

      return maps.map((map) => MeasurementModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheException('Failed to get measurements: $e');
    }
  }

  @override
  Future<MeasurementModel> getMeasurementById(String id) async {
    try {
      final db = await databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) {
        throw CacheException('Measurement not found');
      }

      return MeasurementModel.fromMap(maps.first);
    } catch (e) {
      throw CacheException('Failed to get measurement: $e');
    }
  }

  @override
  Future<void> deleteMeasurement(String id) async {
    try {
      final db = await databaseHelper.database;
      await db.delete(
        DatabaseHelper.tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CacheException('Failed to delete measurement: $e');
    }
  }

  @override
  Future<void> updateMeasurement(MeasurementModel measurement) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        DatabaseHelper.tableName,
        measurement.toMap(),
        where: 'id = ?',
        whereArgs: [measurement.id],
      );
    } catch (e) {
      throw CacheException('Failed to update measurement: $e');
    }
  }
}
