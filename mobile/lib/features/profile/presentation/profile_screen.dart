import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/flow_page.dart';
import '../../../shared/widgets/outline_button.dart';
import '../../auth/data/auth_repository_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _signingOut = false;

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await ref.read(authRepositoryProvider).signOut();
    } on Exception {
      if (!mounted) return;
      setState(() => _signingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).signOutError)),
      );
      return;
    }
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FlowPage(
      title: l.navProfile,
      children: [
        AppCard(
          leading: const Icon(Icons.school_outlined),
          child: FlowCopy(l.appName, l.demoCampus),
        ),
        OutlineButton(
          label: l.signOutLabel,
          icon: Icons.logout,
          onPressed: _signingOut ? null : _signOut,
        ),
      ],
    );
  }
}
