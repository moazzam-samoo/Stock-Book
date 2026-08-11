import 'package:stock_investment_tracker/data/data_sources/remote/firestore_data_source.dart';
import 'package:stock_investment_tracker/data/models/withdrawal_model.dart';
import 'package:stock_investment_tracker/domain/entities/withdrawal.dart';
import 'package:stock_investment_tracker/domain/repositories/withdrawal_repository.dart';

class WithdrawalRepositoryImpl implements WithdrawalRepository {
  final String _uid;
  final FirestoreDataSource _firestoreDataSource;

  WithdrawalRepositoryImpl({
    required String uid,
    required FirestoreDataSource firestoreDataSource,
  })  : _uid = uid,
        _firestoreDataSource = firestoreDataSource;

  @override
  Stream<List<Withdrawal>> watchAllWithdrawals() {
    return _firestoreDataSource.watchAllWithdrawals(_uid).map((models) {
      return models.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<void> addWithdrawal(Withdrawal withdrawal) async {
    final model = WithdrawalModelExtension.fromEntity(withdrawal);
    await _firestoreDataSource.addWithdrawal(_uid, model);
  }

  @override
  Future<void> updateWithdrawal(Withdrawal withdrawal) async {
    final model = WithdrawalModelExtension.fromEntity(withdrawal);
    await _firestoreDataSource.updateWithdrawal(_uid, model);
  }

  @override
  Future<void> deleteWithdrawal(String withdrawalId) async {
    await _firestoreDataSource.deleteWithdrawal(_uid, withdrawalId);
  }
}
