import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/member_progress_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/progress_by_member_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/widgets/member_progress_card.dart';

class IndividualProgressSection extends StatelessWidget {
  final ProgressByMemberEntity progressByMember;
  final int? status;
  final String? kategoriForm;
  final LatLng? lngLat;
  final String? locationName;
  final int radiusMeter;
  final String? workOrderTypeName;
  final int? workOrderTypeId;
  final bool isOvertime;

  const IndividualProgressSection({
    super.key,
    required this.progressByMember,
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
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (progressByMember.members.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Progress Anggota Tim", style: textTheme.displayMedium),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${progressByMember.members.length} Anggota',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        ..._buildBody(context),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Membangun konten utama. Jika ada PIC, anggota dikelompokkan: PIC sebagai
  /// pemimpin di atas, lalu staff lapangan ter-nesting di bawahnya. Jika tidak
  /// ada PIC (fallback defensif), tampilkan daftar datar seperti sebelumnya.
  List<Widget> _buildBody(BuildContext context) {
    final pic = progressByMember.pic;

    if (pic == null) {
      return [
        ...progressByMember.members
            .map((member) => _buildCard(member, isLeader: false)),
        // Tanpa PIC: tampilkan total laporan tim saja (tanpa Status Terakhir).
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _buildStatItem(
            'Total Laporan Tim',
            '${progressByMember.totalLaporanTim}',
            Icons.assignment,
            Colors.blue,
          ),
        ),
      ];
    }

    final anggota =
        progressByMember.members.where((m) => !m.isPic).toList();

    // Satu container luar membungkus seluruh tim: leader (PIC) dirender rata
    // sebagai konten di atas, lalu anggota lapangan sebagai kartu di dalamnya.
    return [
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel(icon: Icons.groups_outlined, text: 'Tim Lapangan'),
            const SizedBox(height: 8),
            // Leader (PIC) — flat, tanpa kartu sendiri.
            _buildCard(pic, isLeader: true, flat: true),
            if (anggota.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _buildSectionLabel(
                text: 'Anggota Lapangan · ${anggota.length} orang',
              ),
              const SizedBox(height: 4),
              ...anggota.map(
                (member) => _buildCard(
                  member,
                  isLeader: false,
                  margin: const EdgeInsets.only(bottom: 8),
                ),
              ),
            ],
            // Footer ringkasan tim: total laporan seluruh anggota + status
            // terakhir milik PIC (PIC yang menjalankan tahapan).
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildTeamFooter(pic),
          ],
        ),
      ),
    ];
  }

  /// Footer ringkasan di dalam container "Tim Lapangan": total laporan tim
  /// (agregat seluruh anggota) dan status terakhir PIC.
  Widget _buildTeamFooter(MemberProgressEntity pic) {
    final lastProgress =
        pic.progressList.isNotEmpty ? pic.progressList.last : null;

    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            'Total Laporan Tim',
            '${progressByMember.totalLaporanTim}',
            Icons.assignment,
            Colors.blue,
          ),
        ),
        if (lastProgress != null)
          Expanded(
            child: _buildStatItem(
              'Status Terakhir',
              lastProgress.progressType ?? 'Progress',
              lastProgress.isSelesai ? Icons.check_circle : Icons.sync,
              lastProgress.isSelesai ? Colors.green : Colors.orange,
            ),
          ),
      ],
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

  Widget _buildSectionLabel({IconData? icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 6),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(
    MemberProgressEntity member, {
    required bool isLeader,
    bool flat = false,
    EdgeInsetsGeometry? margin,
  }) {
    return MemberProgressCard(
      member: member,
      isExpanded: false,
      isLeader: isLeader,
      flat: flat,
      showAvatar: true,
      // Anggota dalam grup: margin diatur oleh pemanggil. Fallback (tanpa PIC)
      // memakai margin default kartu.
      margin: margin,
      status: status,
      kategoriForm: kategoriForm,
      lngLat: lngLat,
      locationName: locationName,
      radiusMeter: radiusMeter,
      workOrderTypeName: workOrderTypeName,
      workOrderTypeId: workOrderTypeId,
      isOvertime: isOvertime,
    );
  }
}
