import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:medinear_app/core/localization/app_localizations.dart';
import 'package:medinear_app/features/alarm/views/alarm_view.dart';
import 'package:medinear_app/features/support/presentation/screen/support_screen.dart';
import 'package:medinear_app/features/wallet/views/wallet_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medinear_app/core/di/global_providers.dart';
import '../view_models/profile_provider.dart';
import 'widgets/profile_widgets.dart';
import 'package:medinear_app/features/auth/presentation/auth_provider.dart';

import 'package:medinear_app/features/about_us/presentation/screens/about_support_screen.dart';
import 'package:medinear_app/features/orders/presentation/screens/my_orders_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.watch(profileProvider).fetchProfile();
    });
  }

  void _showEditDialog(
      String title, String currentVal, ProfileProvider provider) {
    if (currentVal == 'No Phone' ||
        currentVal == 'No Name' ||
        currentVal == 'No Email') {
      currentVal = '';
    }
    TextEditingController controller = TextEditingController(text: currentVal);
    bool isPhoneField = title == 'Phone';
    String? errorMessage;

    final List<Map<String, dynamic>> countries = [
      {'name': 'Egypt', 'flag': '🇪🇬', 'code': '+20', 'maxLength': 11},
      {'name': 'Saudi Arabia', 'flag': '🇸🇦', 'code': '+966', 'maxLength': 9},
      {'name': 'UAE', 'flag': '🇦🇪', 'code': '+971', 'maxLength': 9},
      {'name': 'Kuwait', 'flag': '🇰🇼', 'code': '+965', 'maxLength': 8},
    ];

    Map<String, dynamic> selectedCountry = countries[0];

    if (isPhoneField) {
      String cleanPhone = currentVal;
      for (var country in countries) {
        if (currentVal.startsWith(country['code'])) {
          selectedCountry = country;
          cleanPhone = currentVal.replaceFirst(country['code'], '').trim();
          break;
        }
      }
      controller.text = cleanPhone;
    }

    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (stateCtx, setDialogState) {
          return AlertDialog(
            backgroundColor: theme.cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text('Edit $title',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isPhoneField
                    ? Row(
                        children: [
                          Container(
                            height: 55,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: errorMessage != null
                                      ? Colors.red
                                      : theme.dividerColor,
                                  width: errorMessage != null ? 1.5 : 1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Map<String, dynamic>>(
                                dropdownColor: theme.cardColor,
                                value: selectedCountry,
                                items: countries
                                    .map((c) => DropdownMenuItem(
                                        value: c,
                                        child: Text('${c['flag']} ${c['code']}',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: theme.textTheme.bodyLarge?.color))))
                                    .toList(),
                                onChanged: (val) {
                                  setDialogState(() {
                                    selectedCountry = val!;
                                    controller.clear();
                                    errorMessage = null;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 55,
                              child: TextField(
                                controller: controller,
                                keyboardType: TextInputType.phone,
                                style: TextStyle(
                                    color: theme.textTheme.bodyLarge?.color),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(
                                      selectedCountry['maxLength'])
                                ],
                                onChanged: (v) =>
                                    setDialogState(() => errorMessage = null),
                                decoration: InputDecoration(
                                  hintText: selectedCountry['code'] == '+20'
                                      ? "01xxxxxxxxx"
                                      : "Enter number",
                                  hintStyle: TextStyle(color: theme.hintColor),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: errorMessage != null
                                            ? Colors.red
                                            : theme.dividerColor,
                                        width: errorMessage != null ? 1.5 : 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: errorMessage != null
                                            ? Colors.red
                                            : theme.colorScheme.primary,
                                        width: 2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : TextField(
                        controller: controller,
                        style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                        onChanged: (v) =>
                            setDialogState(() => errorMessage = null),
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: errorMessage != null
                                    ? Colors.red
                                    : theme.dividerColor,
                                width: errorMessage != null ? 1.5 : 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: errorMessage != null
                                    ? Colors.red
                                    : theme.colorScheme.primary,
                                width: 2),
                          ),
                        ),
                      ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.red, size: 16),
                      const SizedBox(width: 6),
                      Text(errorMessage!,
                          style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ]
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Cancel',
                      style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.bold))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    String finalValue = controller.text.trim();
                    if (isPhoneField) {
                      finalValue = finalValue.replaceAll(' ', '');
                      if (finalValue.startsWith('0')) {
                        finalValue = finalValue.substring(1);
                      }
                      finalValue = '${selectedCountry['code']}$finalValue';
                    }
                    Navigator.pop(dialogCtx);
                    provider.updateData(context, title, finalValue);
                  } else {
                    setDialogState(() {
                      errorMessage = isPhoneField
                          ? 'Please enter your phone number!'
                          : 'Please enter your name!';
                    });
                  }
                },
                child: const Text('Save',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext parentContext) {
    final theme = Theme.of(parentContext);
    showDialog(
      context: parentContext,
      builder: (dialogCtx) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          elevation: 10,
          backgroundColor: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(25, 50, 25, 25),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                        color: theme.shadowColor.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Logout',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'logoutConfirmMsg'.tr(context),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16,
                          color: theme.textTheme.bodyMedium?.color,
                          height: 1.4),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.dividerColor),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: Text('cancel'.tr(context),
                                style: TextStyle(
                                    color: theme.textTheme.bodyMedium?.color,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD32F2F),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              Navigator.pop(dialogCtx);
                              // Reset navigation to Home (index 0) so on next login it doesn't land on Profile
                              ref.read(navigationProvider).changeIndex(0);
                              await ref
                                  .read(authProvider)
                                  .logout(parentContext);
                            },
                            child: Text('logout'.tr(context),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -32,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.cardColor,
                          spreadRadius: 5,
                          blurRadius: 0,
                        ),
                        BoxShadow(
                          color: const Color(0xFFD32F2F).withValues(alpha: 0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ]),
                  child: const Padding(
                    padding: EdgeInsets.only(
                        left: 4.0), // لضبط تمركز الأيقونة بصرياً
                    child: Icon(Icons.logout_rounded,
                        color: Colors.white, size: 30),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final provider = ref.watch(profileProvider);
        final user = provider.user;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        if (provider.isLoading || user == null) {
          return Scaffold(
            body: Center(
                child:
                    CircularProgressIndicator(color: theme.colorScheme.primary)),
          );
        }

        ImageProvider? getProfileImage() {
          if (user.profileImage != null) {
            return FileImage(user.profileImage!);
          } else if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
            return CachedNetworkImageProvider(user.photoUrl!);
          } else if (user.avatar != null && user.avatar!.isNotEmpty) {
            return CachedNetworkImageProvider(user.avatar!);
          }
          return null;
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none,
                  children: [
                    // Subtle translucent header background
                    Container(
                      height: 155,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.07),
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(40)),
                      ),
                    ),
                    Column(
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).padding.top + 10),
                        Text('Profile',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: theme.colorScheme.primary)),
                        const SizedBox(height: 15),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutBack,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: child,
                            );
                          },
                          child: GestureDetector(
                            onTap: () => provider.pickImage(context),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.scaffoldBackgroundColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                          alpha: isDark ? 0.3 : 0.08),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    )
                                  ]),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 105,
                                    height: 105,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                      border: Border.all(
                                          color: theme.dividerColor.withValues(alpha: 0.15),
                                          width: 1.5),
                                      image: getProfileImage() != null
                                          ? DecorationImage(
                                              image: getProfileImage()!,
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: getProfileImage() == null
                                        ? Icon(Icons.person_rounded,
                                            size: 55,
                                            color: theme.colorScheme.primary)
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: -2,
                                    right: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFF0EA5E9),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: theme.scaffoldBackgroundColor,
                                              width: 3.5),
                                          boxShadow: [
                                            BoxShadow(
                                                color: const Color(0xFF0EA5E9)
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3))
                                          ]),
                                      child: const Icon(
                                          Icons.camera_alt_rounded,
                                          color: Colors.white,
                                          size: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Column(children: [
                  Text(user.name,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text(user.email,
                      style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color)),
                ]),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: Opacity(opacity: value, child: child),
                          );
                        },
                        child: PremiumProfileGroup(
                            title: 'personalInformation'.tr(context),
                            children: [
                              PremiumProfileTile(
                                title: 'profileName'.tr(context),
                                subtitle: user.name,
                                icon: Icons.person_outline_rounded,
                                iconColor: const Color(0xFF0EA5E9),
                                onTap: () => _showEditDialog(
                                    'Name', user.name, provider),
                                trailing: Icon(Icons.edit_rounded,
                                    size: 18,
                                    color: isDark
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade400),
                              ),
                              PremiumProfileTile(
                                title: 'profilePhone'.tr(context),
                                subtitle: user.phone,
                                icon: Icons.phone_in_talk_outlined,
                                iconColor: const Color(0xFF10B981),
                                onTap: () => _showEditDialog(
                                    'Phone', user.phone, provider),
                                trailing: Icon(Icons.edit_rounded,
                                    size: 18,
                                    color: isDark
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade400),
                              ),
                              PremiumProfileTile(
                                title: 'profileEmail'.tr(context),
                                subtitle: user.email,
                                icon: Icons.email_outlined,
                                iconColor: const Color(0xFF8B5CF6),
                                trailing: Icon(Icons.lock_rounded,
                                    size: 16,
                                    color: theme.unselectedWidgetColor),
                                onTap: () {},
                              ),
                            ]),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: Opacity(opacity: value, child: child),
                          );
                        },
                        child:
                            PremiumProfileGroup(title: 'features'.tr(context), children: [
                          PremiumProfileTile(
                            title: 'myOrders'.tr(context),
                            icon: Icons.shopping_bag_outlined,
                            iconColor: const Color(0xFFF59E0B),
                            onTap: () => _navigateTo(const MyOrdersScreen()),
                          ),
                          PremiumProfileTile(
                            title: 'wallet'.tr(context),
                            icon: Icons.account_balance_wallet_outlined,
                            iconColor: const Color(0xFF0EA5E9),
                            onTap: () => _navigateTo(const WalletView()),
                          ),
                          PremiumProfileTile(
                            title: 'familyMembers'.tr(context),
                            icon: Icons.family_restroom_rounded,
                            iconColor: const Color(0xFFF43F5E),
                            onTap: () {},
                          ),
                          PremiumProfileTile(
                            title: 'medicineReminder'.tr(context),
                            icon: Icons.alarm_rounded,
                            iconColor: const Color(0xFF8B5CF6),
                            onTap: () => _navigateTo(const AlarmView()),
                          ),
                        ]),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: Opacity(opacity: value, child: child),
                          );
                        },
                        child: PremiumProfileGroup(
                            title: 'supportSettings'.tr(context),
                            children: [
                              PremiumProfileTile(
                                title: 'language'.tr(context),
                                subtitle: ref.watch(localeProvider).locale.languageCode == 'ar' ? 'العربية' : 'English',
                                icon: Icons.language_rounded,
                                iconColor: const Color(0xFFF59E0B),
                                trailing: const Icon(Icons.sync_alt_rounded, size: 18, color: Colors.grey),
                                onTap: () => ref.read(localeProvider.notifier).toggleLocale(),
                              ),
                              PremiumProfileTile(
                                title: 'helpSupport'.tr(context),
                                icon: Icons.headset_mic_rounded,
                                iconColor: const Color(0xFF10B981),
                                onTap: () => _navigateTo(const SupportScreen()),
                              ),
                              PremiumProfileTile(
                                title: 'aboutUs'.tr(context),
                                icon: Icons.info_outline_rounded,
                                iconColor: const Color(0xFF0EA5E9),
                                onTap: () =>
                                    _navigateTo(const AboutSupportScreen()),
                              ),
                              PremiumProfileTile(
                                title: 'logout'.tr(context),
                                icon: Icons.logout_rounded,
                                iconColor: const Color(0xFFEF4444),
                                isDestructive: true,
                                trailing: const SizedBox(),
                                onTap: () => _showLogoutDialog(context),
                              ),
                            ]),
                      ),
                      const SizedBox(height: 120), // 🚀 زيادة المسافة السفلية عشان البار السفلي ميغطيش على زرار تسجيل الخروج
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
