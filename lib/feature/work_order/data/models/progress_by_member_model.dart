import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:project_mobile_pdam/feature/work_order/data/models/member_progress_model.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/progress_by_member_entity.dart';

class ProgressByMemberModel extends ProgressByMemberEntity {
  const ProgressByMemberModel({
    required super.workorderId,
    required super.workorderName,
    required super.estimasiHari,
    required super.members,
  });

  factory ProgressByMemberModel.fromJson(String source) =>
      ProgressByMemberModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory ProgressByMemberModel.fromMap(Map<String, dynamic> map) {
    debugPrint("📋 Parsing ProgressByMember: ${map['workorder_name']}");

    int? parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    List<MemberProgressModel> parseMembersList(dynamic value) {
      if (value is List) {
        return value
            .whereType<Map>()
            .map((json) => MemberProgressModel.fromMap(
                  Map<String, dynamic>.from(json),
                ))
            .toList();
      }
      return [];
    }

    return ProgressByMemberModel(
      workorderId: parseInt(map['workorder_id']) ?? 0,
      workorderName: map['workorder_name']?.toString() ?? '',
      estimasiHari: parseInt(map['estimasi_hari']) ?? 0,
      members: parseMembersList(map['members']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'workorder_id': workorderId,
      'workorder_name': workorderName,
      'estimasi_hari': estimasiHari,
      'members': members
          .map((member) => MemberProgressModel.fromEntity(member).toMap())
          .toList(),
    };
  }

  ProgressByMemberEntity toEntity() {
    return ProgressByMemberEntity(
      workorderId: workorderId,
      workorderName: workorderName,
      estimasiHari: estimasiHari,
      members: members,
    );
  }

  factory ProgressByMemberModel.fromEntity(ProgressByMemberEntity entity) {
    return ProgressByMemberModel(
      workorderId: entity.workorderId,
      workorderName: entity.workorderName,
      estimasiHari: entity.estimasiHari,
      members: entity.members,
    );
  }
}
