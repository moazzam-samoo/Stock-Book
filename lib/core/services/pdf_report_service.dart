import 'package:intl/intl.dart';
import 'package:stock_investment_tracker/core/utils/currency_formatter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:stock_investment_tracker/domain/entities/lot.dart';
import 'package:stock_investment_tracker/domain/entities/stock_summary.dart';
import 'package:stock_investment_tracker/domain/entities/portfolio_summary.dart';

class PdfReportService {
  static final NumberFormat _wholeFormat = NumberFormat('#,##0');
  static final DateFormat _dateFormat = DateFormat('MMM d, y');

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
    required List<Lot> lots,
    required PortfolioSummary summary,
    required List<StockSummary> stockSummaries,
  }) async {
    final pdf = pw.Document();

    // Collect all sales events across all lots
    final allSalesList = <Map<String, dynamic>>[];
    for (final lot in lots) {
      if (lot.sales.isNotEmpty) {
        for (final sale in lot.sales) {
          final profit = (sale.sellPricePerShare - lot.buyPricePerShare) * sale.sharesSold;
          allSalesList.add({
            'ticker': lot.ticker,
            'sellDate': sale.sellDate,
            'sharesSold': sale.sharesSold,
            'buyPrice': lot.buyPricePerShare,
            'sellPrice': sale.sellPricePerShare,
            'amountReceived': sale.amountReceived,
            'profit': profit,
          });
        }
      }
    }
    allSalesList.sort((a, b) => (b['sellDate'] as DateTime).compareTo(a['sellDate'] as DateTime));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader('Overall Portfolio & Financial Performance Report'),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.SizedBox(height: 12),
          // Executive Summary Banner
          _buildExecutiveSummaryBanner(summary, lots.length),
          pw.SizedBox(height: 20),

          // Visual Breakdown Section
          if (stockSummaries.isNotEmpty) ...[
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Portfolio Stock Allocation Pie Chart
                pw.Expanded(
                  flex: 1,
                  child: _buildAllocationPieChart(stockSummaries),
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
                'Rs ${AppCurrencyFormatter.format(s.avgBuyPrice)}',
                'Rs ${AppCurrencyFormatter.format(s.amountInvestedOpen)}',
                '${isProfit ? "+" : "-"}Rs ${AppCurrencyFormatter.format(s.realizedPL.abs())}',
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
                  'Rs ${AppCurrencyFormatter.format(sale['buyPrice'])}',
                  'Rs ${AppCurrencyFormatter.format(sale['sellPrice'])}',
                  'Rs ${AppCurrencyFormatter.format(sale['amountReceived'])}',
                  '${isProfit ? "+" : "-"}Rs ${AppCurrencyFormatter.format(profit.abs())}',
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 24),
          ],

          // Detailed Lots Table
          _buildSectionTitle('All Buy Lots & Transaction Records'),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8.5),
            headerDecoration: const pw.BoxDecoration(color: _headerBgColor),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _borderColor))),
            oddRowDecoration: const pw.BoxDecoration(color: _lightBgColor),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            headers: ['Ticker', 'Buy Date', 'Purchased', 'Buy Price', 'Remaining', 'Holding', 'Status', 'Realized P/L'],
            data: lots.map<List<dynamic>>((lot) {
              final isProfit = lot.realizedProfitLoss >= 0;
              return [
                lot.ticker,
                _dateFormat.format(lot.buyDate),
                _wholeFormat.format(lot.sharesPurchased),
                'Rs ${AppCurrencyFormatter.format(lot.buyPricePerShare)}',
                '${_wholeFormat.format(lot.sharesRemaining)} sh',
                '${lot.holdingDays}d',
                lot.status.name.toUpperCase(),
                '${isProfit ? "+" : "-"}Rs ${AppCurrencyFormatter.format(lot.realizedProfitLoss.abs())}',
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

  /// 2. Export Per-Stock Detailed Performance Report
  static Future<void> exportStockPdf({
    required String ticker,
    required List<Lot> stockLots,
    required StockSummary? summary,
  }) async {
    final pdf = pw.Document();

    final totalPurchasedShares = stockLots.fold<int>(0, (sum, l) => sum + l.sharesPurchased);
    final totalInvested = stockLots.fold<double>(0.0, (sum, l) => sum + l.amountInvested);
    final totalRealizedPL = stockLots.fold<double>(0.0, (sum, l) => sum + l.realizedProfitLoss);

    final allSales = <Map<String, dynamic>>[];
    for (final lot in stockLots) {
      if (lot.sales.isNotEmpty) {
        for (final sale in lot.sales) {
          final profit = (sale.sellPricePerShare - lot.buyPricePerShare) * sale.sharesSold;
          allSales.add({
            'lotId': lot.id,
            'sellDate': sale.sellDate,
            'sharesSold': sale.sharesSold,
            'buyPrice': lot.buyPricePerShare,
            'sellPrice': sale.sellPricePerShare,
            'amountReceived': sale.amountReceived,
            'profit': profit,
          });
        }
      }
    }
    allSales.sort((a, b) => (b['sellDate'] as DateTime).compareTo(a['sellDate'] as DateTime));
    final totalSalesReceived = allSales.fold<double>(0.0, (sum, s) => sum + (s['amountReceived'] as double));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader('$ticker Stock Performance & Trades Audit'),
        footer: (context) => _buildPdfFooter(context),
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
                pw.Text('$ticker EXECUTIVE METRICS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricItem('Total Shares Bought', _wholeFormat.format(totalPurchasedShares)),
                    _buildMetricItem('Total Capital Invested', 'Rs ${AppCurrencyFormatter.format(totalInvested)}'),
                    _buildMetricItem('Shares Remaining', summary != null ? _wholeFormat.format(summary.sharesHeld) : '0'),
                    _buildMetricItem('Total Sales Received', 'Rs ${AppCurrencyFormatter.format(totalSalesReceived)}'),
                    _buildMetricItem(
                      'Realized Profit/Loss',
                      '${totalRealizedPL >= 0 ? "+" : "-"}Rs ${AppCurrencyFormatter.format(totalRealizedPL.abs())}',
                      color: totalRealizedPL >= 0 ? _greenColor : _redColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Lots Breakdown Table
          _buildSectionTitle('Lots Purchase History for $ticker'),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: _headerBgColor),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _borderColor))),
            oddRowDecoration: const pw.BoxDecoration(color: _lightBgColor),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            headers: ['Buy Date', 'Purchased', 'Buy Price', 'Remaining', 'Holding Period', 'Status', 'Realized P/L'],
            data: stockLots.map<List<dynamic>>((lot) {
              final isProfit = lot.realizedProfitLoss >= 0;
              return [
                _dateFormat.format(lot.buyDate),
                _wholeFormat.format(lot.sharesPurchased),
                'Rs ${AppCurrencyFormatter.format(lot.buyPricePerShare)}',
                _wholeFormat.format(lot.sharesRemaining),
                '${lot.holdingDays} days',
                lot.status.name.toUpperCase(),
                '${isProfit ? "+" : "-"}Rs ${AppCurrencyFormatter.format(lot.realizedProfitLoss.abs())}',
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 24),

          // Detailed Sale Events Audit Table
          _buildSectionTitle('Sale Events Audit for $ticker (Sale Price & Date History)'),
          pw.SizedBox(height: 8),
          if (allSales.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(color: _lightBgColor, borderRadius: pw.BorderRadius.circular(8)),
              child: pw.Text('No sale events recorded for $ticker yet.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            )
          else
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8.5),
              headerDecoration: const pw.BoxDecoration(color: _primaryColor),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _borderColor))),
              oddRowDecoration: const pw.BoxDecoration(color: _lightBgColor),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              headers: ['Sell Date', 'Shares Sold', 'Buy Price / Sh', 'Sell Price / Sh', 'Amount Received', 'Realized P/L'],
              data: allSales.map<List<dynamic>>((sale) {
                final double profit = sale['profit'] as double;
                final isProfit = profit >= 0;
                return [
                  _dateFormat.format(sale['sellDate'] as DateTime),
                  _wholeFormat.format(sale['sharesSold']),
                  'Rs ${AppCurrencyFormatter.format(sale['buyPrice'])}',
                  'Rs ${AppCurrencyFormatter.format(sale['sellPrice'])}',
                  'Rs ${AppCurrencyFormatter.format(sale['amountReceived'])}',
                  '${isProfit ? "+" : "-"}Rs ${AppCurrencyFormatter.format(profit.abs())}',
                ];
              }).toList(),
            ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${ticker}_Stock_Report.pdf',
    );
  }

  /// 3. Export Per-Lot Detailed Audit Report
  static Future<void> exportLotPdf(Lot lot) async {
    final pdf = pw.Document();
    final isProfit = lot.realizedProfitLoss >= 0;

    final salesList = lot.sales;
    final totalAmountReceived = salesList.fold<double>(0.0, (sum, s) => sum + s.amountReceived);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildPdfHeader('${lot.ticker} Lot Audit Report'),
            pw.SizedBox(height: 16),

            // Lot Purchase Card
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
                        '${lot.ticker} LOT AUDIT SUMMARY',
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _accentColor),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: _primaryColor,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Text(
                          lot.status.name.toUpperCase(),
                          style: const pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricItem('Buy Date', _dateFormat.format(lot.buyDate)),
                      _buildMetricItem('Shares Purchased', _wholeFormat.format(lot.sharesPurchased)),
                      _buildMetricItem('Buy Price / Share', 'Rs ${AppCurrencyFormatter.format(lot.buyPricePerShare)}'),
                      _buildMetricItem('Total Capital Invested', 'Rs ${AppCurrencyFormatter.format(lot.amountInvested)}'),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricItem('Holding Period', '${lot.holdingDays} Days'),
                      _buildMetricItem('Remaining Shares', '${_wholeFormat.format(lot.sharesRemaining)} sh'),
                      _buildMetricItem('Total Sales Received', 'Rs ${AppCurrencyFormatter.format(totalAmountReceived)}'),
                      _buildMetricItem(
                        'Realized Profit / Loss',
                        '${isProfit ? "+" : "-"}Rs ${AppCurrencyFormatter.format(lot.realizedProfitLoss.abs())}',
                        color: isProfit ? _greenColor : _redColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 24),
            _buildSectionTitle('Sales Audit Log (Sale Price & Date Details)'),
            pw.SizedBox(height: 8),

            if (salesList.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(color: _lightBgColor, borderRadius: pw.BorderRadius.circular(8)),
                child: pw.Text('No sales recorded for this lot yet.', style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9)),
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
                headers: ['Sell Date', 'Shares Sold', 'Buy Price / Share', 'Sell Price / Share', 'Amount Received', 'Realized P/L'],
                data: salesList.map<List<dynamic>>((sale) {
                  final saleProfit = (sale.sellPricePerShare - lot.buyPricePerShare) * sale.sharesSold;
                  final saleIsProfit = saleProfit >= 0;
                  return [
                    _dateFormat.format(sale.sellDate),
                    _wholeFormat.format(sale.sharesSold),
                    'Rs ${AppCurrencyFormatter.format(lot.buyPricePerShare)}',
                    'Rs ${AppCurrencyFormatter.format(sale.sellPricePerShare)}',
                    'Rs ${AppCurrencyFormatter.format(sale.amountReceived)}',
                    '${saleIsProfit ? "+" : "-"}Rs ${AppCurrencyFormatter.format(saleProfit.abs())}',
                  ];
                }).toList(),
              ),

            pw.Spacer(),
            _buildPdfFooter(context),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${lot.ticker}_Lot_Report.pdf',
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
              _buildMetricItem('Total Capital Invested', 'Rs ${AppCurrencyFormatter.format(summary.totalInvested)}'),
              _buildMetricItem(
                'Realized Profit / Loss',
                '${summary.realizedPL >= 0 ? "+" : "-"}Rs ${AppCurrencyFormatter.format(summary.realizedPL.abs())}',
                color: summary.realizedPL >= 0 ? _greenColor : _redColor,
              ),
              _buildMetricItem('Active Investment Value', 'Rs ${AppCurrencyFormatter.format(summary.currentlyInvested)}'),
              _buildMetricItem('Total Lots Count', '${summary.openLots} Active / ${totalLotsCount - summary.openLots} Closed'),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAllocationPieChart(List<StockSummary> stockSummaries) {
    final totalInvested = stockSummaries.fold<double>(0, (sum, s) => sum + s.amountInvestedOpen);
    if (totalInvested <= 0) return pw.SizedBox();

    return pw.Container(
      height: 145,
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
                'Portfolio Stock Allocation',
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
                  'Rs ${AppCurrencyFormatter.format(totalInvested)}',
                  style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _primaryColor),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Expanded(
            child: pw.Row(
              children: [
                pw.Container(
                  width: 90,
                  height: 90,
                  child: pw.Chart(
                    grid: pw.PieGrid(),
                    datasets: List<pw.Dataset>.generate(stockSummaries.length, (i) {
                      final s = stockSummaries[i];
                      return pw.PieDataSet(
                        value: s.amountInvestedOpen,
                        color: _sliceColors[i % _sliceColors.length],
                        legend: s.ticker,
                        legendStyle: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      );
                    }),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: List<pw.Widget>.generate(
                      stockSummaries.length > 5 ? 5 : stockSummaries.length,
                      (i) {
                        final s = stockSummaries[i];
                        final pct = totalInvested > 0 ? (s.amountInvestedOpen / totalInvested * 100) : 0.0;
                        final sliceColor = _sliceColors[i % _sliceColors.length];
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Row(
                                children: [
                                  pw.Container(
                                    width: 7,
                                    height: 7,
                                    decoration: pw.BoxDecoration(
                                      color: sliceColor,
                                      borderRadius: pw.BorderRadius.circular(2),
                                    ),
                                  ),
                                  pw.SizedBox(width: 5),
                                  pw.Text(
                                    s.ticker,
                                    style: pw.TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: pw.FontWeight.bold,
                                      color: _accentColor,
                                    ),
                                  ),
                                ],
                              ),
                              pw.Row(
                                children: [
                                  pw.Text(
                                    'Rs ${AppCurrencyFormatter.format(s.amountInvestedOpen)}',
                                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                                  ),
                                  pw.SizedBox(width: 4),
                                  pw.Container(
                                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: pw.BoxDecoration(
                                      color: _lightBgColor,
                                      borderRadius: pw.BorderRadius.circular(3),
                                    ),
                                    child: pw.Text(
                                      '${pct.toStringAsFixed(1)}%',
                                      style: pw.TextStyle(
                                        fontSize: 7.5,
                                        fontWeight: pw.FontWeight.bold,
                                        color: _primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
                        '${isProfit ? "+" : "-"}Rs ${AppCurrencyFormatter.format(s.realizedPL.abs())}',
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

  static pw.Widget _buildPdfHeader(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(
              children: [
                pw.Container(
                  width: 10,
                  height: 10,
                  decoration: const pw.BoxDecoration(color: _primaryColor, shape: pw.BoxShape.circle),
                ),
                pw.SizedBox(width: 6),
                pw.Text(
                  'Stocks Investment Records',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _primaryColor),
                ),
              ],
            ),
            pw.Text(
              'Report Date: ${_dateFormat.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(title, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _accentColor)),
        pw.SizedBox(height: 8),
        pw.Divider(color: _borderColor, thickness: 1),
      ],
    );
  }

  static pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(color: _borderColor, thickness: 1),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Stocks Investment Records · Official Performance & Audit Report', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
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
