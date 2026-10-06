import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/utils/currency_formatter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:stock_investment_tracker/domain/entities/position.dart';
import 'package:stock_investment_tracker/domain/calculator/position_calculator.dart';
import 'package:stock_investment_tracker/domain/entities/stock_summary.dart';
import 'package:stock_investment_tracker/domain/entities/portfolio_summary.dart';
import 'package:stock_investment_tracker/domain/entities/withdrawal.dart';

class PdfReportService {
  static final NumberFormat _wholeFormat = NumberFormat('#,##0');
  static final DateFormat _dateFormat = DateFormat('MMM d, y');

  static Future<pw.ImageProvider?> _loadAssetImage(String path) async {
    try {
      final bytes = await rootBundle.load(path);
      return pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  // Modern Financial Theme Colors for PDF
  static const PdfColor _primaryColor = PdfColor.fromInt(0xFF10B981); // Emerald Green
  static const PdfColor _accentColor = PdfColor.fromInt(0xFF0F172A); // Slate Dark
  static const PdfColor _greenColor = PdfColor.fromInt(0xFF059669); // Money Green
  static const PdfColor _redColor = PdfColor.fromInt(0xFFDC2626); // Alert Red
  static const PdfColor _lightBgColor = PdfColor.fromInt(0xFFF8FAFC); // Slate 50
  static const PdfColor _borderColor = PdfColor.fromInt(0xFFE2E8F0); // Slate 200
  static const PdfColor _headerBgColor = PdfColor.fromInt(0xFF1E293B); // Slate 800

  static final List<PdfColor> _sliceColors = [
    const PdfColor.fromInt(0xFF10B981),
    const PdfColor.fromInt(0xFF3B82F6),
    const PdfColor.fromInt(0xFFA855F7),
    const PdfColor.fromInt(0xFFF59E0B),
    const PdfColor.fromInt(0xFFEC4899),
    const PdfColor.fromInt(0xFF06B6D4),
    const PdfColor.fromInt(0xFF84CC16),
  ];

  /// 1. Export Overall Portfolio Executive Report
  static Future<void> exportOverallPortfolioPdf({
    required List<Position> positions,
    required PortfolioSummary summary,
    required List<StockSummary> stockSummaries,
    List<Withdrawal> withdrawals = const [],
  }) async {
    final appLogo = await _loadAssetImage('assets/icon/Stockk.png');
    final cdLogo = await _loadAssetImage('assets/icon/android-chrome-192x192.png');
    final pdf = pw.Document();

    // Collect all sales events across all positions
    final allSalesList = <Map<String, dynamic>>[];
    for (final position in positions) {
      if (position.sales.isNotEmpty) {
        for (final sale in position.sales) {
          allSalesList.add({
            'ticker': position.ticker,
            'sellDate': sale.date,
            'sharesSold': sale.shares,
            'buyPrice': sale.costBasisAtSale ?? 0.0,
            'sellPrice': sale.pricePerShare,
            'amountReceived': sale.amountReceived,
            'profit': sale.realizedPL,
          });
        }
      }
    }
    allSalesList.sort((a, b) => (b['sellDate'] as DateTime).compareTo(a['sellDate'] as DateTime));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader(
          title: 'Overall Portfolio & Financial Performance Report',
          appLogo: appLogo,
          cdLogo: cdLogo,
        ),
        footer: (context) => _buildPdfFooter(context, cdLogo: cdLogo),
        build: (context) => [
          pw.SizedBox(height: 12),
          // Executive Summary Banner
          _buildExecutiveSummaryBanner(summary, positions.length),
          pw.SizedBox(height: 20),

          // Profit Withdrawals (cash taken out of realized profit)
          if (withdrawals.isNotEmpty) ...[
            _buildSectionTitle('Profit Withdrawals & Cash Outflows'),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: _redColor),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _borderColor))),
              oddRowDecoration: const pw.BoxDecoration(color: _lightBgColor),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              headers: ['Withdrawal Date', 'Amount Withdrawn', 'Note'],
              data: [
                ...withdrawals.map<List<dynamic>>((w) => [
                      _dateFormat.format(w.date),
                      '-${AppCurrencyFormatter.format(w.amount)}',
                      w.note.isEmpty ? '-' : w.note,
                    ]),
                [
                  'TOTAL WITHDRAWN',
                  '-${AppCurrencyFormatter.format(summary.totalWithdrawn)}',
                  '${withdrawals.length} withdrawal${withdrawals.length == 1 ? '' : 's'}',
                ],
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Withdrawals are cash removed from realized profit. They reduce the net realized P/L, the portfolio value and the liquid capital, but not the starting capital or the amount currently invested in stocks.',
              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 20),
          ],

