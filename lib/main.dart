import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/viewmodels/auth_viewmodel.dart';
import 'features/auth/views/splash_screen.dart';


import 'features/bengkel/viewmodels/bengkel_dashboard_viewmodel.dart';
import 'features/bengkel/viewmodels/bengkel_inventory_viewmodel.dart';
import 'features/bengkel/viewmodels/bengkel_orders_viewmodel.dart';
import 'features/bengkel/viewmodels/bengkel_mechanic_viewmodel.dart';
import 'features/bengkel/viewmodels/bengkel_manage_service_viewmodel.dart';
import 'features/bengkel/viewmodels/bengkel_booking_viewmodel.dart';
import 'features/customer/viewmodels/customer_dashboard_viewmodel.dart';
import 'features/customer/viewmodels/customer_profile_viewmodel.dart';
import 'features/customer/viewmodels/customer_marketplace_viewmodel.dart';
import 'features/customer/viewmodels/customer_booking_viewmodel.dart';
import 'features/customer/viewmodels/notification_viewmodel.dart';
import 'features/customer/viewmodels/bengkel_service_viewmodel.dart';
import 'features/customer/viewmodels/workshop_report_viewmodel.dart';
import 'features/admin/viewmodels/admin_config_viewmodel.dart';
import 'features/mekanik/viewmodels/mekanik_dashboard_viewmodel.dart';
import 'core/viewmodels/chat_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('FlutterError: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  await Supabase.initialize(
    url: 'https://xowudhicrbgjcplvkqnb.supabase.co',
    anonKey: 'sb_publishable__vbOvduayzWwqbeCY7a87Q_bzVVlXXo',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => CustomerDashboardViewModel()),
        ChangeNotifierProvider(create: (_) => CustomerProfileViewModel()),
        ChangeNotifierProvider(create: (_) => CustomerMarketplaceViewModel()),
        ChangeNotifierProvider(create: (_) => CustomerBookingViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ChangeNotifierProvider(create: (_) => BengkelDashboardViewModel()),
        ChangeNotifierProvider(create: (_) => BengkelInventoryViewModel()),
        ChangeNotifierProvider(create: (_) => BengkelOrdersViewModel()),
        ChangeNotifierProvider(create: (_) => BengkelMechanicViewModel()),
        ChangeNotifierProvider(create: (_) => BengkelServiceViewModel()),
        ChangeNotifierProvider(create: (_) => BengkelManageServiceViewModel()),
        ChangeNotifierProvider(create: (_) => BengkelBookingViewModel()),
        ChangeNotifierProvider(create: (_) => AdminConfigViewModel()),
        ChangeNotifierProvider(create: (_) => MekanikDashboardViewModel()),
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
        ChangeNotifierProvider(create: (_) => WorkshopReportViewModel()),
      ],
      child: const BengkelinApp(),
    ),
  );
}

class BengkelinApp extends StatelessWidget {
  const BengkelinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bengkelin App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
      ),
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: Builder(
          builder: (context) {
            return ResponsiveScaledBox(
              width: ResponsiveValue<double>(
                context,
                conditionalValues: [
                  Condition.equals(name: MOBILE, value: 390),
                  Condition.equals(name: TABLET, value: 800),
                  Condition.equals(name: DESKTOP, value: 1200),
                ],
                defaultValue: 390,
              ).value,
              child: child!,
            );
          },
        ),
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
        ],
      ),
      home: const SplashScreen(),
    );
  }
}
