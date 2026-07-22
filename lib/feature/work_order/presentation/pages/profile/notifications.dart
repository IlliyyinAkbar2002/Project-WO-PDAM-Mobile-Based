import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/core/seed/maps_seed_model.dart';
import 'package:project_mobile_pdam/core/utils/auth_storage.dart';
import 'package:project_mobile_pdam/core/utils/app_snackbar.dart';
import 'package:project_mobile_pdam/feature/work_order/data/data_source/remote/work_order_remote_data_source.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/notification_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/bloc/notification_bloc.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_reguler/assignee_page/assignee_work_order_detail_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_reguler/detail_work_order/detail_work_order_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/wo_lembur/detail_work_order_page_lembur.dart';
import 'package:project_mobile_pdam/feature/peminjaman_material/presentation/pages/approval/approval_pengembalian_peminjaman_asset.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  static const Color _textPrimary = Color(0xFF282A37);
  static const Color _textSecondary = Color(0xFF515978);
  static const Color _accentBlue = Color(0xFF156CD7);
  static const Color _blueSoft = Color(0xFFEEF7FF);
  static const Color _cardSoft = Color(0xFFF6F7F9);
  static const Color _lineColor = Color(0xFFECEDF2);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(FetchNotificationsEvent());
  }

  String _getInitials(String name) {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return '?';
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    final first = parts.first.characters.firstOrNull ?? '';
    final last = parts.last.characters.firstOrNull ?? '';
    return '$first$last'.toUpperCase();
  }

  Color _getAvatarColor(String senderName) {
    final code = senderName.hashCode.abs();
    final colors = [
      const Color(0xFFE99C11),
      const Color(0xFF0A043C),
      const Color(0xFFE1260D),
      const Color(0xFFF39200),
      const Color(0xFF8F77F6),
      const Color(0xFF156CD7),
    ];
    return colors[code % colors.length];
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }

  /// Ikon yang merepresentasikan setiap jenis notifikasi (berdasarkan
  /// `data.type` yang sudah dipetakan ke [NotificationKind]).
  IconData _iconForKind(NotificationKind kind) {
    switch (kind) {
      case NotificationKind.woCreated:
        return Icons.assignment_add;
      case NotificationKind.woAssigned:
        return Icons.assignment_ind_rounded;
      case NotificationKind.woReadyForReview:
        return Icons.fact_check_rounded;
      case NotificationKind.materialReturnSubmitted:
        return Icons.inventory_2_rounded;
      case NotificationKind.materialReturnVerified:
        return Icons.inventory_rounded;
      case NotificationKind.woLemburApproved:
        return Icons.more_time_rounded;
      case NotificationKind.unknown:
        return Icons.notifications_rounded;
    }
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    NotificationEntity n,
  ) async {
    // 1. Selalu tandai sudah dibaca (optimistic update ditangani Bloc).
    context.read<NotificationBloc>().add(MarkNotificationAsReadEvent(n.id));

    switch (n.data.kind) {
      case NotificationKind.materialReturnSubmitted:
        // Pengembalian material → SPV langsung ke halaman persetujuan.
        if (AuthStorage.getJabatanKodeSync() == 'SPV') {
          await _openPage(context, const PersetujuanPeminjamanBarangPage());
        }
        return;

      case NotificationKind.woCreated:
      case NotificationKind.woAssigned:
      case NotificationKind.woReadyForReview:
      case NotificationKind.materialReturnVerified:
      case NotificationKind.woLemburApproved:
        // Semua bermuara ke detail WO terkait. Untuk WO lembur,
        // _openWorkOrderDetail otomatis membuka layar lembur (isLembur).
        await _openWorkOrderDetail(context, n.data.workOrderId);
        return;

      case NotificationKind.unknown:
        if (n.data.workOrderId > 0) {
          await _openWorkOrderDetail(context, n.data.workOrderId);
        }
        return;
    }
  }

  /// Buka halaman lalu refresh daftar notifikasi saat kembali.
  Future<void> _openPage(BuildContext context, Widget page) async {
    if (!context.mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (context.mounted) {
      context.read<NotificationBloc>().add(FetchNotificationsEvent());
    }
  }

  Future<void> _openWorkOrderDetail(
    BuildContext context,
    int workOrderId,
  ) async {
    if (workOrderId <= 0) return;

    // Loading dialog selama fetch detail.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );

    try {
      final ds = WorkOrderRemoteDataSource();
      final result = await ds.fetchWorkOrderDetail(workOrderId);

      if (context.mounted) {
        Navigator.of(context).pop(); // tutup loading dialog
      }

      if (result is! DataSuccess) {
        if (context.mounted) {
          AppSnackbar.showError("Gagal mengambil detail pekerjaan.");
        }
        return;
      }

      final workOrder = result.data!;
      if (!context.mounted) return;

      final user = AuthStorage.getUserSync();
      final roleId = user?['role_id'] as int?;
      final jabatanKode = AuthStorage.getJabatanKodeSync();
      // Skema MergerManual: pegawai = role_id 4 (lapangan), dibedakan via jabatan.
      // Staff = pegawai non-SPV (Staff / Staff Senior).
      final isStaff = roleId == 4 && jabatanKode != 'SPV';

      final lngLat = workOrder.assignment?.latitude != null
          ? LatLng(
              workOrder.assignment!.latitude!,
              workOrder.assignment!.longitude!,
            )
          : null;
      final radiusMeter =
          workOrder.assignment?.location?.radiusMeter ??
          MapsSeedModel.defaultRadiusMeter;
      final locationName = workOrder.assignment?.location?.nama;
      final workOrderTypeId =
          workOrder.workOrderTypeId ?? workOrder.workOrderType?.id;

      final Widget detailPage;
      if (workOrder.isLembur) {
        // Layar WO lembur dipakai bersama staff & SPV.
        detailPage = DetailWorkOrderPageLembur(
          isAssignee: isStaff,
          workOrderId: workOrder.id,
          workOrderTypeId: workOrderTypeId,
          status: workOrder.statusId,
          kategoriForm: workOrder.kategoriForm,
          lngLat: lngLat,
          locationName: locationName,
          radiusMeter: radiusMeter,
        );
      } else if (isStaff) {
        detailPage = AssigneeWorkOrderDetailPage(
          isAssignee: true,
          workOrderId: workOrder.id,
          workOrderTypeId: workOrderTypeId,
          status: workOrder.statusId,
          kategoriForm: workOrder.kategoriForm,
          lngLat: lngLat,
          locationName: locationName,
          radiusMeter: radiusMeter,
        );
      } else {
        detailPage = DetailWorkOrderPage(
          picId: null,
          userId: user?['id'] as int?,
          workOrderId: workOrder.id,
          status: workOrder.statusId,
          isOvertime: workOrder.requiresApproval,
        );
      }

      await _openPage(context, detailPage);
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // tutup dialog bila error
        AppSnackbar.showError("Terjadi kesalahan: $e");
      }
    }
  }

  Widget _buildNotificationRow(BuildContext context, NotificationEntity n) {
    return _NotificationItem(
      initials: _getInitials(n.data.senderName),
      actor: n.data.senderName,
      content: n.data.message,
      subtitle: '${n.data.title} - ${_formatTimeAgo(n.createdAt)}',
      avatarColor: _getAvatarColor(n.data.senderName),
      typeIcon: _iconForKind(n.data.kind),
      isUnread: !n.isRead,
      onTap: () => _handleNotificationTap(context, n),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            if (state is NotificationLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is NotificationError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: NotificationsPage._textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          context.read<NotificationBloc>().add(
                            FetchNotificationsEvent(),
                          );
                        },
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is NotificationLoaded) {
              final notifications = state.notifications;
              final today = DateTime.now();

              final todayNotifications = notifications.where((n) {
                final local = n.createdAt.toLocal();
                return local.year == today.year &&
                    local.month == today.month &&
                    local.day == today.day;
              }).toList();

              final olderNotifications = notifications.where((n) {
                final local = n.createdAt.toLocal();
                return !(local.year == today.year &&
                    local.month == today.month &&
                    local.day == today.day);
              }).toList();

              if (notifications.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<NotificationBloc>().add(
                      FetchNotificationsEvent(),
                    );
                  },
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16, topInset + 18, 16, 20),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const _NotificationsHeader(unreadCount: 0),
                      const SizedBox(height: 100),
                      const Center(
                        child: Text(
                          'Belum ada notifikasi.',
                          style: TextStyle(
                            color: NotificationsPage._textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<NotificationBloc>().add(
                    FetchNotificationsEvent(),
                  );
                },
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, topInset + 18, 16, 20),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    _NotificationsHeader(unreadCount: state.unreadCount),
                    const SizedBox(height: 18),
                    if (todayNotifications.isNotEmpty) ...[
                      const _SectionTitle(title: 'Hari Ini'),
                      ...todayNotifications.map(
                        (n) => _buildNotificationRow(context, n),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (olderNotifications.isNotEmpty) ...[
                      const _SectionTitle(title: 'Sebelumnya'),
                      ...olderNotifications.map(
                        (n) => _buildNotificationRow(context, n),
                      ),
                    ],
                  ],
                ),
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}

class _NotificationsHeader extends StatelessWidget {
  final int unreadCount;
  const _NotificationsHeader({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: NotificationsPage._blueSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: NotificationsPage._accentBlue,
                  size: 20,
                ),
              ),
            ),
            const Spacer(),
            Tooltip(
              message: 'Tandai semua dibaca',
              child: GestureDetector(
                onTap: unreadCount > 0
                    ? () => context.read<NotificationBloc>().add(
                        MarkAllNotificationsAsReadEvent(),
                      )
                    : null,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: NotificationsPage._blueSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.done_all_rounded,
                    color: unreadCount > 0
                        ? NotificationsPage._accentBlue
                        : NotificationsPage._textSecondary.withValues(
                            alpha: 0.4,
                          ),
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Notifications',
          style: TextStyle(
            color: NotificationsPage._textPrimary,
            fontSize: 34 / 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: const TextStyle(
              color: NotificationsPage._textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            children: [
              const TextSpan(text: 'You have '),
              TextSpan(
                text: '$unreadCount Notifications',
                style: const TextStyle(
                  color: NotificationsPage._accentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: ' today.'),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 32 / 1.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final String initials;
  final String actor;
  final String content;
  final String subtitle;
  final Color avatarColor;
  final IconData typeIcon;
  final bool isUnread;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.initials,
    required this.actor,
    required this.content,
    required this.subtitle,
    required this.avatarColor,
    required this.typeIcon,
    required this.isUnread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: NotificationsPage._lineColor),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isUnread
                    ? NotificationsPage._accentBlue
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18 / 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: NotificationsPage._textSecondary,
                        fontSize: 30 / 2.2,
                        fontWeight: FontWeight.w400,
                      ),
                      children: [
                        TextSpan(
                          text: actor,
                          style: const TextStyle(
                            color: NotificationsPage._accentBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(text: ' $content'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: NotificationsPage._textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 60,
              height: 50,
              decoration: BoxDecoration(
                color: NotificationsPage._cardSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(
                typeIcon,
                color: NotificationsPage._accentBlue,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
