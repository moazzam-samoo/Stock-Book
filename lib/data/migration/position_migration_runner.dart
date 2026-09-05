import 'package:stock_investment_tracker/data/models/lot_model.dart';
import 'package:stock_investment_tracker/data/models/position_model.dart';
import 'package:stock_investment_tracker/data/data_sources/remote/firestore_data_source.dart';
import 'package:stock_investment_tracker/domain/calculator/position_migration.dart';
import 'package:flutter/foundation.dart';

class MigrationOutcome {
  final bool success;
  final String? errorMessage;
  
  const MigrationOutcome.success()
      : success = true,
        errorMessage = null;

  const MigrationOutcome.failure(this.errorMessage)
      : success = false;
}

class PositionMigrationRunner {
  final FirestoreDataSource _dataSource;
  final String _uid;

  PositionMigrationRunner(this._dataSource, this._uid);

  Future<MigrationOutcome> runIfNeeded() async {
    try {
      // 1. Read users/{uid}.schemaVersion. If it is >= 2, return immediately.
      final schemaVersion = await _dataSource.getUserSchemaVersion(_uid);
      if (schemaVersion != null && schemaVersion >= 2) {
        return const MigrationOutcome.success();
      }

      // 2. Load all lots (one read, not a stream).
      final lotModels = await _dataSource.getAllLotsOnce(_uid);
      
      // 3. If there are no lots at all, just stamp schemaVersion: 2 and return.
      if (lotModels.isEmpty) {
        await _dataSource.stampSchemaVersion(_uid, 2);
        return const MigrationOutcome.success();
      }

      final lots = lotModels.map((m) => m.toEntity()).toList();

      // 4. Call PositionMigration.buildPositions(lots).
      final result = PositionMigration.buildPositions(lots);

      // 5. If result.isValid == false: write nothing.
      if (!result.isValid) {
        final error = 'Migration verification failed: ${result.warnings.join(", ")}';
        debugPrint(error);
        return MigrationOutcome.failure(error);
      }

      // 6. If valid: write all positions and schemaVersion: 2 in a single WriteBatch (or chunked)
      // We map the Position entities to PositionModel to easily serialize them
      final positions = result.positions.map((p) => PositionModelExtension.fromEntity(p)).toList();
      
      await _dataSource.runPositionMigrationBatches(_uid, positions, 2);

      return const MigrationOutcome.success();
    } catch (e) {
      debugPrint('Migration error: $e');
      return MigrationOutcome.failure(e.toString());
    }
  }
}
