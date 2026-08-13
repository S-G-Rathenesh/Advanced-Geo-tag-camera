import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_routes.dart';
import 'core/constants/app_theme.dart';

import 'features/authentication/login_screen.dart';
import 'features/authentication/splash_screen.dart';
import 'features/camera/capture_confirmation_screen.dart';
import 'features/camera/secure_camera_screen.dart';
import 'features/dashboard/role_router.dart';
import 'features/evidence/evidence_details_screen.dart';
import 'features/evidence/my_evidence_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/synchronization/sync_status_screen.dart';

import 'services/auth_service.dart';
import 'services/evidence_service.dart';
import 'services/sync_service.dart';
import 'services/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GeoEvidenceApp());
}

class GeoEvidenceApp extends StatelessWidget {
  const GeoEvidenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => EvidenceService()),
        ChangeNotifierProvider(create: (_) => SyncService()),
        Provider(create: (_) => ApiService()),
      ],
      child: MaterialApp(
        title: 'GeoEvidence',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.dashboard: (_) => const RoleRouter(),
          AppRoutes.secureCamera: (_) => const SecureCameraScreen(),
          AppRoutes.captureConfirmation: (_) =>
              const CaptureConfirmationScreen(),
          AppRoutes.syncStatus: (_) => const SyncStatusScreen(),
          AppRoutes.myEvidence: (_) => const MyEvidenceScreen(),
          AppRoutes.evidenceDetails: (_) => const EvidenceDetailsScreen(),
          AppRoutes.profile: (_) => const ProfileScreen(),
        },
      ),
    );
  }
}
