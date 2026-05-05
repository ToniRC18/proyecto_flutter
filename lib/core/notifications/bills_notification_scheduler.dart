import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../features/bills/domain/bill_model.dart';
import 'notification_service.dart';

/// Agenda recordatorios locales para los próximos bills.
class BillsNotificationScheduler {
  static const _reminderBaseId = 1000;
  static const _dueBaseId = 1500;
  static const _maxBillsToSchedule = 500;
  static const _billsChannelId = 'bills';
  static const _billsChannelName = 'Pagos recurrentes';

  Future<void> scheduleAllBillNotifications(List<BillModel> bills) async {
    try {
      await _cancelExistingBillNotifications();

      final upcomingBills = bills
          .where((bill) => bill.isActive && bill.isUpcoming)
          .take(_maxBillsToSchedule)
          .toList();

      for (var index = 0; index < upcomingBills.length; index++) {
        final bill = upcomingBills[index];
        final dueDate = _nextDueDateAtHour(bill, 8);
        var reminderDate = _nextDueDateAtHour(bill, 9).subtract(
          const Duration(days: 3),
        );

        if (reminderDate.isBefore(DateTime.now())) {
          reminderDate = _advanceToNextCycle(bill, reminderDate, 9);
        }
        final effectiveDueDate = dueDate.isBefore(DateTime.now())
            ? _advanceToNextCycle(bill, dueDate, 8)
            : dueDate;

        await flutterLocalNotificationsPlugin.zonedSchedule(
          _reminderBaseId + index,
          'Pago próximo: ${bill.name}',
          '\$${bill.amount.toStringAsFixed(2)} vence en ${bill.daysUntilDue} días',
          tz.TZDateTime.from(reminderDate, tz.local),
          _notificationDetails(),
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'bill_${bill.id}',
        );

        await flutterLocalNotificationsPlugin.zonedSchedule(
          _dueBaseId + index,
          'Hoy vence: ${bill.name}',
          'No olvides pagar \$${bill.amount.toStringAsFixed(2)}',
          tz.TZDateTime.from(effectiveDueDate, tz.local),
          _notificationDetails(),
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'bill_${bill.id}',
        );
      }
    } catch (_) {
      throw Exception('No se pudieron programar los recordatorios de pagos.');
    }
  }

  Future<void> _cancelExistingBillNotifications() async {
    for (var id = 1000; id < 2500; id++) {
      await flutterLocalNotificationsPlugin.cancel(id);
    }
  }

  DateTime _nextDueDateAtHour(BillModel bill, int hour) {
    final dueDate = bill.nextDueDate;
    return DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      hour,
    );
  }

  DateTime _advanceToNextCycle(BillModel bill, DateTime date, int hour) {
    switch (bill.frequency) {
      case BillFrequency.monthly:
        final nextMonth = DateTime(date.year, date.month + 1, 1);
        return DateTime(
          nextMonth.year,
          nextMonth.month,
          BillModel.clampDay(nextMonth.year, nextMonth.month, bill.dueDay),
          hour,
        );
      case BillFrequency.weekly:
        final nextWeek = date.add(const Duration(days: 7));
        return DateTime(
          nextWeek.year,
          nextWeek.month,
          nextWeek.day,
          hour,
        );
      case BillFrequency.yearly:
        final nextYear = date.year + 1;
        return DateTime(
          nextYear,
          bill.createdAt.month,
          BillModel.clampDay(nextYear, bill.createdAt.month, bill.dueDay),
          hour,
        );
    }
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _billsChannelId,
        _billsChannelName,
        channelDescription: 'Recordatorios de pagos recurrentes',
        icon: '@mipmap/ic_launcher',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }
}
