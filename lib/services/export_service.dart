// lib/services/export_service.dart
// RF-10: Export data as PDF

import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

// Conditional imports for platform-specific functionality
import 'export_service_stub.dart'
    if (dart.library.io) 'export_service_io.dart'
    if (dart.library.html) 'export_service_web.dart' as platform;

import '../repositories/repository_interfaces.dart';
import '../repositories/health_repository.dart';
import '../repositories/plano_repository.dart';
import '../models/models.dart';
import '../models/event_record.dart';
import 'charts_service.dart';

/// PDF Export Service (RF-10)
/// Supports both web (browser download) and mobile (file system)
class ExportService {
  final IHealthRepository _healthRepo;
  final IPlanoRepository _planoRepo;
  final ChartsService _chartsService;

  ExportService({
    IHealthRepository? healthRepo,
    IPlanoRepository? planoRepo,
    ChartsService? chartsService,
  })  : _healthRepo = healthRepo ?? HealthRepository(),
        _planoRepo = planoRepo ?? PlanoRepository(),
        _chartsService = chartsService ?? ChartsService();

  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _timeFormat = DateFormat('HH:mm');
  final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  /// Export user data to PDF
  /// On web: triggers browser download
  /// On mobile: returns file path and can share
  Future<String> exportToPdf({
    required DateTime from,
    required DateTime to,
    required String userName,
  }) async {
    // Check freemium limits
    final canExport = await _planoRepo.canExport();
    if (!canExport) {
      throw Exception('Limite de exportações atingido. Faça upgrade para continuar.');
    }

    // Fetch all data
    final glucoseRecords = await _healthRepo.getGlucoseRecords(from: from, to: to);
    final insulinRecords = await _healthRepo.getInsulinRecords(from: from, to: to);
    final eventRecords = await _healthRepo.getEventRecords(from: from, to: to);
    final summary = await _chartsService.getPeriodSummary(from: from, to: to);
    final timeInRange = await _chartsService.getTimeInRange(from: from, to: to);

    // Build PDF
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(userName, from, to),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildSummarySection(summary, timeInRange),
          pw.SizedBox(height: 20),
          _buildGlucoseChart(glucoseRecords),
          pw.SizedBox(height: 20),
          _buildGlucoseSection(glucoseRecords),
          pw.SizedBox(height: 20),
          _buildInsulinSection(insulinRecords),
          pw.SizedBox(height: 20),
          _buildEventsSection(eventRecords),
        ],
      ),
    );

    // Generate PDF bytes
    final Uint8List pdfBytes = await pdf.save();
    final fileName = 'diabetter_${_dateFormat.format(from).replaceAll('/', '-')}_${_dateFormat.format(to).replaceAll('/', '-')}.pdf';

    // Use platform-specific save/download
    final result = await platform.savePdf(pdfBytes, fileName);

    // Increment export counter for freemium
    await _planoRepo.incrementExportCount();

    return result;
  }

  /// Share the exported PDF (mobile only, no-op on web)
  Future<void> sharePdf(String filePath) async {
    await platform.sharePdf(filePath);
  }

  // Private helper methods for PDF building

  pw.Widget _buildHeader(String userName, DateTime from, DateTime to) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Diabetter',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.Text(
                'Relatório de Acompanhamento',
                style: const pw.TextStyle(fontSize: 14),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Paciente: $userName'),
              pw.Text('Período: ${_dateFormat.format(from)} - ${_dateFormat.format(to)}'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Gerado por Diabetter em ${_dateTimeFormat.format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummarySection(PeriodSummary summary, TimeInRange tir) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Resumo do Período',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatBox('Glicemia Média', 
                summary.glucoseAverage?.toStringAsFixed(0) ?? '-', 'mg/dL'),
              _buildStatBox('Mínima', 
                summary.glucoseMin?.toStringAsFixed(0) ?? '-', 'mg/dL'),
              _buildStatBox('Máxima', 
                summary.glucoseMax?.toStringAsFixed(0) ?? '-', 'mg/dL'),
              _buildStatBox('Tempo no Alvo', 
                '${tir.inRangePercent.toStringAsFixed(0)}%', ''),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatBox('Registros Glicemia', '${summary.glucoseCount}', ''),
              _buildStatBox('Aplicações Insulina', '${summary.insulinCount}', ''),
              _buildStatBox('Total Insulina', 
                summary.insulinTotalUnits?.toStringAsFixed(1) ?? '0', 'un'),
              _buildStatBox('Eventos', '${summary.eventsCount}', ''),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStatBox(String label, String value, String unit) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        if (unit.isNotEmpty) pw.Text(unit, style: const pw.TextStyle(fontSize: 10)),
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  pw.Widget _buildGlucoseChart(List<GlucoseRecord> records) {
    if (records.isEmpty) {
      return pw.Container();
    }

    // Sort records by timestamp and limit to 15 for readability
    final sortedRecords = List<GlucoseRecord>.from(records)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final displayRecords = sortedRecords.length > 15 
        ? sortedRecords.sublist(sortedRecords.length - 15)
        : sortedRecords;

    // Chart dimensions
    const double chartWidth = 500;
    const double chartHeight = 180;
    const double leftPadding = 45;
    const double bottomPadding = 35;
    const double topPadding = 25;

    // Find min/max values for scaling
    final minValue = 40.0;
    final maxValue = displayRecords.map((r) => r.quantity).reduce((a, b) => a > b ? a : b).clamp(180.0, 400.0);
    final valueRange = maxValue - minValue;

    // Time range
    final startTime = displayRecords.first.timestamp;
    final endTime = displayRecords.last.timestamp;
    final timeRange = endTime.difference(startTime).inMinutes.toDouble();

    // Convert data points to coordinates
    List<PdfPoint> dataPoints = [];
    for (final record in displayRecords) {
      final xRatio = timeRange > 0 
          ? record.timestamp.difference(startTime).inMinutes / timeRange
          : 0.5;
      final yRatio = (record.quantity - minValue) / valueRange;
      
      final x = leftPadding + xRatio * (chartWidth - leftPadding - 10);
      final y = bottomPadding + yRatio * (chartHeight - bottomPadding - topPadding);
      dataPoints.add(PdfPoint(x, y));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Gráfico de Glicemia',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          height: chartHeight + 20,
          width: chartWidth,
          child: pw.Stack(
            children: [
              // Chart drawing
              pw.CustomPaint(
                size: PdfPoint(chartWidth, chartHeight),
                painter: (canvas, size) {
                  // Draw target range zone (70-180 mg/dL) - green
                  final y70 = bottomPadding + ((70 - minValue) / valueRange) * (chartHeight - bottomPadding - topPadding);
                  final y180 = bottomPadding + ((180 - minValue) / valueRange) * (chartHeight - bottomPadding - topPadding);
                  
                  canvas.drawRect(leftPadding, y70, chartWidth - leftPadding - 10, y180 - y70);
                  canvas.setFillColor(PdfColors.green100);
                  canvas.fillPath();

                  // Draw axes
                  canvas.setStrokeColor(PdfColors.grey600);
                  canvas.setLineWidth(1);
                  canvas.drawLine(leftPadding, bottomPadding, leftPadding, chartHeight - topPadding);
                  canvas.drawLine(leftPadding, bottomPadding, chartWidth - 10, bottomPadding);
                  canvas.strokePath();

                  // Draw reference lines
                  canvas.setStrokeColor(PdfColors.grey300);
                  canvas.setLineWidth(0.5);
                  canvas.drawLine(leftPadding, y70, chartWidth - 10, y70);
                  canvas.drawLine(leftPadding, y180, chartWidth - 10, y180);
                  canvas.strokePath();

                  // Draw data lines
                  if (dataPoints.length > 1) {
                    canvas.setStrokeColor(PdfColors.blue700);
                    canvas.setLineWidth(1.5);
                    for (int i = 0; i < dataPoints.length - 1; i++) {
                      canvas.drawLine(
                        dataPoints[i].x, dataPoints[i].y,
                        dataPoints[i + 1].x, dataPoints[i + 1].y,
                      );
                    }
                    canvas.strokePath();
                  }

                  // Draw data points
                  canvas.setFillColor(PdfColors.blue700);
                  for (final point in dataPoints) {
                    canvas.drawEllipse(point.x, point.y, 3, 3);
                    canvas.fillPath();
                  }
                },
              ),
              // Y-axis labels
              pw.Positioned(
                left: 0,
                bottom: bottomPadding + ((70 - minValue) / valueRange) * (chartHeight - bottomPadding - topPadding) - 5,
                child: pw.Text('70', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
              ),
              pw.Positioned(
                left: 0,
                bottom: bottomPadding + ((125 - minValue) / valueRange) * (chartHeight - bottomPadding - topPadding) - 5,
                child: pw.Text('125', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
              ),
              pw.Positioned(
                left: 0,
                bottom: bottomPadding + ((180 - minValue) / valueRange) * (chartHeight - bottomPadding - topPadding) - 5,
                child: pw.Text('180', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
              ),
              // Y-axis title
              pw.Positioned(
                left: 2,
                top: 5,
                child: pw.Text('mg/dL', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
              ),
              // Data point values
              ...List.generate(displayRecords.length, (i) {
                return pw.Positioned(
                  left: dataPoints[i].x - 8,
                  bottom: dataPoints[i].y + 5,
                  child: pw.Text(
                    displayRecords[i].quantity.toStringAsFixed(0),
                    style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
                  ),
                );
              }),
            ],
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(
              children: [
                pw.Container(width: 12, height: 12, color: PdfColors.green100),
                pw.SizedBox(width: 4),
                pw.Text('Alvo (70-180 mg/dL)', style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
            pw.Text(
              'Período: ${_dateFormat.format(startTime)} - ${_dateFormat.format(endTime)}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildGlucoseSection(List<GlucoseRecord> records) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Registros de Glicemia',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        if (records.isEmpty)
          pw.Text('Nenhum registro no período.')
        else
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellPadding: const pw.EdgeInsets.all(5),
            data: [
              ['Data', 'Hora', 'Valor (mg/dL)', 'Notas'],
              ...records.map((r) => [
                _dateFormat.format(r.timestamp),
                _timeFormat.format(r.timestamp),
                r.quantity.toStringAsFixed(0),
                r.notas ?? '',
              ]),
            ],
          ),
      ],
    );
  }

  pw.Widget _buildInsulinSection(List<InsulinRecord> records) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Registros de Insulina',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        if (records.isEmpty)
          pw.Text('Nenhum registro no período.')
        else
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellPadding: const pw.EdgeInsets.all(5),
            data: [
              ['Data', 'Hora', 'Dose (un)', 'Tipo', 'Local'],
              ...records.map((r) => [
                _dateFormat.format(r.timestamp),
                _timeFormat.format(r.timestamp),
                r.quantity.toStringAsFixed(1),
                r.type ?? '-',
                r.bodyPart ?? '-',
              ]),
            ],
          ),
      ],
    );
  }

  pw.Widget _buildEventsSection(List<EventRecord> records) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Eventos',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        if (records.isEmpty)
          pw.Text('Nenhum evento no período.')
        else
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellPadding: const pw.EdgeInsets.all(5),
            data: [
              ['Data', 'Hora', 'Tipo', 'Título', 'Descrição'],
              ...records.map((r) => [
                _dateFormat.format(r.horario),
                _timeFormat.format(r.horario),
                r.tipoEvento.displayName,
                r.titulo,
                r.descricao ?? '',
              ]),
            ],
          ),
      ],
    );
  }
}
