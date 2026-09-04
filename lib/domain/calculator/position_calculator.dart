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

  /// Walks this position's buy/sell history once and returns the *precise*
  /// (unrounded) remaining total cost — the single source of truth both
  /// [avgCost] and [totalCost]/[amountInvested] derive from.
  ///
  /// This exists so those three functions cannot disagree with each other.
  /// [avgCost] used to be the only function that walked events directly, and
  /// [totalCost]/[amountInvested] multiplied `sharesHeld × avgCost(p)` — but
  /// `avgCost(p)` is *already rounded to 2dp* by the time it's returned, so
  /// that multiplication re-introduces the exact "rounding an intermediate
  /// value" problem the model's rule 5 rules out. On the STPL reference case
  /// (1,700 sh, avg 8.4829..., rounded to 8.48) that was worth Rs 4.41 of
  /// drift on one position — sharesHeld(1500) × roundedAvg(8.48) = 12,720.00
  /// against a true remaining cost of 12,724.41. Computing straight from the
  /// unrounded running total avoids it.
  static double _preciseTotalCost(Position p) {
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

    return currentShares <= 0 ? 0.0 : totalCost;
  }

  static double avgCost(Position p) {
    final remaining = sharesHeld(p);
    if (remaining <= 0) return 0.0;
    return _round(_preciseTotalCost(p) / remaining);
  }

  static int sharesHeld(Position p) {
    int bought = p.buys.fold(0, (sum, b) => sum + b.shares);
    int sold = p.sales.fold(0, (sum, s) => sum + s.shares);
    int remaining = bought - sold;
    return remaining < 0 ? 0 : remaining;
  }

  static double totalCost(Position p) {
    return _round(_preciseTotalCost(p));
  }

  static double realizedPL(Position p) {
    return _round(p.sales.fold(0.0, (sum, s) => sum + s.realizedPL));
  }

  static double amountInvested(Position p) {
    return _round(_preciseTotalCost(p));
  }

  static int holdingDays(Position p) {
    if (p.buys.isEmpty) return 0;
    
    // Uses openedAt (which should match the first buy's date)
    final start = p.openedAt;
    
    // If closed, compare with closedAt, else compare with today
    final end = p.status == PositionStatus.closed && p.closedAt != null 
        ? p.closedAt! 
        : DateTime.now();
        
    return end.difference(start).inDays;
  }

  /// Total shares ever bought in this cycle. Unlike [sharesHeld] this does not
  /// shrink as shares are sold, so it still means something once the position
  /// is closed.
  static int totalSharesBought(Position p) {
    return p.buys.fold(0, (sum, b) => sum + b.shares);
  }

  /// Total capital put into this cycle across every buy, ignoring sales.
  ///
  /// [amountInvested] answers "how much is still tied up in shares I hold" and
  /// correctly drops to 0 when the position closes. This answers "how much did
  /// I put in", which is what a closed card needs to show instead of Rs 0.
  static double totalCapitalDeployed(Position p) {
    return _round(
      p.buys.fold(0.0, (sum, b) => sum + b.shares * b.pricePerShare),
    );
  }

  /// The blended price actually paid across this cycle's buys.
  ///
  /// Same relationship to [avgCost] as [totalCapitalDeployed] has to
  /// [amountInvested]: this one survives the position closing.
  static double historicalAvgCost(Position p) {
    final shares = totalSharesBought(p);
    if (shares <= 0) return 0.0;
    final total = p.buys.fold(0.0, (sum, b) => sum + b.shares * b.pricePerShare);
    return _round(total / shares);
  }

  /// Average cost of the shares still held across *all* cycles of one ticker —
  /// what the dashboard's per-ticker row shows.
  ///
  /// Sums the **unrounded** remaining cost and rounds once at the end. Summing
  /// [amountInvested] (already 2dp-rounded per position) or going through
  /// `sharesHeld × avgCost` would compound rounding error — see
  /// [_preciseTotalCost]'s note on the Rs 4.41 drift that caused.
  static double blendedAvgCost(List<Position> positionsForOneTicker) {
    double totalCost = 0.0;
    int totalShares = 0;
    for (final p in positionsForOneTicker) {
      totalCost += _preciseTotalCost(p);
      totalShares += sharesHeld(p);
    }
    if (totalShares <= 0) return 0.0;
    return _round(totalCost / totalShares);
  }

  /// Breaks a **closed** position back into one display-only position per buy,
  /// each carrying the sales that paid for it, matched oldest-buy-first (FIFO).
  ///
  /// Pooling a ticker's buys is the whole point of the merge model *while you
  /// hold it* — that's what gives one averaged open card. Once the cycle is
  /// closed, the useful record is per purchase again: what did this buy cost,
  /// and what did it make. A single sale that covered several buys is split
  /// across them, so shares and realized P/L both still add up to the original.
  ///
  /// The returned positions are **display-only** — their ids are synthetic
  /// (`<positionId>::<buyId>`) and their sales may be partial slices of a real
  /// sale. Never persist one; write through the position they came from.
  ///
  /// Returns `[p]` untouched when it isn't closed or has only one buy.
  static List<Position> splitByBuy(Position p) {
    if (p.status != PositionStatus.closed || p.buys.length <= 1) return [p];

    final buys = [...p.buys]..sort((a, b) => a.date.compareTo(b.date));
    final sales = [...p.sales]..sort((a, b) => a.date.compareTo(b.date));

    final unsoldPerBuy = {for (final b in buys) b.id: b.shares};
    final salesPerBuy = {for (final b in buys) b.id: <PositionSale>[]};
    final lastSaleDatePerBuy = <String, DateTime>{};

    for (final sale in sales) {
      var unallocated = sale.shares;
      for (final buy in buys) {
        if (unallocated <= 0) break;
        final capacity = unsoldPerBuy[buy.id]!;
        if (capacity <= 0) continue;

        final take = capacity < unallocated ? capacity : unallocated;
        unsoldPerBuy[buy.id] = capacity - take;
        unallocated -= take;

        salesPerBuy[buy.id]!.add(PositionSale(
          id: '${sale.id}::${buy.id}',
          date: sale.date,
          shares: take,
          pricePerShare: sale.pricePerShare,
          // Carried over untouched: the basis this sale was booked at is not
          // re-derived per slice, so profit still totals what it always did.
          costBasisAtSale: sale.costBasisAtSale,
        ));
        lastSaleDatePerBuy[buy.id] = sale.date;
      }
    }

    return [
      for (final buy in buys)
        Position(
          id: '${p.id}::${buy.id}',
          ticker: p.ticker,
          status: PositionStatus.closed,
          openedAt: buy.date,
          closedAt: lastSaleDatePerBuy[buy.id] ?? p.closedAt,
          buys: [buy],
          sales: salesPerBuy[buy.id]!,
        ),
    ];
  }

  /// The status a position should carry given its current buys/sales — the
  /// same 3-way rule `replay()` applies when first building positions, kept
  /// available here so every write path (add/edit a buy or sale) can restamp
  /// `Position.status` after mutating it, since the field is stored, not derived.
  static PositionStatus computeStatus(Position p) {
    final remaining = sharesHeld(p);
    if (remaining <= 0) return PositionStatus.closed;
    if (p.sales.isNotEmpty) return PositionStatus.partiallySold;
    return PositionStatus.open;
  }

  /// Returns the open (non-closed) position for [ticker], if any. A ticker can
  /// only have one non-closed position at a time under the merge model, so
  /// this is what "append to the open position, or start a new one" checks.
  static Position? findOpenPosition(List<Position> positions, String ticker) {
    for (final p in positions) {
      if (p.ticker == ticker && p.status != PositionStatus.closed) {
        return p;
      }
    }
    return null;
  }

  /// Appends a new buy to [p] and returns the updated position with status
  /// (and `closedAt`, cleared since a position with a new buy cannot be
  /// closed) recomputed. Pure — callers own persisting the result.
  static Position applyBuy(
    Position p, {
    required String buyId,
    required DateTime date,
    required int shares,
    required double pricePerShare,
  }) {
    final updatedBuys = List<PositionBuy>.from(p.buys)
      ..add(PositionBuy(
        id: buyId,
        date: date,
        shares: shares,
        pricePerShare: pricePerShare,
      ));
    final updated = p.copyWith(buys: updatedBuys, closedAt: null);
    return updated.copyWith(status: computeStatus(updated));
  }

  /// Appends a new sale to [p], freezing `costBasisAtSale` at the position's
  /// *current* avg cost — never recomputed later, per the model's core rule.
  /// Returns the updated position with status/`closedAt` recomputed.
  static Position applySell(
    Position p, {
    required String saleId,
    required DateTime date,
    required int shares,
    required double pricePerShare,
  }) {
    final costBasisAtSale = avgCost(p);
    final updatedSales = List<PositionSale>.from(p.sales)
      ..add(PositionSale(
        id: saleId,
        date: date,
        shares: shares,
        pricePerShare: pricePerShare,
        costBasisAtSale: costBasisAtSale,
      ));
    final updated = p.copyWith(sales: updatedSales);
    final newStatus = computeStatus(updated);
    return updated.copyWith(
      status: newStatus,
      closedAt: newStatus == PositionStatus.closed ? date : null,
    );
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
