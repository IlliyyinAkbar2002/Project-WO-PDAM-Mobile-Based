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

class NotificationDataEntity extends Equatable {
  final String title;
  final String message;
  final int workOrderId;
  final String
  type; // "wo_created" | "wo_assigned" | "wo_ready_for_review" | "wo_completed"
  final String senderName;

  const NotificationDataEntity({
    required this.title,
    required this.message,
    required this.workOrderId,
    required this.type,
    required this.senderName,
  });

  @override
  List<Object?> get props => [title, message, workOrderId, type, senderName];
}
