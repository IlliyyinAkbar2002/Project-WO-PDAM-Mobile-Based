import 'package:project_mobile_pdam/feature/work_order/domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.type,
    required super.data,
    super.readAt,
    required super.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseUtcDateTime(dynamic value) {
      if (value is DateTime) return value.isUtc ? value.toLocal() : value;
      if (value is String) {
        String raw = value.trim();
        if (raw.isEmpty) return null;
        if (!raw.endsWith('Z') && !raw.contains('+')) {
          raw = '${raw.replaceAll(' ', 'T')}Z';
        }
        return DateTime.tryParse(raw)?.toLocal();
      }
      return null;
    }

    return NotificationModel(
      id: map['id'] as String,
      type: map['type'] as String,
      data: NotificationDataModel.fromMap(map['data'] as Map<String, dynamic>),
      readAt: parseUtcDateTime(map['read_at']),
      createdAt: parseUtcDateTime(map['created_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'data': (data as NotificationDataModel).toMap(),
      'read_at': readAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  NotificationEntity toEntity() {
    return NotificationEntity(
      id: id,
      type: type,
      data: data,
      readAt: readAt,
      createdAt: createdAt,
    );
  }
}

class NotificationDataModel extends NotificationDataEntity {
  const NotificationDataModel({
    required super.title,
    required super.message,
    required super.workOrderId,
    required super.type,
    required super.senderName,
  });

  factory NotificationDataModel.fromMap(Map<String, dynamic> map) {
    // API sends work_order_id. It might be int or string. Let's parse it safely.
    final rawWorkOrderId = map['work_order_id'];
    final int workOrderIdVal;
    if (rawWorkOrderId is int) {
      workOrderIdVal = rawWorkOrderId;
    } else if (rawWorkOrderId is String) {
      workOrderIdVal = int.tryParse(rawWorkOrderId) ?? 0;
    } else {
      workOrderIdVal = 0;
    }

    return NotificationDataModel(
      title: (map['title'] ?? '').toString(),
      message: (map['message'] ?? '').toString(),
      workOrderId: workOrderIdVal,
      type: (map['type'] ?? '').toString(),
      senderName: (map['sender_name'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'work_order_id': workOrderId,
      'type': type,
      'sender_name': senderName,
    };
  }
}
