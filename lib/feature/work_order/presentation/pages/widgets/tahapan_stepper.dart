import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/config/theme/app_color.dart';
import 'package:project_mobile_pdam/core/constants/tahapan_labels.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/work_order_progress_entity.dart';

/// Stepper "Tahapan Pekerjaan" 4 langkah dengan garis penghubung yang konsisten.
///
/// Tiap langkah menempati lebar yang sama (`Expanded`) dan garis penghubung
/// dipecah jadi dua bagian (kiri & kanan lingkaran). Dengan begitu setiap
/// lingkaran berada tepat di tengah kolomnya sehingga jarak antar lingkaran dan
/// panjang garisnya seragam.
class TahapanStepper extends StatelessWidget {
  final WorkOrderEntity? workOrder;
  final List<WorkOrderProgressEntity> progresses;

  const TahapanStepper({
    super.key,
    required this.workOrder,
    required this.progresses,
  });

  int _computeTahapan() {
    if (workOrder?.tahapanTertinggi != null) {
      return workOrder!.tahapanTertinggi!;
    }
    int computed = 0;
    for (final p in progresses) {
      if (p.tahapan != null && p.tahapan! > computed) {
        computed = p.tahapan!;
      }
    }
    return computed;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).extension<AppColor>()!;
    final int computedTahapan = _computeTahapan();
    final labels = tahapanLabelsFor(workOrder?.workOrderType?.name);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.foreground[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tahapan Pekerjaan',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(4, (index) {
              final stepTahapan = index + 1;
              final isCompleted = computedTahapan >= stepTahapan;
              final isCurrent =
                  computedTahapan + 1 == stepTahapan && computedTahapan != 4;

              final Color circleColor = isCompleted
                  ? color.status[2]! // hijau
                  : isCurrent
                  ? color.primary[500]! // biru primary
                  : color.foreground[300]!; // abu-abu

              // Garis hijau bila tahap yang dihubungkannya sudah tercapai.
              // Garis kiri & kanan dari sambungan yang sama selalu sewarna.
              final Color leftLineColor = computedTahapan >= index
                  ? color.status[2]!
                  : color.foreground[200]!;
              final Color rightLineColor = isCompleted
                  ? color.status[2]!
                  : color.foreground[200]!;

              return Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: index == 0
                              ? const SizedBox(height: 2)
                              : Container(height: 2, color: leftLineColor),
                        ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? circleColor
                                : Colors.transparent,
                            border: Border.all(color: circleColor, width: 2),
                            shape: BoxShape.circle,
                          ),
                          child: isCompleted
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : isCurrent
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: circleColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        Expanded(
                          child: index == 3
                              ? const SizedBox(height: 2)
                              : Container(height: 2, color: rightLineColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      labels[index],
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontWeight: isCurrent || isCompleted
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isCurrent || isCompleted
                            ? color.foreground[900]
                            : color.foreground[500],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
