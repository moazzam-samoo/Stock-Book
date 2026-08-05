import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:stock_investment_tracker/domain/calculator/portfolio_calculator.dart';
import 'package:stock_investment_tracker/domain/entities/lot.dart';
import 'package:stock_investment_tracker/domain/entities/stock_summary.dart';
import 'package:stock_investment_tracker/domain/entities/portfolio_summary.dart';

class PdfReportService {
  static final NumberFormat _currencyFormat = NumberFormat('#,##0.00');
  static final NumberFormat _wholeFormat = NumberFormat('#,##0');
  static final DateFormat _dateFormat = DateFormat('MMM d, y');

  // Colors for PDF
  static const PdfColor _primaryColor = PdfColor.fromInt(0xFF584BF6);
  static const PdfColor _darkHeaderColor = PdfColor.fromInt(0xFF1E1E2D);
  static const PdfColor _greenColor = PdfColor.fromInt(0xFF10B981);
  static const PdfColor _redColor = PdfColor.fromInt(0xFFEF4444);
  static const PdfColor _lightBgColor = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor _borderColor = PdfColor.fromInt(0xFFE2E8F0);

  /// 1. Export Overall Portfolio Report
  static Future<void> exportOverallPortfolioPdf({
    required List<Lot> lots,
    required PortfolioSummary summary,
    required List<StockSummary> stockSummaries,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader('Overall Portfolio Investment Report'),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.SizedBox(height: 16),
          // Executive Summary Cards
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
                pw.Text(
                  'EXECUTIVE PORTFOLIO SUMMARY',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricItem(
                      'Total Amount Invested',
                      'Rs ${_currencyFormat.format(summary.totalInvested)}',
                    ),
                    _buildMetricItem(
                      'Realized Profit / Loss',
                      '${summary.realizedPL >= 0 ? "+" : "-"}Rs ${_currencyFormat.format(summary.realizedPL.abs())}',
                      color: summary.realizedPL >= 0 ? _greenColor : _redColor,
                    ),
                    _buildMetricItem(
                      'Remaining Investment',
                      'Rs ${_currencyFormat.format(summary.currentlyInvested)}',
                    ),
                    _buildMetricItem(
                      'Total Lots / Holdings',
                      '${summary.openLots} Active (${lots.length - summary.openLots} Closed)',
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Stock Aggregates Section
          pw.Text(
            'Stock Performance Summary',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _darkHeaderColor),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: _primaryColor),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _borderColor))),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            headers: ['Ticker', 'Shares Remaining', 'Avg Buy Price', 'Realized P/L', 'Status'],
            data: stockSummaries.map<List<dynamic>>((s) {
              final isProfit = s.realizedPL >= 0;
              return [
                s.ticker,
                _wholeFormat.format(s.sharesHeld),
                'Rs ${_currencyFormat.format(s.avgBuyPrice)}',
                '${isProfit ? "+" : "-"}Rs ${_currencyFormat.format(s.realizedPL.abs())}',
                s.status.name.toUpperCase(),
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 24),

          // Detailed Lots Table
          pw.Text(
            'All Lot Transactions & Records',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _darkHeaderColor),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: _darkHeaderColor),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _borderColor))),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            headers: ['Ticker', 'Buy Date', 'Shares', 'Buy Price', 'Remaining', 'Holding', 'Status', 'Realized P/L'],
            data: lots.map<List<dynamic>>((lot) {
              final isProfit = lot.realizedProfitLoss >= 0;
              return [
                lot.ticker,
                _dateFormat.format(lot.buyDate),
                _wholeFormat.format(lot.sharesPurchased),
                'Rs ${_currencyFormat.format(lot.buyPricePerShare)}',
                '${_wholeFormat.format(lot.sharesRemaining)} sh',
                '${lot.holdingDays}d',
                lot.status.name.toUpperCase(),
                '${isProfit ? "+" : "-"}Rs ${_currencyFormat.format(lot.realizedProfitLoss.abs())}',
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

  /// 2. Export Per-Stock Report
  static Future<void> exportStockPdf({
    required String ticker,
    required List<Lot> stockLots,
    required StockSummary? summary,
  }) async {
    final pdf = pw.Document();

    final totalPurchasedShares = stockLots.fold<int>(0, (sum, l) => sum + l.sharesPurchased);
    final totalInvested = stockLots.fold<double>(0.0, (sum, l) => sum + l.amountInvested);
    final totalRealizedPL = stockLots.fold<double>(0.0, (sum, l) => sum + l.realizedProfitLoss);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader('$ticker Stock Performance Report'),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.SizedBox(height: 16),
          // Stock Overview Card
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
                _buildMetricItem('Total Shares Bought', _wholeFormat.format(totalPurchasedShares)),
                _buildMetricItem('Total Invested', 'Rs ${_currencyFormat.format(totalInvested)}'),
                _buildMetricItem(
                  'Shares Remaining',
                  summary != null ? _wholeFormat.format(summary.sharesHeld) : '0',
                ),
                _buildMetricItem(
                  'Realized P/L',
                  '${totalRealizedPL >= 0 ? "+" : "-"}Rs ${_currencyFormat.format(totalRealizedPL.abs())}',
                  color: totalRealizedPL >= 0 ? _greenColor : _redColor,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Stock Lots Table
          pw.Text(
            'Lots History for $ticker',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _darkHeaderColor),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: _primaryColor),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _borderColor))),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            headers: ['Buy Date', 'Purchased', 'Buy Price', 'Remaining', 'Holding Period', 'Status', 'Realized P/L'],
            data: stockLots.map<List<dynamic>>((lot) {
              final isProfit = lot.realizedProfitLoss >= 0;
              return [
                _dateFormat.format(lot.buyDate),
                _wholeFormat.format(lot.sharesPurchased),
                'Rs ${_currencyFormat.format(lot.buyPricePerShare)}',
                _wholeFormat.format(lot.sharesRemaining),
                '${lot.holdingDays} days',
                lot.status.name.toUpperCase(),
                '${isProfit ? "+" : "-"}Rs ${_currencyFormat.format(lot.realizedProfitLoss.abs())}',
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 24),

          // Sale Events Log
          pw.Text(
            'Sale Events Log for $ticker',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _darkHeaderColor),
          ),
          pw.SizedBox(height: 8),
          ...stockLots.expand((lot) {
            if (lot.sales == null || lot.sales!.isEmpty) return <pw.Widget>[];
            return lot.sales!.map((sale) {
              final saleProfit = (sale.sellPricePerShare - lot.buyPricePerShare) * sale.sharesSold;
              final isProfit = saleProfit >= 0;
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: _borderColor),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Sold ${_wholeFormat.format(sale.sharesSold)} sh @ Rs ${_currencyFormat.format(sale.sellPricePerShare)}'),
                    pw.Text(_dateFormat.format(sale.sellDate), style: const pw.TextStyle(color: PdfColors.grey700)),
                    pw.Text(
                      '${isProfit ? "+" : "-"}Rs ${_currencyFormat.format(saleProfit.abs())}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: isProfit ? _greenColor : _redColor),
                    ),
                  ],
                ),
              );
            });
          }).toList(),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${ticker}_Stock_Report.pdf',
    );
  }

  /// 3. Export Per-Lot Report
  static Future<void> exportLotPdf(Lot lot) async {
    final pdf = pw.Document();
    final isProfit = lot.realizedProfitLoss >= 0;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildPdfHeader('Lot #${lot.id} Record Report'),
            pw.SizedBox(height: 20),

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
                        '${lot.ticker} LOT DETAILS',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _primaryColor),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: _primaryColor,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Text(
                          lot.status.name.toUpperCase(),
                          style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
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
                      _buildMetricItem('Buy Price / Share', 'Rs ${_currencyFormat.format(lot.buyPricePerShare)}'),
                      _buildMetricItem('Amount Invested', 'Rs ${_currencyFormat.format(lot.amountInvested)}'),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricItem('Holding Period', '${lot.holdingDays} Days'),
                      _buildMetricItem('Remaining Shares', '${_wholeFormat.format(lot.sharesRemaining)} sh'),
                      _buildMetricItem(
                        'Realized Profit / Loss',
                        '${isProfit ? "+" : "-"}Rs ${_currencyFormat.format(lot.realizedProfitLoss.abs())}',
                        color: isProfit ? _greenColor : _redColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 24),
            pw.Text(
              'Sales Log for Lot #${lot.id}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _darkHeaderColor),
            ),
            pw.SizedBox(height: 8),

            if (lot.sales == null || lot.sales!.isEmpty)
              pw.Text('No sales recorded for this lot yet.', style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10))
            else
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: _darkHeaderColor),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _borderColor))),
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                headers: ['Sell Date', 'Shares Sold', 'Sell Price / Share', 'Amount Received', 'Realized P/L'],
                data: lot.sales!.map<List<dynamic>>((sale) {
                  final saleProfit = (sale.sellPricePerShare - lot.buyPricePerShare) * sale.sharesSold;
                  final saleIsProfit = saleProfit >= 0;
                  return [
                    _dateFormat.format(sale.sellDate),
                    _wholeFormat.format(sale.sharesSold),
                    'Rs ${_currencyFormat.format(sale.sellPricePerShare)}',
                    'Rs ${_currencyFormat.format(sale.amountReceived)}',
                    '${saleIsProfit ? "+" : "-"}Rs ${_currencyFormat.format(saleProfit.abs())}',
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
      name: '${lot.ticker}_Lot_${lot.id}_Report.pdf',
    );
  }

  // --- Helper Widgets ---

  static pw.Widget _buildPdfHeader(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Stocks Investment Records',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _primaryColor),
            ),
            pw.Text(
              'Generated: ${_dateFormat.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _darkHeaderColor)),
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
            pw.Text('Stocks Investment Records · Official Financial Report', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
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
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: color ?? _darkHeaderColor),
        ),
      ],
    );
  }
}
