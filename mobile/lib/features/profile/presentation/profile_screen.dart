import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/flow_page.dart';
import '../../../shared/widgets/outline_button.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/form_section.dart';
import '../application/profile_controller.dart';
import 'profile_edit_screen.dart';
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
        ref
            .watch(profileControllerProvider)
            .when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profileFailure(l, error)),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(profileControllerProvider),
                      child: Text(l.retryLabel),
                    ),
                  ],
                ),
              ),
              data: (profile) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 18,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        spacing: 10,
                        children: [
                          Avatar.xl(
                            name: profile.fullName,
                            imageUrl: profile.photoUrl,
                            showBorder: false,
                          ),
                          Text(
                            profile.fullName,
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            profile.email,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          if (profile.major?.isNotEmpty ?? false)
                            Chip(label: Text(profile.major!)),
                        ],
                      ),
                    ),
                  ),
                  PrimaryButton(
                    label: l.profileEdit,
                    icon: Icons.edit_outlined,
                    onPressed: () => context.push(AppRoutes.profileEdit),
                  ),
                  FormSection(
                    title: l.profilePersonal,
                    icon: Icons.person_outline,
                    children: [
                      _ProfileValue(
                        icon: Icons.phone_outlined,
                        label: l.phoneNumberLabel,
                        value: profile.phoneNumber ?? l.profileNotSet,
                      ),
                      _ProfileValue(
                        icon: Icons.school_outlined,
                        label: l.profileMajor,
                        value: profile.major ?? l.profileNotSet,
                      ),
                      _ProfileValue(
                        icon: Icons.calendar_today_outlined,
                        label: l.profileYear,
                        value: profile.academicYear ?? l.profileNotSet,
                      ),
                    ],
                  ),
                  FormSection(
                    title: l.profilePreferences,
                    icon: Icons.tune_rounded,
                    children: [
                      _ProfileValue(
                        icon: Icons.location_on_outlined,
                        label: l.profileCampus,
                        value: switch (profile.preferredCampus) {
                          'TARGA' => l.campusTarga,
                          'CENTRE' => l.campusCentre,
                          _ => l.profileNoPreference,
                        },
                      ),
                      _ProfileValue(
                        icon: Icons.directions_car_outlined,
                        label: l.vehiclePreference,
                        value: switch (profile.preferredVehicle) {
                          'MOTO' => l.vehicleMotorcycle,
                          'CAR' => l.vehicleCar,
                          'ANY' => l.vehicleAny,
                          _ => l.profileNoPreference,
                        },
                      ),
                    ],
                  ),
                ],
              ),
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

class _ProfileValue extends StatelessWidget {
  const _ProfileValue({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        icon,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    ],
  );
}
