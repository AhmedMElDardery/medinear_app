import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// --- Core Imports ---
import 'package:medinear_app/core/network/dio_clilent.dart';
import 'package:medinear_app/core/services/token_storage.dart';
import 'package:medinear_app/core/services/user_storage.dart';
import 'package:medinear_app/core/theme/theme_provider.dart';
import 'package:medinear_app/core/provider/navigation_provider.dart';
import 'package:medinear_app/core/provider/locale_provider.dart';

// --- Features Imports ---
import 'package:medinear_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:medinear_app/features/auth/data/datasources/auth_remote_data_source_impl.dart';
import 'package:medinear_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:medinear_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:medinear_app/features/auth/presentation/auth_provider.dart';

import 'package:medinear_app/features/home/data/datasources/home_remote_data_source.dart';
import 'package:medinear_app/features/home/data/datasources/home_remote_data_source_impl.dart';
import 'package:medinear_app/features/home/data/repositories/home_repository_impl.dart';
import 'package:medinear_app/features/home/domain/repositories/home_repository.dart';
import 'package:medinear_app/features/home/presentation/provider/home_provider.dart';

import 'package:medinear_app/features/map/data/datasource/map_remote_datasource.dart'
    hide MapProvider;
import 'package:medinear_app/features/map/data/repositories/map_repository_impl.dart';
import 'package:medinear_app/features/map/domain/repositories/map_repository.dart';
import 'package:medinear_app/features/map/presentation/provider/map_provider.dart';

import 'package:medinear_app/features/about_us/presentation/manager/about_provider.dart';
import 'package:medinear_app/features/chat/view_models/chats_view_model.dart';
import 'package:medinear_app/features/onboarding/onboarding_provider.dart';
import 'package:medinear_app/features/pharmacy/presentation/manager/pharmacy_provider.dart';
import 'package:medinear_app/features/profile/view_models/profile_provider.dart';
import 'package:medinear_app/features/orders/presentation/manager/order_provider.dart';
import 'package:medinear_app/features/saved_items/presentation/manager/saved_items_provider.dart';
import 'package:medinear_app/features/alarm/view_models/alarm_view_model.dart';
import 'package:medinear_app/features/chat_bot/provider/chat_bot_provider.dart';
import 'package:medinear_app/features/support/presentation/provider/support_provider.dart';
import 'package:medinear_app/features/wallet/view_models/wallet_view_model.dart';
import 'package:medinear_app/features/splash/splash_provider.dart';
import 'package:medinear_app/features/cart/presentation/manager/cart_provider.dart';
import 'package:medinear_app/features/notifications/presentation/manager/notifications_provider.dart';
import 'package:medinear_app/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:medinear_app/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:medinear_app/features/notifications/data/datasources/notifications_remote_data_source.dart';

// ==========================================
// 1. Core Services & Clients
// ==========================================
final dioClientProvider = Provider<DioClient>((ref) => DioClient());
final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
final userStorageProvider = Provider<UserStorage>((ref) => UserStorage());

// ==========================================
// 2. Auth Dependencies
// ==========================================
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.read(dioClientProvider).dio);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.read(authRemoteDataSourceProvider),
    ref.read(tokenStorageProvider),
    ref.read(userStorageProvider),
  );
});

// Using ChangeNotifierProvider as a bridge. Global state.
final authProvider = ChangeNotifierProvider<AuthProvider>((ref) {
  final provider = AuthProvider(
    ref.read(authRepositoryProvider),
    ref.read(userStorageProvider),
  );
  provider.loadCachedUser();
  return provider;
});

// ==========================================
// 3. Home Dependencies
// ==========================================
final homeRemoteDataSourceProvider = Provider<HomeRemoteDataSource>((ref) {
  return HomeRemoteDataSourceImpl(
    dio: ref.read(dioClientProvider).dio,
    tokenStorage: ref.read(tokenStorageProvider),
  );
});

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepositoryImpl(ref.read(homeRemoteDataSourceProvider));
});

final homeProvider = ChangeNotifierProvider<HomeProvider>((ref) {
  return HomeProvider(ref.read(homeRepositoryProvider));
});

// ==========================================
// 4. Map Dependencies
// ==========================================
final mapRemoteDataSourceProvider = Provider<MapRemoteDataSource>((ref) {
  return MapRemoteDataSource(ref.read(dioClientProvider).dio);
});

final mapRepositoryProvider = Provider<MapRepository>((ref) {
  return MapRepositoryImpl(ref.read(mapRemoteDataSourceProvider));
});

// AutoDispose for map state to fix memory leak!
final mapProvider = ChangeNotifierProvider.autoDispose<MapProvider>((ref) {
  return MapProvider(ref.read(mapRepositoryProvider));
});

// ==========================================
// 5. Global & UI Providers
// ==========================================
// Global Themes & Navigation & Locale
final themeProvider =
    ChangeNotifierProvider<ThemeProvider>((ref) => ThemeProvider());
final navigationProvider =
    ChangeNotifierProvider<NavigationProvider>((ref) => NavigationProvider());
final localeProvider =
    ChangeNotifierProvider<LocaleProvider>((ref) => LocaleProvider());

// AutoDispose for screen-specific states to fix memory leaks
final splashProvider =
    ChangeNotifierProvider.autoDispose<SplashProvider>((ref) {
  return SplashProvider(ref.read(tokenStorageProvider));
});

final onboardingProvider =
    ChangeNotifierProvider.autoDispose<OnboardingProvider>(
        (ref) => OnboardingProvider());
final savedItemsProvider =
    ChangeNotifierProvider.autoDispose<SavedItemsProvider>(
        (ref) => SavedItemsProvider());
final pharmacyProvider = ChangeNotifierProvider.autoDispose<PharmacyProvider>(
    (ref) => PharmacyProvider());
final cartProvider =
    ChangeNotifierProvider.autoDispose<CartProvider>((ref) => CartProvider());
final aboutProvider =
    ChangeNotifierProvider.autoDispose<AboutProvider>((ref) => AboutProvider());
final profileProvider = ChangeNotifierProvider.autoDispose<ProfileProvider>(
    (ref) => ProfileProvider());
final orderProvider =
    ChangeNotifierProvider.autoDispose<OrderProvider>((ref) => OrderProvider());
final chatsViewModelProvider =
    ChangeNotifierProvider.autoDispose<ChatsViewModel>(
        (ref) => ChatsViewModel());
final chatBotProvider = ChangeNotifierProvider.autoDispose<ChatBotProvider>(
    (ref) => ChatBotProvider());
final walletViewModelProvider =
    ChangeNotifierProvider.autoDispose<WalletViewModel>(
        (ref) => WalletViewModel());
final alarmViewModelProvider =
    ChangeNotifierProvider.autoDispose<AlarmViewModel>(
        (ref) => AlarmViewModel());
final supportProvider = ChangeNotifierProvider.autoDispose<SupportProvider>(
    (ref) => SupportProvider());
final notificationsProvider =
    ChangeNotifierProvider.autoDispose<NotificationsProvider>((ref) {
  return NotificationsProvider(
    getNotificationsUseCase: GetNotificationsUseCase(
      NotificationsRepositoryImpl(
        remoteDataSource: NotificationsRemoteDataSource(),
      ),
    ),
  );
});
