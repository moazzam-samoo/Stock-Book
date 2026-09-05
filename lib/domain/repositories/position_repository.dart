import 'package:stock_investment_tracker/domain/entities/position.dart';

abstract class PositionRepository {
  Stream<List<Position>> watchAllPositions();
  Future<void> addPosition(Position position);
  Future<void> updatePosition(Position position);
  Future<void> deletePosition(String positionId);
}
