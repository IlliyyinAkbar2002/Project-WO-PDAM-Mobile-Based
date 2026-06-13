import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
        ...progressByMember.members.map((member) {
          return MemberProgressCard(
            member: member,
            isExpanded: false,
            status: status,
            kategoriForm: kategoriForm,
            lngLat: lngLat,
            locationName: locationName,
            radiusMeter: radiusMeter,
            workOrderTypeName: workOrderTypeName,
            workOrderTypeId: workOrderTypeId,
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}
