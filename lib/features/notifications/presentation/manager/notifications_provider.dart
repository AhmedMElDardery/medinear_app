import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/get_notifications_usecase.dart';

class NotificationsProvider extends ChangeNotifier {
  final GetNotificationsUseCase getNotificationsUseCase;

  List<NotificationEntity> _notifications = [];
  String _currentFilter = 'All';
  bool _isLoading = false;
  int _itemsToShow = 6;

  NotificationsProvider({required this.getNotificationsUseCase}) {
    fetchData();
  }

  bool get isLoading => _isLoading;
  String get currentFilter => _currentFilter;
  bool get hasUnread => _notifications.any((n) => !n.isRead);

  List<NotificationEntity> get displayedNotifications {
    List<NotificationEntity> filtered;
    if (_currentFilter == 'Unread') {
      filtered = _notifications.where((n) => !n.isRead).toList();
    } else {
      filtered = _notifications;
    }
    return filtered.take(_itemsToShow).toList();
  }

  bool get hasMoreItems {
    int totalFiltered = _currentFilter == 'Unread'
        ? _notifications.where((n) => !n.isRead).length
        : _notifications.length;
    return _itemsToShow < totalFiltered;
  }

  Future<void> fetchData() async {
    _isLoading = true;
    notifyListeners();
    try {
      final fetched = await getNotificationsUseCase.execute();
      final prefs = await SharedPreferences.getInstance();
      
      final readIds = prefs.getStringList('read_notifications') ?? [];
      final deletedIds = prefs.getStringList('deleted_notifications') ?? [];

      _notifications = fetched.where((n) => !deletedIds.contains(n.id)).toList();
      for (var n in _notifications) {
        if (readIds.contains(n.id)) {
          n.isRead = true;
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(String filter) {
    _currentFilter = filter;
    _itemsToShow = 6;
    notifyListeners();
  }

  void loadMore() {
    _itemsToShow += 5;
    notifyListeners();
  }

  Future<void> refresh() async {
    _itemsToShow = 6;
    await fetchData();
  }

  void markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList('read_notifications') ?? [];
      if (!readIds.contains(id)) {
        readIds.add(id);
        await prefs.setStringList('read_notifications', readIds);
      }
    }
  }

  void markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList('read_notifications') ?? [];

    for (var n in _notifications) {
      n.isRead = true;
      if (!readIds.contains(n.id)) {
        readIds.add(n.id);
      }
    }
    await prefs.setStringList('read_notifications', readIds);
    notifyListeners();
  }

  NotificationEntity? deleteItem(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final removedItem = _notifications[index];
      _notifications.removeAt(index);
      notifyListeners();

      SharedPreferences.getInstance().then((prefs) {
        final deletedIds = prefs.getStringList('deleted_notifications') ?? [];
        if (!deletedIds.contains(id)) {
          deletedIds.add(id);
          prefs.setStringList('deleted_notifications', deletedIds);
        }
      });

      return removedItem;
    }
    return null;
  }

  void restoreItem(NotificationEntity item) async {
    _notifications.add(item);
    _notifications.sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final deletedIds = prefs.getStringList('deleted_notifications') ?? [];
    if (deletedIds.contains(item.id)) {
      deletedIds.remove(item.id);
      await prefs.setStringList('deleted_notifications', deletedIds);
    }
  }
}
