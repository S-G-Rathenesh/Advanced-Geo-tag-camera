import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'officer_dashboard.dart';
import 'supervisor_dashboard.dart';
import 'user_dashboard.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not Authenticated')));
    }

    switch (user.role) {
      case UserRole.officer:
        return const OfficerDashboard();
      case UserRole.supervisor:
        return const SupervisorDashboard();
      case UserRole.user:
        return const UserDashboard();
    }
  }
}
