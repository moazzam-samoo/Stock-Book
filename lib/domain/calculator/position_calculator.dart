import 'package:stock_investment_tracker/domain/entities/position.dart';
import 'package:stock_investment_tracker/domain/entities/position_buy.dart';
import 'package:stock_investment_tracker/domain/entities/position_sale.dart';
import 'package:stock_investment_tracker/domain/enums/position_status.dart';

class _PositionEvent {
  final DateTime date;
  final bool isBuy;
  final dynamic event;

  _PositionEvent(this.date, this.isBuy, this.event);
}

class PositionCalculator {
  static double _round(double value) {
    return (value * 100).roundToDouble() / 100;
  }

  static double avgCost(Position p) {
    final remaining = sharesHeld(p);
    if (remaining <= 0) return 0.0;
    
    // avgCost is defined by the total cost / shares held.
    // We can compute this by re-running the moving average on just this position's events,
    // or by tracking it. Since a Position represents a contiguous block of trades without hitting 0,
    // we can re-derive the average cost by walking its events.
    double totalCost = 0.0;
    int currentShares = 0;

    List<_PositionEvent> events = [];
    events.addAll(p.buys.map((b) => _PositionEvent(b.date, true, b)));
    events.addAll(p.sales.map((s) => _PositionEvent(s.date, false, s)));

    events.sort((a, b) {
      final dateCmp = a.date.compareTo(b.date);
      if (dateCmp != 0) return dateCmp;
      if (a.isBuy && !b.isBuy) return -1;
      if (!a.isBuy && b.isBuy) return 1;
      return 0;
    });

    for (final ev in events) {
      if (ev.isBuy) {
        final buy = ev.event as PositionBuy;
        totalCost += buy.shares * buy.pricePerShare;
        currentShares += buy.shares;
      } else {
        final sale = ev.event as PositionSale;
        if (currentShares > 0) {
          final double avg = totalCost / currentShares;
          final double basis = sale.costBasisAtSale ?? avg;
          totalCost -= sale.shares * basis;
          currentShares -= sale.shares;
        }
      }
    }
    
    if (currentShares <= 0) return 0.0;
    return _round(totalCost / currentShares);
  }

  static int sharesHeld(Position p) {
    int bought = p.buys.fold(0, (sum, b) => sum + b.shares);
    int sold = p.sales.fold(0, (sum, s) => sum + s.shares);
    int remaining = bought - sold;
    return remaining < 0 ? 0 : remaining;
  }

  static double totalCost(Position p) {
    return _round(sharesHeld(p) * avgCost(p));
  }

  static double realizedPL(Position p) {
    return _round(p.sales.fold(0.0, (sum, s) => sum + s.realizedPL));
  }

  static double amountInvested(Position p) {
    return _round(sharesHeld(p) * avgCost(p));
  }

  static List<Position> replay(String ticker, List<PositionBuy> buys, List<PositionSale> sales) {
    List<_PositionEvent> events = [];
    events.addAll(buys.map((b) => _PositionEvent(b.date, true, b)));
    events.addAll(sales.map((s) => _PositionEvent(s.date, false, s)));

    // Sort by date, buys before sales
    events.sort((a, b) {
      final dateCmp = a.date.compareTo(b.date);
      if (dateCmp != 0) return dateCmp;
      if (a.isBuy && !b.isBuy) return -1;
      if (!a.isBuy && b.isBuy) return 1;
      return 0;
    });

    List<Position> positions = [];
    
    List<PositionBuy> currentBuys = [];
    List<PositionSale> currentSales = [];
    DateTime? openedAt;
    
    double runningTotalCost = 0.0;
    int currentShares = 0;

    void closePosition(DateTime? closedAt) {
      if (currentBuys.isEmpty && currentSales.isEmpty) return;
      
      PositionStatus status;
      if (currentShares <= 0) {
        status = PositionStatus.closed;
      } else if (currentSales.isNotEmpty) {
        status = PositionStatus.partiallySold;
      } else {
        status = PositionStatus.open;
      }

      positions.add(Position(
        id: '', // Will be assigned by repository or migration
        ticker: ticker,
        status: status,
        openedAt: openedAt ?? DateTime.now(),
        closedAt: status == PositionStatus.closed ? closedAt : null,
        buys: List.from(currentBuys),
        sales: List.from(currentSales),
      ));
      
      currentBuys.clear();
      currentSales.clear();
      openedAt = null;
      runningTotalCost = 0.0;
      currentShares = 0;
    }

    for (final ev in events) {
      if (currentShares == 0 && currentBuys.isNotEmpty) {
        // We hit 0 on the previous event. This new event starts a new position.
        closePosition(currentSales.last.date);
      }

      if (openedAt == null) {
        openedAt = ev.date;
      }

      if (ev.isBuy) {
        final buy = ev.event as PositionBuy;
        currentBuys.add(buy);
        runningTotalCost += buy.shares * buy.pricePerShare;
        currentShares += buy.shares;
      } else {
        final sale = ev.event as PositionSale;
        int processedShares = sale.shares;
        
        // Clamp negative shares if selling more than we have
        if (currentShares < processedShares) {
          processedShares = currentShares;
        }

        if (processedShares > 0) {
          final double avg = currentShares > 0 ? (runningTotalCost / currentShares) : 0.0;
          final double basis = sale.costBasisAtSale ?? avg;
          
          final actualSale = sale.copyWith(
            shares: processedShares,
            costBasisAtSale: basis,
          );
          currentSales.add(actualSale);

          runningTotalCost -= processedShares * basis;
          currentShares -= processedShares;
        }
      }
    }

    // Add the final open or partially closed position
    if (currentBuys.isNotEmpty || currentSales.isNotEmpty) {
      closePosition(currentSales.isNotEmpty ? currentSales.last.date : null);
    }

    return positions;
  }
}
