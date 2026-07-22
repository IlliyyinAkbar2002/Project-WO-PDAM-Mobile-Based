import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_mobile_pdam/core/resource/data_state.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/entities/notification_entity.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/notification_usecases/get_notifications_usecase.dart';
import 'package:project_mobile_pdam/feature/work_order/domain/usecases/notification_usecases/mark_notification_as_read_usecase.dart';

// --- Events ---
abstract class NotificationEvent {}

class FetchNotificationsEvent extends NotificationEvent {}

class MarkNotificationAsReadEvent extends NotificationEvent {
  final String id;
  MarkNotificationAsReadEvent(this.id);
}

class MarkAllNotificationsAsReadEvent extends NotificationEvent {}

// --- States ---
abstract class NotificationState {}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<NotificationEntity> notifications;
  final int unreadCount;

  NotificationLoaded(this.notifications)
      : unreadCount = notifications.where((n) => !n.isRead).length;
}

class NotificationError extends NotificationState {
  final String message;
  NotificationError(this.message);
}

// --- Bloc ---
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotificationsUseCase _getNotificationsUseCase;
  final MarkNotificationAsReadUseCase _markNotificationAsReadUseCase;

  NotificationBloc(
    this._getNotificationsUseCase,
    this._markNotificationAsReadUseCase,
  ) : super(NotificationInitial()) {
    on<FetchNotificationsEvent>(_onFetchNotifications);
    on<MarkNotificationAsReadEvent>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsReadEvent>(_onMarkAllNotificationsAsRead);
  }

  Future<void> _onFetchNotifications(
    FetchNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    try {
      final result = await _getNotificationsUseCase(null);
      if (result is DataSuccess<List<NotificationEntity>>) {
        // Sort notifications to show newest first
        final sortedList = List<NotificationEntity>.from(result.data!)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        emit(NotificationLoaded(sortedList));
      } else if (result is DataFailed) {
        emit(NotificationError(result.error?.toString() ?? 'Gagal memuat notifikasi'));
      }
    } catch (e) {
      emit(NotificationError('Terjadi kesalahan: $e'));
    }
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    // Lewati jika notifikasi tidak ada atau sudah dibaca (hindari panggilan
    // API berulang saat di-tap lagi).
    final alreadyRead = currentState.notifications.any(
      (n) => n.id == event.id && n.isRead,
    );
    final exists = currentState.notifications.any((n) => n.id == event.id);
    if (!exists || alreadyRead) return;

    // Simpan snapshot untuk revert, lalu update optimistis.
    final previousNotifications = currentState.notifications;
    final updatedNotifications = previousNotifications.map((n) {
      if (n.id == event.id) {
        return n.copyWith(readAt: DateTime.now());
      }
      return n;
    }).toList();

    emit(NotificationLoaded(updatedNotifications));

    // Panggil API di latar belakang.
    final result = await _markNotificationAsReadUseCase(event.id);
    if (result is DataFailed && state is NotificationLoaded) {
      // Revert tanpa memicu loading flash (kembalikan snapshot sebelumnya).
      emit(NotificationLoaded(previousNotifications));
    }
  }

  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    final previousNotifications = currentState.notifications;
    final unreadIds = previousNotifications
        .where((n) => !n.isRead)
        .map((n) => n.id)
        .toList();
    if (unreadIds.isEmpty) return;

    // Update optimistis: tandai semua dibaca sekaligus.
    final now = DateTime.now();
    emit(
      NotificationLoaded(
        previousNotifications
            .map((n) => n.isRead ? n : n.copyWith(readAt: now))
            .toList(),
      ),
    );

    // BE tidak punya endpoint bulk read-all; panggil endpoint single per id.
    final results = await Future.wait(
      unreadIds.map((id) => _markNotificationAsReadUseCase(id)),
    );

    // Revert parsial: hanya id yang gagal yang dikembalikan ke unread.
    final failedIds = <String>{
      for (var i = 0; i < unreadIds.length; i++)
        if (results[i] is DataFailed) unreadIds[i],
    };
    if (failedIds.isNotEmpty && state is NotificationLoaded) {
      emit(
        NotificationLoaded(
          previousNotifications
              .map(
                (n) => n.isRead || failedIds.contains(n.id)
                    ? n
                    : n.copyWith(readAt: now),
              )
              .toList(),
        ),
      );
    }
  }
}
