import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final String id;
  final String type;
  final NotificationDataEntity data;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.data,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  NotificationEntity copyWith({
    String? id,
    String? type,
    NotificationDataEntity? data,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      data: data ?? this.data,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, type, data, readAt, createdAt];
}

enum NotificationKind {
  woCreated,
  woAssigned,
  woReadyForReview,
  materialReturnSubmitted,
  materialReturnVerified,
  woLemburApproved,
  unknown,
}

extension NotificationKindParsing on String {
  NotificationKind toNotificationKind() {
    switch (this) {
      case 'wo_created':
        return NotificationKind.woCreated;
      case 'wo_assigned':
        return NotificationKind.woAssigned;
      case 'wo_ready_for_review':
        return NotificationKind.woReadyForReview;
      case 'material_return_submitted':
        return NotificationKind.materialReturnSubmitted;
      case 'material_return_verified':
        return NotificationKind.materialReturnVerified;
      case 'wo_lembur_approved':
      case 'lembur_approved':
      case 'wo_overtime_approved':
        return NotificationKind.woLemburApproved;
      default:
        return NotificationKind.unknown;
    }
  }
}

class NotificationDataEntity extends Equatable {
  final String title;
  final String message;
  final int workOrderId;

  /// Nilai mentah `data.type` dari BE. Gunakan [kind] untuk percabangan logika.
  final String type;
  final String senderName;

  const NotificationDataEntity({
    required this.title,
    required this.message,
    required this.workOrderId,
    required this.type,
    required this.senderName,
  });

  /// Tipe notifikasi yang sudah dipetakan; aman untuk tipe yang tidak dikenal.
  NotificationKind get kind => type.toNotificationKind();

  @override
  List<Object?> get props => [title, message, workOrderId, type, senderName];
}
