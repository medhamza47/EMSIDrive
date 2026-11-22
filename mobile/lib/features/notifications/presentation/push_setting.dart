import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/form_section.dart';
import '../application/push_service.dart';

class PushSetting extends ConsumerStatefulWidget {
  const PushSetting({super.key});
  @override
  ConsumerState<PushSetting> createState() => _PushSettingState();
}

class _PushSettingState extends ConsumerState<PushSetting> {
  bool _saving = false;

  Future<void> _toggle(bool value) async {
    setState(() => _saving = true);
    final service = ref.read(pushServiceProvider);
    if (value) {
      await service.synchronize(enable: true);
    } else {
      await service.disable();
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(pushServiceProvider);
    final l = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: service,
      builder: (_, _) => FormSection(
        title: l.pushSettingTitle,
        icon: Icons.notifications_outlined,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.pushSettingEnable),
            subtitle: Text(switch (service.status) {
              PushStatus.unavailable => l.pushSettingUnavailable,
              PushStatus.denied => l.pushSettingDenied,
              PushStatus.error => l.pushSettingError,
              _ => l.pushSettingDescription,
            }),
            value: service.status == PushStatus.enabled,
            onChanged: _saving || service.status == PushStatus.unavailable
                ? null
                : _toggle,
          ),
        ],
      ),
    );
  }
}
