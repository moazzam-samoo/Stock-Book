import 'package:stock_investment_tracker/domain/entities/position.dart';
import 'package:stock_investment_tracker/domain/repositories/position_repository.dart';
import 'package:stock_investment_tracker/data/models/position_model.dart';
import 'package:stock_investment_tracker/data/data_sources/remote/firestore_data_source.dart';

class PositionRepositoryImpl implements PositionRepository {
  final FirestoreDataSource _dataSource;
  final String _uid;

  PositionRepositoryImpl(this._dataSource, this._uid);

  @override
  Stream<List<Position>> watchAllPositions() {
    return _dataSource.watchAllPositions(_uid).map((models) {
      return models.map((m) => m.toEntity()).toList();
    });
  }

  @override
  Future<void> addPosition(Position position) async {
    final model = PositionModelExtension.fromEntity(position);
    await _dataSource.addPosition(_uid, model);
  }

  @override
  Future<void> updatePosition(Position position) async {
    final model = PositionModelExtension.fromEntity(position);
    await _dataSource.updatePosition(_uid, model);
  }

  @override
  Future<void> deletePosition(String positionId) async {
    await _dataSource.deletePosition(_uid, positionId);
  }
}
