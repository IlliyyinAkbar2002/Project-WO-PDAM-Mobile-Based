import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/member_progress_entity.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_reguler/assignee_page/work_order_report_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_lembur/work_order_report_page_lembur.dart';

/// Widget untuk menampilkan progress individual satu anggota tim.
///
/// Digunakan oleh SPV untuk melihat kontribusi masing-masing anggota.
class MemberProgressCard extends StatefulWidget {
  final MemberProgressEntity member;
  final bool isExpanded;
  final VoidCallback? onTap;

  // Fields for detail navigation
  final int? status;
  final String? kategoriForm;
  final LatLng? lngLat;
  final String? locationName;
  final int radiusMeter;
  final String? workOrderTypeName;
  final int? workOrderTypeId;

  /// Saat `true`, tap progress membuka halaman laporan lembur
  /// (`WorkOrderReportPageLembur`) alih-alih halaman reguler.
  final bool isOvertime;

  const MemberProgressCard({
    super.key,
    required this.member,
    this.isExpanded = false,
    this.onTap,
    this.status,
    this.kategoriForm,
    this.lngLat,
    this.locationName,
    this.radiusMeter = 100,
    this.workOrderTypeName,
    this.workOrderTypeId,
    this.isOvertime = false,
  });

  @override
  State<MemberProgressCard> createState() => _MemberProgressCardState();
}

class _MemberProgressCardState extends State<MemberProgressCard> {
  bool _isExpanded = false;
  bool _showAllProgress = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
          widget.onTap?.call();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Nama, Jabatan, PIC Badge
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.member.nama,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.member.isPic) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'PIC',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.member.jabatan,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (widget.member.nip != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'NIP: ${widget.member.nip}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Statistics Grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total Laporan',
                      '${widget.member.progressList.length}',
                      Icons.assignment,
                      Colors.blue,
                    ),
                  ),
                  if (widget.member.progressList.isNotEmpty)
                    Expanded(
                      // progressList dari backend terurut kronologis
                      // (lama → baru), sama seperti urutan "Riwayat Progress"
                      // di bawah. Jadi elemen TERAKHIR = status terkini,
                      // bukan elemen pertama.
                      child: _buildStatItem(
                        'Status Terakhir',
                        widget.member.progressList.last.progressType ??
                            'Progress',
                        widget.member.progressList.last.isSelesai
                            ? Icons.check_circle
                            : Icons.sync,
                        widget.member.progressList.last.isSelesai
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                ],
              ),

              // Expanded Section: Progress List
              if (_isExpanded) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Riwayat Progress (${widget.member.progressList.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.member.progressList.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Belum ada progress',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ),
                  )
                else
                  ...(_showAllProgress
                          ? widget.member.progressList
                          : widget.member.progressList.take(5))
                      .map((progress) {
                        return _buildProgressItem(progress);
                      }),
                if (widget.member.progressList.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Center(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _showAllProgress = !_showAllProgress;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Text(
                            _showAllProgress
                                ? 'Tampilkan lebih sedikit'
                                : '+ ${widget.member.progressList.length - 5} progress lainnya',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: value.length > 3 ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressItem(dynamic progress) {
    final submitTime = progress.submitTime;
    final formattedTime = submitTime != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(submitTime)
        : '-';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => widget.isOvertime
                    ? WorkOrderReportPageLembur(
                        mode: progress.progressType ?? '-',
                        status: widget.status,
                        isAssignee: false,
                        progressId: progress.id,
                        workOrderId: progress.workOrderId,
                        workOrderTypeId: widget.workOrderTypeId,
                        lngLat: widget.lngLat,
                        locationName: widget.locationName,
                        radiusMeter: widget.radiusMeter,
                        kategoriForm: widget.kategoriForm,
                        initialDescription: progress.description,
                      )
                    : WorkOrderReportPage(
                        mode: progress.progressType ?? '-',
                        status: widget.status,
                        isAssignee: false,
                        progressId: progress.id,
                        workOrderId: progress.workOrderId,
                        workOrderTypeId: widget.workOrderTypeId,
                        lngLat: widget.lngLat,
                        locationName: widget.locationName,
                        radiusMeter: widget.radiusMeter,
                        kategoriForm: widget.kategoriForm,
                        workOrderTypeName: widget.workOrderTypeName,
                        initialDescription: progress.description,
                      ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getProgressTypeColor(progress.tipeProgressId),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progress.progressType ?? 'Progress',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedTime,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (progress.documentation != null &&
                    progress.documentation!.isNotEmpty) ...[
                  Icon(Icons.photo_camera, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 8),
                ],
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getProgressTypeColor(int? tipeProgressId) {
    switch (tipeProgressId) {
      case 1: // Mulai
        return Colors.blue;
      case 3: // Selesai
        return Colors.green;
      default: // Progress
        return Colors.orange;
    }
  }
}
