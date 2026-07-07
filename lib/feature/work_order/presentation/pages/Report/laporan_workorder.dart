import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:project_mobile_pdam/core/utils/app_snackbar.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/service/service_locator.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/laporan_workorder_model.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/laporan_workorder_cubit.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';

class LaporanWorkorderPage extends StatefulWidget {
  final Map<String, dynamic> payload;

  const LaporanWorkorderPage({super.key, required this.payload});

  @override
  State<LaporanWorkorderPage> createState() => _LaporanWorkorderPageState();
}

class _LaporanWorkorderPageState extends AppStatePage<LaporanWorkorderPage> {
  late LaporanWorkorderCubit _cubit;
  late String _printTime;
  LaporanReportModel? _report;

  @override
  void initState() {
    super.initState();
    _cubit = sl<LaporanWorkorderCubit>();
    _printTime = DateFormat(
      'dd MMMM yyyy, HH:mm',
      'id_ID',
    ).format(DateTime.now());
    final id = widget.payload['workorder_id'];
    if (id is int) _cubit.loadReport(id);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // PDF Layout Helpers (package:pdf — pw.*)
  // ─────────────────────────────────────────────

  /// Render section label with left accent bar.
  pw.Widget _sectionLabel(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 14, bottom: 8),
      child: pw.Row(
        children: [
          pw.Container(width: 3, height: 16, color: PdfColors.grey900),
          pw.SizedBox(width: 8),
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
              letterSpacing: 0.9,
            ),
          ),
        ],
      ),
    );
  }

  /// Two-column data grid, same style as the on-screen design.
  pw.Widget _dataGrid(List<_FieldItem> fields) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Table(
        columnWidths: const {
          0: pw.FlexColumnWidth(1),
          1: pw.FlexColumnWidth(1),
        },
        children: _buildTableRows(fields),
      ),
    );
  }

  List<pw.TableRow> _buildTableRows(List<_FieldItem> fields) {
    final rows = <pw.TableRow>[];

    for (int i = 0; i < fields.length; i += 2) {
      final isLastRow = (i + 2 >= fields.length);
      final hasRight = (i + 1 < fields.length);

      rows.add(
        pw.TableRow(
          children: [
            _tableCell(fields[i], isLeft: true, isLast: isLastRow),
            hasRight
                ? _tableCell(fields[i + 1], isLeft: false, isLast: isLastRow)
                : _tableCell(null, isLeft: false, isLast: isLastRow),
          ],
        ),
      );
    }

    // Handle full-width (odd leftover) field.
    if (fields.length.isOdd) {
      rows.removeLast();
      rows.add(
        pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              color: PdfColors.grey50,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    fields.last.label,
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    fields.last.value,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey900,
                    ),
                  ),
                ],
              ),
            ),
            pw.Container(color: PdfColors.grey50),
          ],
        ),
      );
    }

    return rows;
  }

  pw.Widget _tableCell(
    _FieldItem? item, {
    required bool isLeft,
    required bool isLast,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: pw.BoxDecoration(
        color: isLeft ? PdfColors.grey50 : PdfColors.white,
        border: pw.Border(
          right: isLeft
              ? const pw.BorderSide(color: PdfColors.grey300, width: 0.5)
              : pw.BorderSide.none,
          bottom: isLast
              ? pw.BorderSide.none
              : const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: item == null
          ? pw.SizedBox()
          : pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  item.label,
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  item.value,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey900,
                  ),
                ),
              ],
            ),
    );
  }

  /// Snapshot map/list/string → formatted multiline text block.
  pw.Widget _snapshotBlock(dynamic data) {
    String text = '-';
    if (data is Map) {
      text = data.entries.map((e) => '${e.key}: ${e.value}').join('\n');
    } else if (data is List) {
      text = data.map((e) => e.toString()).join('\n');
    } else if (data != null) {
      text = data.toString();
    }

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 12,
          color: PdfColors.grey900,
          lineSpacing: 8,
        ),
      ),
    );
  }

  /// Signature column box.
  pw.Widget _signBox(String role, String name) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            role.toUpperCase(),
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
              letterSpacing: 0.6,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            height: 40,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            name,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey900,
            ),
          ),
        ],
      ),
    );
  }

  String _dash(String? value) =>
      (value == null || value.trim().isEmpty) ? '-' : value.trim();

  String _fmtDate(DateTime? d) =>
      d == null ? '-' : DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(d);

  /// Daftar petugas dengan penanda PIC. Pakai [pw.Table] agar baris bisa
  /// terpaginasi lintas halaman pada [pw.MultiPage] saat petugas banyak.
  pw.Widget _memberList(List<LaporanReportMember> members) {
    if (members.isEmpty) return _snapshotBlock('-');
    return pw.Table(
      // Lebar kolom flex penuh; tanpa ini default IntrinsicColumnWidth mengukur
      // konten pada lebar tak terbatas → pw.Expanded di dalam cell error.
      columnWidths: const {0: pw.FlexColumnWidth()},
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        for (final m in members)
          pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            _dash(m.nama),
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey900,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'NIP: ${_dash(m.nip)}',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (m.isPic)
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green50,
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(color: PdfColors.green300),
                        ),
                        child: pw.Text(
                          'PIC',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  pw.Widget _header(String judulLaporan, String nomorLaporan) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'PDAM PERUMDA SURYA SEMBADA',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey900,
            letterSpacing: 0.4,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'Kota Surabaya  ·  Portal Work Order  ·  Sistem Manajemen Pekerjaan',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 6),
        pw.Container(width: double.infinity, height: 2, color: PdfColors.grey900),
        pw.SizedBox(height: 8),
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                judulLaporan,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                  letterSpacing: 1.2,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'No. Laporan: $nomorLaporan',
                style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColors.grey300, thickness: 0.5),
      ],
    );
  }

  /// Footer dokumen — muncul sekali di akhir konten (seperti desain awal).
  pw.Widget _footer() {
    return pw.Column(
      children: [
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColors.grey300, thickness: 0.5),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Dicetak: $_printTime WIB',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
            ),
            pw.Text(
              'Portal Work Order · PDAM Perumda Surya Sembada',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
            ),
          ],
        ),
      ],
    );
  }

  /// Build dokumen PDF multi-halaman A4.
  Future<Uint8List> _generatePdf(LaporanReportModel report) async {
    final doc = pw.Document();

    final nomorLaporan = report.nomorLaporan;
    final workorderId = report.workorderId?.toString() ?? '-';
    final judulLaporan = report.isLembur
        ? 'LAPORAN SELESAI WORK ORDER LEMBUR'
        : 'LAPORAN SELESAI WORK ORDER';
    final tanggal = DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now());
    final waktu = "${DateFormat('HH:mm', 'id_ID').format(DateTime.now())} WIB";
    final namaPic = _dash(report.pic?.nama);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        build: (context) => [
          _header(judulLaporan, nomorLaporan),

          _sectionLabel('Identitas Dokumen'),
          _dataGrid([
            _FieldItem('Work Order ID', workorderId),
            _FieldItem('Kode Pengaduan', _dash(report.kodePengaduan)),
            _FieldItem('Tanggal Laporan', tanggal),
            _FieldItem('Status', _dash(report.status)),
            _FieldItem('Waktu Submit', waktu),
          ]),

          _sectionLabel('Lokasi & Waktu Pengerjaan'),
          _dataGrid([
            _FieldItem('Tanggal Mulai', _fmtDate(report.tanggalMulai)),
            _FieldItem('Tanggal Selesai', _fmtDate(report.tanggalSelesai)),
            _FieldItem('Lokasi', _dash(report.lokasi)),
          ]),

          _sectionLabel('Data Hasil Pekerjaan'),
          _snapshotBlock(_dash(report.hasilAkhir)),

          _sectionLabel('Penanggung Jawab & Petugas'),
          _dataGrid([
            _FieldItem('SPV (Penanggung Jawab)', _dash(report.spvNama)),
            _FieldItem('NIP SPV', _dash(report.spvNip)),
          ]),
          pw.SizedBox(height: 8),
          _memberList(report.members),

          _sectionLabel('Catatan SPV'),
          _snapshotBlock(_dash(report.catatanSpv)),

          _sectionLabel('Tanda Tangan'),
          pw.SizedBox(height: 4),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _signBox('Petugas Pelaksana', namaPic)),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _signBox('Manager EPB', '( ________________ )'),
              ),
            ],
          ),

          _footer(),
        ],
      ),
    );

    return doc.save();
  }

  Future<void> _exportPdf(BuildContext context, LaporanReportModel report) async {
    try {
      AppSnackbar.showInfo('Sedang membuat PDF...');

      final bytes = await _generatePdf(report);

      final outputDirectory = await getApplicationDocumentsDirectory();
      final file = File(
        '${outputDirectory.path}/Laporan_WO_${widget.payload['workorder_id'] ?? 'unknown'}.pdf',
      );
      await file.writeAsBytes(bytes);

      if (!context.mounted) return;

      // Tampilkan pilihan: Buka atau Bagikan
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'PDF Berhasil Dibuat',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pilih tindakan:',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.open_in_new, color: Colors.blueAccent),
                title: const Text('Buka PDF'),
                onTap: () async {
                  Navigator.pop(context);
                  await OpenFilex.open(file.path);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.green),
                title: const Text('Bagikan PDF'),
                onTap: () async {
                  Navigator.pop(context);
                  await SharePlus.instance.share(
                    ShareParams(
                      files: [XFile(file.path)],
                      text:
                          'Laporan Work Order - PDAM Perumda Surya Sembada',
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.showError('Gagal membuat PDF: $e');
      }
    }
  }

  // ─────────────────────────────────────────────
  // Build Page
  // ─────────────────────────────────────────────

  @override
  Widget buildPage(BuildContext context) {
    final isSpv = AuthStorage.getJabatanKodeSync() == 'SPV';

    return BlocProvider(
      create: (_) => _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Laporan Work Order'),
          actions: [
            if (isSpv && _report != null)
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Export PDF',
                onPressed: () => _exportPdf(context, _report!),
              ),
          ],
        ),
        body: BlocConsumer<LaporanWorkorderCubit, LaporanWorkorderState>(
          listener: (context, state) {
            if (state is LaporanReportLoaded) {
              setState(() => _report = state.report);
            } else if (state is LaporanReportError) {
              AppSnackbar.showError(state.message);
            }
          },
          builder: (context, state) {
            if (state is LaporanReportError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        final id = widget.payload['workorder_id'];
                        if (id is int) _cubit.loadReport(id);
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              );
            }

            final report = _report;
            if (report == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return PdfPreview(
              build: (format) => _generatePdf(report),
              useActions: false,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              pdfFileName:
                  'Laporan_WO_${widget.payload['workorder_id'] ?? 'unknown'}.pdf',
            );
          },
        ),
      ),
    );
  }
}

class _FieldItem {
  final String label;
  final String value;

  _FieldItem(this.label, this.value);
}
