import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state_management/auth_provider.dart';
import 'unauthorized_page.dart';

class RoleGuard extends StatelessWidget {
  final Widget child;
  final String allowedRole;

  const RoleGuard({super.key, required this.child, required this.allowedRole});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final user = authProvider.user;

    if (user == null) {
      return const UnauthorizedPage();
    }

    if (user.role != allowedRole) {
      return const UnauthorizedPage();
    }

    return child;
  }
}
