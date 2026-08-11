import 'package:stock_investment_tracker/domain/entities/withdrawal.dart';

abstract class WithdrawalRepository {
  Stream<List<Withdrawal>> watchAllWithdrawals();
  Future<void> addWithdrawal(Withdrawal withdrawal);
  Future<void> updateWithdrawal(Withdrawal withdrawal);
  Future<void> deleteWithdrawal(String withdrawalId);
}
