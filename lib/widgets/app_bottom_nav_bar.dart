import 'package:flutter/material.dart';

import '../core/constants/app_routes.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == currentIndex) return;
        
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
            break;
          case 1:
            Navigator.pushNamed(context, AppRoutes.secureCamera);
            break;
          case 2:
            Navigator.pushReplacementNamed(context, AppRoutes.myEvidence);
            break;
          case 3:
            Navigator.pushReplacementNamed(context, AppRoutes.profile);
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.camera_alt_rounded),
          label: 'Capture',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.folder_rounded),
          label: 'Evidence',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}
