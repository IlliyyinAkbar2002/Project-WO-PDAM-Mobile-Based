import 'package:equatable/equatable.dart';

class SplEntity extends Equatable {
  final int? id;
  final int? statusId;
  final String? decision;
  final int? verificatorId;
  final DateTime? createdAt;
  final DateTime? verificationDate;
  final String? reason;

  const SplEntity({
    this.id,
    this.statusId,
    this.decision,
    this.verificatorId,
    this.createdAt,
    this.verificationDate,
    this.reason,
  });

  @override
  List<Object?> get props => [
        id,
        statusId,
        decision,
        verificatorId,
        createdAt,
        verificationDate,
        reason,
      ];

  SplEntity copyWith({
    int? id,
    int? statusId,
    String? decision,
    int? verificatorId,
    DateTime? createdAt,
    DateTime? verificationDate,
    String? reason,
  }) {
    return SplEntity(
      id: id ?? this.id,
      statusId: statusId ?? this.statusId,
      decision: decision ?? this.decision,
      verificatorId: verificatorId ?? this.verificatorId,
      createdAt: createdAt ?? this.createdAt,
      verificationDate: verificationDate ?? this.verificationDate,
      reason: reason ?? this.reason,
    );
  }
}