          // Visual Breakdown Section
          if (stockSummaries.isNotEmpty) ...[
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Portfolio Stock Allocation Bar
                pw.Expanded(
                  flex: 1,
                  child: _buildAllocationBar(stockSummaries, positions: positions),
                ),
                pw.SizedBox(width: 16),
                // Realized P/L Distribution Progress Bars
                pw.Expanded(
                  flex: 1,
                  child: _buildProfitLossBarSummary(stockSummaries),
                ),
              ],
            ),
            pw.SizedBox(height: 24),
          ],

          // Stock Performance Summary Table
          _buildSectionTitle('Stock Portfolio Holdings & Summaries'),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: _headerBgColor),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _borderColor))),
            oddRowDecoration: const pw.BoxDecoration(color: _lightBgColor),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            headers: ['Ticker', 'Shares Remaining', 'Avg Buy Price', 'Amount Invested', 'Realized P/L', 'Status'],
            data: stockSummaries.map<List<dynamic>>((s) {
              final isProfit = s.realizedPL >= 0;
              return [
                s.ticker,
                _wholeFormat.format(s.sharesHeld),
                AppCurrencyFormatter.format(s.avgBuyPrice),
                AppCurrencyFormatter.format(s.amountInvestedOpen),
                '${isProfit ? "+" : "-"}${AppCurrencyFormatter.format(s.realizedPL.abs())}',
                s.status.name.toUpperCase(),
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 24),

          // Detailed Sales History Table (if any sales exist)
          if (allSalesList.isNotEmpty) ...[
            _buildSectionTitle('Complete Sales & Realized Profit History'),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: _primaryColor),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _borderColor))),
              oddRowDecoration: const pw.BoxDecoration(color: _lightBgColor),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              headers: ['Date', 'Ticker', 'Shares Sold', 'Buy Price', 'Sell Price', 'Amount Received', 'Realized P/L'],
              data: allSalesList.map<List<dynamic>>((sale) {
                final double profit = sale['profit'] as double;
                final isProfit = profit >= 0;
                return [
                  _dateFormat.format(sale['sellDate'] as DateTime),
                  sale['ticker'],
                  _wholeFormat.format(sale['sharesSold']),
                  AppCurrencyFormatter.format(sale['buyPrice'] as num),
                  AppCurrencyFormatter.format(sale['sellPrice'] as num),
                  AppCurrencyFormatter.format(sale['amountReceived'] as num),
                  '${isProfit ? "+" : "-"}${AppCurrencyFormatter.format(profit.abs())}',
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 24),
          ],

          // Detailed Positions Table
          _buildSectionTitle('All Positions & Transaction Records'),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8.5),
            headerDecoration: const pw.BoxDecoration(color: _headerBgColor),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _borderColor))),
            oddRowDecoration: const pw.BoxDecoration(color: _lightBgColor),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            headers: ['Ticker', 'Open Date', 'Purchased', 'Avg Cost', 'Remaining', 'Holding', 'Status', 'Realized P/L'],
            data: positions.map<List<dynamic>>((pos) {
              final realizedPL = PositionCalculator.realizedPL(pos);
              final isProfit = realizedPL >= 0;
              final purchased = pos.buys.fold<int>(0, (sum, b) => sum + b.shares);
              final remaining = PositionCalculator.sharesHeld(pos);
              return [
                pos.ticker,
                _dateFormat.format(pos.openedAt),
                _wholeFormat.format(purchased),
                AppCurrencyFormatter.format(PositionCalculator.avgCost(pos)),
                '${_wholeFormat.format(remaining)} sh',
                '${PositionCalculator.holdingDays(pos)}d',
                pos.status.name.toUpperCase(),
                '${isProfit ? "+" : "-"}${AppCurrencyFormatter.format(realizedPL.abs())}',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Stocks_Portfolio_Report.pdf',
    );
  }

  /// 2. Export Per-Stock Detailed Performance Report (LOT-WISE grouping).
  /// Each Position (lot) is shown as a separate section with its own buy
  /// history, so multi-buy lots are clearly visible per lot.
  static Future<void> exportStockPdf({
    required String ticker,
    required List<Position> positions,
    required StockSummary? summary,
  }) async {
    final appLogo = await _loadAssetImage('assets/icon/Stockk.png');
    final cdLogo = await _loadAssetImage('assets/icon/android-chrome-192x192.png');
    final pdf = pw.Document();

    var totalPurchasedShares = 0;
    var totalCapitalPurchased = 0.0;
    var totalRealizedPL = 0.0;
    var totalSalesReceived = 0.0;
    var totalRemainingShares = 0;

    for (final position in positions) {
      final pBuysShares = position.buys.fold<int>(0, (sum, b) => sum + b.shares);
      final pBuysCost = position.buys.fold<double>(0.0, (sum, b) => sum + (b.shares * b.pricePerShare));
      totalPurchasedShares += pBuysShares;
      totalCapitalPurchased += pBuysCost;
      totalRemainingShares += PositionCalculator.sharesHeld(position);
      totalRealizedPL += PositionCalculator.realizedPL(position);
      totalSalesReceived +=
          position.sales.fold<double>(0.0, (sum, s) => sum + s.amountReceived);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader(
          title: '$ticker Stock Performance & Trades Audit',
          appLogo: appLogo,
          cdLogo: cdLogo,
        ),
        footer: (context) => _buildPdfFooter(context, cdLogo: cdLogo),
        build: (context) => [
          pw.SizedBox(height: 12),
          // Overview Metrics Card
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: _lightBgColor,
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: _borderColor),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('$ticker EXECUTIVE METRICS',
                    style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700)),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricItem('Total Lots',
                        '${positions.length} lot${positions.length == 1 ? '' : 's'}'),
                    _buildMetricItem('Total Shares Bought',
                        _wholeFormat.format(totalPurchasedShares)),
                    _buildMetricItem('Total Capital Deployed',
                        AppCurrencyFormatter.format(totalCapitalPurchased)),
                    _buildMetricItem(
                        'Shares Remaining',
                        _wholeFormat.format(totalRemainingShares)),
                    _buildMetricItem('Total Sales Received',
                        AppCurrencyFormatter.format(totalSalesReceived)),
                    _buildMetricItem(
                      'Realized Profit/Loss',
                      '${totalRealizedPL >= 0 ? "+" : "-"}${AppCurrencyFormatter.format(totalRealizedPL.abs())}',
                      color: totalRealizedPL >= 0 ? _greenColor : _redColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // ── LOT-WISE POSITION & TRADE AUDIT ──────────────────────────────
          _buildSectionTitle('Lot-wise Trade History for $ticker'),
          pw.SizedBox(height: 4),
          pw.Text(
            'Each lot below represents a separate position opened for $ticker. All buy tranches and associated sale records are audited lot by lot.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 12),

          ...positions.asMap().entries.expand((entry) {
            final lotIndex = entry.key + 1;
            final position = entry.value;
            final lotRealizedPL = PositionCalculator.realizedPL(position);
            final lotPurchased =
                position.buys.fold<int>(0, (sum, b) => sum + b.shares);
            final lotPurchasedCost = position.buys
                .fold<double>(0.0, (sum, b) => sum + (b.shares * b.pricePerShare));
            final lotAvgBuyPrice =
                lotPurchased > 0 ? (lotPurchasedCost / lotPurchased) : 0.0;
            final lotRemaining = PositionCalculator.sharesHeld(position);
            final lotSoldShares =
                position.sales.fold<int>(0, (sum, s) => sum + s.shares);
            final lotSalesReceived = position.sales
                .fold<double>(0.0, (sum, s) => sum + s.amountReceived);
            final isPL = lotRealizedPL >= 0;

            final statusColor = position.status.name == 'closed'
                ? _redColor
                : (position.status.name == 'partiallySold'
                    ? const PdfColor.fromInt(0xFFF59E0B)
                    : _primaryColor);

            return [
              // Lot header banner (2-tier layout with breathing room)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: _headerBgColor,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Top Row: Lot number & Dates + Status Badge
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'Lot #$lotIndex  ·  Opened ${_dateFormat.format(position.openedAt)}${position.closedAt != null ? "  ·  Closed ${_dateFormat.format(position.closedAt!)}" : ""}',
                          style: pw.TextStyle(
                              fontSize: 9.5,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2.5),
                          decoration: pw.BoxDecoration(
                            color: statusColor,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            position.status.name.toUpperCase(),
                            style: const pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 7.5,
                                fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      child: pw.Divider(color: const PdfColor.fromInt(0xFF2E384D), thickness: 0.5),
                    ),
                    // Bottom Row: Summary stats for this lot
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '${_wholeFormat.format(lotPurchased)} sh bought  ·  ${_wholeFormat.format(lotRemaining)} remaining  ·  Avg Buy ${AppCurrencyFormatter.format(lotAvgBuyPrice)}',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey300),
                        ),
                        pw.Text(
                          'P/L ${isPL ? '+' : '-'}${AppCurrencyFormatter.format(lotRealizedPL.abs())}',
                          style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: isPL ? _greenColor : _redColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),

              // ── Buys table for this lot ──
              if (position.buys.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                      color: _lightBgColor,
                      borderRadius: pw.BorderRadius.circular(6)),
                  child: pw.Text('No buy records for this lot.',
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey600)),
                )
              else
                pw.TableHelper.fromTextArray(
                  headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      fontSize: 8),
                  headerDecoration:
                      const pw.BoxDecoration(color: _primaryColor),
                  rowDecoration: const pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(color: _borderColor))),
                  oddRowDecoration:
                      const pw.BoxDecoration(color: _lightBgColor),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellStyle: const pw.TextStyle(fontSize: 7.5),
                  cellPadding: const pw.EdgeInsets.symmetric(
                      horizontal: 6, vertical: 4),
                  headers: [
                    '#',
                    'Buy Date',
                    'Shares Purchased',
                    'Buy Price / Share',
                    'Amount Invested'
                  ],
                  data: [
                    ...position.buys.asMap().entries.map<List<dynamic>>((bEntry) {
                      final bIdx = bEntry.key + 1;
                      final buy = bEntry.value;
                      return [
                        '$bIdx',
                        _dateFormat.format(buy.date),
                        _wholeFormat.format(buy.shares),
                        AppCurrencyFormatter.format(buy.pricePerShare),
                        AppCurrencyFormatter.format(
                            buy.shares * buy.pricePerShare),
                      ];
                    }),
                    if (position.buys.length > 1) [
                      'TOTAL',
                      '${position.buys.length} buys',
                      _wholeFormat.format(lotPurchased),
                      'Avg ${AppCurrencyFormatter.format(lotAvgBuyPrice)}',
                      AppCurrencyFormatter.format(lotPurchasedCost),
                    ],
                  ],
                ),

              pw.SizedBox(height: 6),

              // ── Sales table for this lot ──
              if (position.sales.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                      color: _lightBgColor,
                      borderRadius: pw.BorderRadius.circular(6)),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        'Sales for Lot #$lotIndex:  ',
                        style: pw.TextStyle(
                            fontSize: 7.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700),
                      ),
                      pw.Text(
                        'No sales recorded against this lot yet.',
                        style: const pw.TextStyle(
                            fontSize: 7.5, color: PdfColors.grey500),
                      ),
                    ],
                  ),
                )
              else
                pw.TableHelper.fromTextArray(
                  headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      fontSize: 8),
                  headerDecoration:
                      const pw.BoxDecoration(color: _headerBgColor),
                  rowDecoration: const pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(color: _borderColor))),
                  oddRowDecoration:
                      const pw.BoxDecoration(color: _lightBgColor),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellStyle: const pw.TextStyle(fontSize: 7.5),
                  cellPadding: const pw.EdgeInsets.symmetric(
                      horizontal: 6, vertical: 4),
                  headers: [
                    '#',
                    'Sell Date',
                    'Shares Sold',
                    'Cost Basis / Sh',
                    'Sell Price / Sh',
                    'Amount Received',
                    'Realized P/L'
                  ],
                  data: [
                    ...position.sales.asMap().entries.map<List<dynamic>>((sEntry) {
                      final sIdx = sEntry.key + 1;
                      final sale = sEntry.value;
                      final profit = sale.realizedPL;
                      final isSaleProfit = profit >= 0;
                      return [
                        '$sIdx',
                        _dateFormat.format(sale.date),
                        _wholeFormat.format(sale.shares),
                        AppCurrencyFormatter.format(sale.costBasisAtSale ?? 0.0),
                        AppCurrencyFormatter.format(sale.pricePerShare),
                        AppCurrencyFormatter.format(sale.amountReceived),
                        '${isSaleProfit ? "+" : "-"}${AppCurrencyFormatter.format(profit.abs())}',
                      ];
                    }),
                    if (position.sales.length > 1) [
                      'TOTAL',
                      '${position.sales.length} sales',
                      _wholeFormat.format(lotSoldShares),
                      '-',
                      '-',
                      AppCurrencyFormatter.format(lotSalesReceived),
                      '${isPL ? "+" : "-"}${AppCurrencyFormatter.format(lotRealizedPL.abs())}',
                    ],
                  ],
                ),

              pw.SizedBox(height: 14),
            ];
          }),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${ticker}_Stock_Report.pdf',
    );
  }

  /// 2b. Export Withdrawals-Only PDF.
  /// Called from the dedicated WithdrawalListScreen.
  static Future<void> exportWithdrawalsPdf({
    required List<Withdrawal> withdrawals,
    required double totalWithdrawn,
    required double grossRealizedPL,
  }) async {
    final appLogo = await _loadAssetImage('assets/icon/Stockk.png');
    final cdLogo = await _loadAssetImage('assets/icon/android-chrome-192x192.png');
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader(
          title: 'Profit Withdrawals Report',
          appLogo: appLogo,
          cdLogo: cdLogo,
        ),
        footer: (context) => _buildPdfFooter(context, cdLogo: cdLogo),
        build: (context) => [
          pw.SizedBox(height: 12),
          // Summary banner
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: _lightBgColor,
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: _borderColor),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricItem(
                    'Total Withdrawals', '${withdrawals.length}'),
                _buildMetricItem(
                    'Total Withdrawn',
                    '-${AppCurrencyFormatter.format(totalWithdrawn)}',
                    color: _redColor),
                _buildMetricItem(
                    'Gross Realized P/L',
                    '${grossRealizedPL >= 0 ? '+' : '-'}${AppCurrencyFormatter.format(grossRealizedPL.abs())}',
                    color: grossRealizedPL >= 0 ? _greenColor : _redColor),
                _buildMetricItem(
                    'Net Realized P/L',
                    '${(grossRealizedPL - totalWithdrawn) >= 0 ? '+' : '-'}${AppCurrencyFormatter.format((grossRealizedPL - totalWithdrawn).abs())}',
                    color: (grossRealizedPL - totalWithdrawn) >= 0
                        ? _greenColor
                        : _redColor),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          _buildSectionTitle('Withdrawal Records'),
          pw.SizedBox(height: 8),
          if (withdrawals.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                  color: _lightBgColor,
                  borderRadius: pw.BorderRadius.circular(8)),
              child: pw.Text('No withdrawals recorded yet.',
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey600)),
            )
          else
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: _redColor),
              rowDecoration: const pw.BoxDecoration(
                  border:
                      pw.Border(bottom: pw.BorderSide(color: _borderColor))),
              oddRowDecoration: const pw.BoxDecoration(color: _lightBgColor),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              headers: ['#', 'Withdrawal Date', 'Amount Withdrawn', 'Note'],
              data: withdrawals.asMap().entries.map<List<dynamic>>((e) {
                final idx = e.key + 1;
                final w = e.value;
                return [
                  '$idx',
                  _dateFormat.format(w.date),
                  '-${AppCurrencyFormatter.format(w.amount)}',
                  w.note.isEmpty ? '-' : w.note,
                ];
              }).toList(),
            ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Withdrawals represent cash taken out of realized profit. They reduce net realized P/L and liquid capital, but do not affect starting capital or currently invested amounts.',
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Withdrawals_Report.pdf',
    );
  }

  /// 3. Export Per-Position Detailed Audit Report
  static Future<void> exportPositionPdf(Position position) async {
    final appLogo = await _loadAssetImage('assets/icon/Stockk.png');
    final cdLogo = await _loadAssetImage('assets/icon/android-chrome-192x192.png');
    final pdf = pw.Document();
    final realizedPL = PositionCalculator.realizedPL(position);
    final isProfit = realizedPL >= 0;

    final salesList = position.sales;
    final totalAmountReceived = salesList.fold<double>(0.0, (sum, s) => sum + s.amountReceived);
    final totalPurchased = position.buys.fold<int>(0, (sum, b) => sum + b.shares);
    final totalBuysCost = position.buys.fold<double>(0.0, (sum, b) => sum + (b.shares * b.pricePerShare));
    final avgBuyPrice = totalPurchased > 0 ? (totalBuysCost / totalPurchased) : 0.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader(
          title: '${position.ticker} Position Audit Report',
          appLogo: appLogo,
          cdLogo: cdLogo,
        ),
        footer: (context) => _buildPdfFooter(context, cdLogo: cdLogo),
        build: (context) => [
          pw.SizedBox(height: 16),

          // Position Summary Card
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: _lightBgColor,
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: _borderColor),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '${position.ticker} POSITION AUDIT SUMMARY',
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _accentColor),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: _primaryColor,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Text(
                          position.status.name.toUpperCase(),
                          style: const pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricItem('Open Date', _dateFormat.format(position.openedAt)),
                      _buildMetricItem('Shares Purchased', _wholeFormat.format(totalPurchased)),
                      _buildMetricItem('Avg Buy Price / Sh', AppCurrencyFormatter.format(avgBuyPrice)),
                      _buildMetricItem('Total Capital Deployed', AppCurrencyFormatter.format(totalBuysCost)),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricItem('Holding Period', '${PositionCalculator.holdingDays(position)} Days'),
                      _buildMetricItem('Remaining Shares', '${_wholeFormat.format(PositionCalculator.sharesHeld(position))} sh'),
                      _buildMetricItem('Total Sales Received', AppCurrencyFormatter.format(totalAmountReceived)),
                      _buildMetricItem(
                        'Realized Profit / Loss',
                        '${isProfit ? "+" : "-"}${AppCurrencyFormatter.format(realizedPL.abs())}',
                        color: isProfit ? _greenColor : _redColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),

          pw.SizedBox(height: 24),
          _buildSectionTitle('Buys Audit Log (Buy Price & Date Details)'),
          pw.SizedBox(height: 8),

          if (position.buys.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(color: _lightBgColor, borderRadius: pw.BorderRadius.circular(8)),
              child: pw.Text('No buys recorded for this position.', style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9)),
            )
          else
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: _headerBgColor),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _borderColor))),
              oddRowDecoration: const pw.BoxDecoration(color: _lightBgColor),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              headers: ['Buy Date', 'Shares Purchased', 'Buy Price / Share', 'Amount Invested'],
              data: position.buys.map<List<dynamic>>((buy) {
                return [
                  _dateFormat.format(buy.date),
                  _wholeFormat.format(buy.shares),
                  AppCurrencyFormatter.format(buy.pricePerShare),
                  AppCurrencyFormatter.format(buy.shares * buy.pricePerShare),
                ];
              }).toList(),
            ),

          pw.SizedBox(height: 24),
          _buildSectionTitle('Sales Audit Log (Sale Price & Date Details)'),
          pw.SizedBox(height: 8),

          if (salesList.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(color: _lightBgColor, borderRadius: pw.BorderRadius.circular(8)),
              child: pw.Text('No sales recorded for this position yet.', style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9)),
            )
          else
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: _headerBgColor),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _borderColor))),
              oddRowDecoration: const pw.BoxDecoration(color: _lightBgColor),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              headers: ['Sell Date', 'Shares Sold', 'Cost Basis / Share', 'Sell Price / Share', 'Amount Received', 'Realized P/L'],
              data: salesList.map<List<dynamic>>((sale) {
                final saleProfit = sale.realizedPL;
                final saleIsProfit = saleProfit >= 0;
                return [
                  _dateFormat.format(sale.date),
                  _wholeFormat.format(sale.shares),
                  AppCurrencyFormatter.format(sale.costBasisAtSale ?? 0.0),
                  AppCurrencyFormatter.format(sale.pricePerShare),
                  AppCurrencyFormatter.format(sale.amountReceived),
                  '${saleIsProfit ? "+" : "-"}${AppCurrencyFormatter.format(saleProfit.abs())}',
                ];
              }).toList(),
            ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${position.ticker}_Position_Report.pdf',
    );
  }

  // --- Helper Widgets & Visual Components ---

  static pw.Widget _buildExecutiveSummaryBanner(PortfolioSummary summary, int totalLotsCount) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _lightBgColor,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _borderColor),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('EXECUTIVE PORTFOLIO SUMMARY', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem('Total Capital Invested', AppCurrencyFormatter.format(summary.totalInvested)),
              _buildMetricItem(
                'Realized Profit / Loss',
                '${summary.realizedPL >= 0 ? "+" : "-"}${AppCurrencyFormatter.format(summary.realizedPL.abs())}',
                color: summary.realizedPL >= 0 ? _greenColor : _redColor,
              ),
              _buildMetricItem('Active Investment Value', AppCurrencyFormatter.format(summary.currentlyInvested)),
              _buildMetricItem('Total Lots Count', '${summary.openLots} Active / ${totalLotsCount - summary.openLots} Closed'),
            ],
          ),
          if (summary.totalWithdrawn > 0) ...[
            pw.SizedBox(height: 12),
            pw.Divider(color: _borderColor, thickness: 0.5),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricItem(
                  'Gross Trading Profit',
                  '${summary.grossRealizedPL >= 0 ? "+" : "-"}${AppCurrencyFormatter.format(summary.grossRealizedPL.abs())}',
                  color: summary.grossRealizedPL >= 0 ? _greenColor : _redColor,
                ),
                _buildMetricItem(
                  'Profit Withdrawn',
                  '-${AppCurrencyFormatter.format(summary.totalWithdrawn)}',
                  color: _redColor,
                ),
                _buildMetricItem(
                  'Net Profit In Account',
                  '${summary.realizedPL >= 0 ? "+" : "-"}${AppCurrencyFormatter.format(summary.realizedPL.abs())}',
                  color: summary.realizedPL >= 0 ? _greenColor : _redColor,
                ),
                _buildMetricItem('Portfolio Value', AppCurrencyFormatter.format(summary.portfolioValue)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildAllocationBar(
    List<StockSummary> stockSummaries, {
    List<Position>? positions,
  }) {
    final activeSummaries = stockSummaries.where((s) => s.amountInvestedOpen > 0).toList();
    final totalInvested = activeSummaries.fold<double>(0, (sum, s) => sum + s.amountInvestedOpen);

    // If there is active capital invested, show the active portfolio allocation bar
    if (totalInvested > 0) {
      return pw.Container(
        height: 140,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(10),
          border: pw.Border.all(color: _borderColor),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Portfolio Capital Allocation',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _accentColor),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: _lightBgColor,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: _borderColor),
                  ),
                  child: pw.Text(
                    AppCurrencyFormatter.format(totalInvested),
                    style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _primaryColor),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            // Horizontal Stacked Bar
            pw.ClipRRect(
              horizontalRadius: 4,
              verticalRadius: 4,
              child: pw.Container(
                height: 14,
                child: pw.Row(
                  children: List<pw.Widget>.generate(activeSummaries.length, (i) {
                    final s = activeSummaries[i];
                    final pct = s.amountInvestedOpen / totalInvested;
                    final flex = (pct * 1000).toInt().clamp(1, 1000);
                    return pw.Expanded(
                      flex: flex,
                      child: pw.Container(
                        color: _sliceColors[i % _sliceColors.length],
                      ),
                    );
                  }),
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            // Legend items
            pw.Expanded(
              child: pw.Wrap(
                spacing: 12,
                runSpacing: 6,
                children: List<pw.Widget>.generate(
                  activeSummaries.length > 6 ? 6 : activeSummaries.length,
                  (i) {
                    final s = activeSummaries[i];
                    final pct = (s.amountInvestedOpen / totalInvested * 100);
                    final color = _sliceColors[i % _sliceColors.length];
                    return pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Container(
                          width: 7,
                          height: 7,
                          decoration: pw.BoxDecoration(
                            color: color,
                            borderRadius: pw.BorderRadius.circular(2),
                          ),
                        ),
                        pw.SizedBox(width: 4),
                        pw.Text(
                          '${s.ticker} (${pct.toStringAsFixed(1)}%)',
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            fontWeight: pw.FontWeight.bold,
                            color: _accentColor,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    // When there are no active holdings (e.g. all closed or cash), display lifetime traded capital allocation
    final lifetimeTraded = <String, double>{};
    if (positions != null && positions.isNotEmpty) {
      for (final p in positions) {
        final cost = p.buys.fold<double>(0.0, (sum, b) => sum + (b.shares * b.pricePerShare));
        if (cost > 0) {
          lifetimeTraded[p.ticker] = (lifetimeTraded[p.ticker] ?? 0.0) + cost;
        }
      }
    }

    if (lifetimeTraded.isNotEmpty) {
      final totalLifetime = lifetimeTraded.values.fold<double>(0.0, (sum, v) => sum + v);
      final entries = lifetimeTraded.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return pw.Container(
        height: 140,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(10),
          border: pw.Border.all(color: _borderColor),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Lifetime Traded Capital Allocation',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _accentColor),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: _lightBgColor,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: _borderColor),
                  ),
                  child: pw.Text(
                    AppCurrencyFormatter.format(totalLifetime),
                    style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _primaryColor),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            // Horizontal Stacked Bar
            pw.ClipRRect(
              horizontalRadius: 4,
              verticalRadius: 4,
              child: pw.Container(
                height: 14,
                child: pw.Row(
                  children: List<pw.Widget>.generate(entries.length, (i) {
                    final e = entries[i];
                    final pct = e.value / totalLifetime;
                    final flex = (pct * 1000).toInt().clamp(1, 1000);
                    return pw.Expanded(
                      flex: flex,
                      child: pw.Container(
                        color: _sliceColors[i % _sliceColors.length],
                      ),
                    );
                  }),
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            // Legend items
            pw.Expanded(
              child: pw.Wrap(
                spacing: 12,
                runSpacing: 6,
                children: List<pw.Widget>.generate(
                  entries.length > 6 ? 6 : entries.length,
                  (i) {
                    final e = entries[i];
                    final pct = (e.value / totalLifetime * 100);
                    final color = _sliceColors[i % _sliceColors.length];
                    return pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Container(
                          width: 7,
                          height: 7,
                          decoration: pw.BoxDecoration(
                            color: color,
                            borderRadius: pw.BorderRadius.circular(2),
                          ),
                        ),
                        pw.SizedBox(width: 4),
                        pw.Text(
                          '${e.key} (${pct.toStringAsFixed(1)}%)',
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            fontWeight: pw.FontWeight.bold,
                            color: _accentColor,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Fallback card if neither active nor lifetime positions exist
    return pw.Container(
      height: 140,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _borderColor),
      ),
      child: pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'Portfolio Capital Allocation',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _accentColor),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'No active stock holdings. 100% of capital in cash.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildProfitLossBarSummary(List<StockSummary> stockSummaries) {
    final maxPL = stockSummaries.fold<double>(0, (max, s) => s.realizedPL.abs() > max ? s.realizedPL.abs() : max);

    return pw.Container(
      height: 140,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _borderColor),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Realized P/L Summary by Stock', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _accentColor)),
          pw.SizedBox(height: 8),
          pw.Expanded(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: List<pw.Widget>.generate(
                stockSummaries.length > 4 ? 4 : stockSummaries.length,
                (i) {
                  final s = stockSummaries[i];
                  final isProfit = s.realizedPL >= 0;
                  final barPct = maxPL > 0 ? (s.realizedPL.abs() / maxPL) : 0.0;
                  return pw.Row(
                    children: [
                      pw.SizedBox(width: 40, child: pw.Text(s.ticker, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      // Simple bar using a Container with calculated width
                      pw.Container(
                        width: 120 * barPct.clamp(0.05, 1.0),
                        height: 10,
                        decoration: pw.BoxDecoration(
                          color: isProfit ? _greenColor : _redColor,
                          borderRadius: pw.BorderRadius.circular(5),
                        ),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Text(
                        '${isProfit ? "+" : "-"}${AppCurrencyFormatter.format(s.realizedPL.abs())}',
                        style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: isProfit ? _greenColor : _redColor),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _accentColor),
    );
  }

  static pw.Widget _buildPdfHeader({
    required String title,
    pw.ImageProvider? appLogo,
    pw.ImageProvider? cdLogo,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (appLogo != null) ...[
                  pw.ClipRRect(
                    horizontalRadius: 6,
                    verticalRadius: 6,
                    child: pw.Image(appLogo, width: 34, height: 34),
                  ),
                  pw.SizedBox(width: 8),
                ] else ...[
                  pw.Container(
                    width: 10,
                    height: 10,
                    decoration: const pw.BoxDecoration(color: _primaryColor, shape: pw.BoxShape.circle),
                  ),
                  pw.SizedBox(width: 6),
                ],
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Stock Book',
                      style: pw.TextStyle(
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                        color: _accentColor,
                      ),
                    ),
                    pw.Text(
                      'Report Date: ${_dateFormat.format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 10.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _accentColor,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      'Powered by Coding District',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.grey600,
                      ),
                    ),
                    if (cdLogo != null) ...[
                      pw.SizedBox(width: 4),
                      pw.ClipRRect(
                        horizontalRadius: 3,
                        verticalRadius: 3,
                        child: pw.Image(cdLogo, width: 12, height: 12),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: _borderColor, thickness: 1),
      ],
    );
  }

  static pw.Widget _buildPdfFooter(pw.Context context, {pw.ImageProvider? cdLogo}) {
    return pw.Column(
      children: [
        pw.Divider(color: _borderColor, thickness: 1),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(
              children: [
                pw.Text(
                  'Stock Book · Powered by Coding District',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
                if (cdLogo != null) ...[
                  pw.SizedBox(width: 4),
                  pw.ClipRRect(
                    horizontalRadius: 2,
                    verticalRadius: 2,
                    child: pw.Image(cdLogo, width: 10, height: 10),
                  ),
                ],
              ],
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildMetricItem(String label, String value, {PdfColor? color}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: color ?? _accentColor),
        ),
      ],
    );
  }
}
