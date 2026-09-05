import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_paths.dart';
import '../../domain/entities/market_status.dart';
import '../../domain/repositories/market_status_repository.dart';
import '../models/market_status_model.dart';

class MarketStatusRepositoryImpl implements MarketStatusRepository {
  final FirebaseFirestore _firestore;

  MarketStatusRepositoryImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<MarketStatus?> watchStatus() {
    return _firestore
        .doc(FirestorePaths.marketStatus())
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      try {
        final model = MarketStatusModel.fromJson(snapshot.data()!);
        return model.toEntity();
      } catch (e) {
        return null;
      }
    });
  }
}
