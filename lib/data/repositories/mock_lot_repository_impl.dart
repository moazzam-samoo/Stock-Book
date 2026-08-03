import 'dart:async';
import 'package:stock_investment_tracker/domain/entities/lot.dart';
import 'package:stock_investment_tracker/domain/entities/sale.dart';
import 'package:stock_investment_tracker/domain/enums/lot_status.dart';
import 'package:stock_investment_tracker/domain/repositories/lot_repository.dart';

class MockLotRepositoryImpl implements LotRepository {
  final List<Lot> _lots = [
    Lot(
      id: '1',
      ticker: 'SYS',
      buyDate: DateTime.now().subtract(const Duration(days: 45)),
      sharesPurchased: 500,
      buyPricePerShare: 420.0,
      amountInvested: 210000.0,
      sharesRemaining: 300,
      amountInvestedRemaining: 126000.0,
      realizedProfitLoss: 18000.0,
      status: LotStatus.partiallySold,
      sales: [
        Sale(
          id: 's1',
          sellDate: DateTime.now().subtract(const Duration(days: 10)),
          sharesSold: 200,
          sellPricePerShare: 510.0,
          amountReceived: 102000.0,
        ),
      ],
    ),
    Lot(
      id: '2',
      ticker: 'TRG',
      buyDate: DateTime.now().subtract(const Duration(days: 30)),
      sharesPurchased: 1000,
      buyPricePerShare: 85.5,
      amountInvested: 85500.0,
      sharesRemaining: 1000,
      amountInvestedRemaining: 85500.0,
      realizedProfitLoss: 0.0,
      status: LotStatus.open,
    ),
    Lot(
      id: '3',
      ticker: 'OGDC',
      buyDate: DateTime.now().subtract(const Duration(days: 60)),
      sharesPurchased: 800,
      buyPricePerShare: 110.0,
      amountInvested: 88000.0,
      sharesRemaining: 800,
      amountInvestedRemaining: 88000.0,
      realizedProfitLoss: 12500.0,
      status: LotStatus.open,
    ),
    Lot(
      id: '4',
      ticker: 'LUCK',
      buyDate: DateTime.now().subtract(const Duration(days: 90)),
      sharesPurchased: 250,
      buyPricePerShare: 640.0,
      amountInvested: 160000.0,
      sharesRemaining: 0,
      amountInvestedRemaining: 0.0,
      realizedProfitLoss: -8500.0,
      status: LotStatus.closed,
      sales: [
        Sale(
          id: 's2',
          sellDate: DateTime.now().subtract(const Duration(days: 5)),
          sharesSold: 250,
          sellPricePerShare: 606.0,
          amountReceived: 151500.0,
        ),
      ],
    ),
  ];

  final StreamController<List<Lot>> _controller =
      StreamController<List<Lot>>.broadcast();

  MockLotRepositoryImpl() {
    _controller.add(_lots);
  }

  void _notify() {
    _controller.add(List.unmodifiable(_lots));
  }

  @override
  Stream<List<Lot>> watchAllLots() {
    // Send current value immediately when someone listens
    Future.microtask(() => _notify());
    return _controller.stream;
  }

  @override
  Stream<List<Lot>> watchLotsByTicker(String ticker) {
    return _controller.stream.map((lots) {
      return lots.where((l) => l.ticker == ticker).toList();
    });
  }

  @override
  Stream<List<Lot>> watchLotsByFilter(String statusFilter) {
    return _controller.stream.map((lots) {
      if (statusFilter.toLowerCase() == 'all') return lots;
      final status = LotStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == statusFilter.toLowerCase(),
        orElse: () => LotStatus.open,
      );
      return lots.where((l) => l.status == status).toList();
    });
  }

  @override
  Future<void> addLot(Lot lot) async {
    _lots.add(lot);
    _notify();
  }

  @override
  Future<void> updateLot(Lot lot) async {
    final index = _lots.indexWhere((l) => l.id == lot.id);
    if (index != -1) {
      _lots[index] = lot;
      _notify();
    }
  }

  @override
  Future<void> deleteLot(String lotId) async {
    _lots.removeWhere((l) => l.id == lotId);
    _notify();
  }
}
