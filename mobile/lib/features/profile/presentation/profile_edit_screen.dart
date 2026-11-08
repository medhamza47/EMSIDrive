import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/flow_page.dart';
import '../../../shared/widgets/form_section.dart';
import '../../../shared/widgets/primary_button.dart';
import '../application/profile_controller.dart';
import '../domain/student_profile.dart';

String profileFailure(AppLocalizations l, Object error) => switch (error) {
  UnauthorizedFailure() => l.profileSignIn,
  NetworkFailure() || TimeoutFailure() => l.networkErrorMessage,
  _ => l.profileOperationError,
};

class ProfileEditScreen extends ConsumerWidget {
  const ProfileEditScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return ref
        .watch(profileControllerProvider)
        .when(
          data: (profile) =>
              _Editor(key: ValueKey(profile.id), profile: profile),
          loading: () => FlowPage(
            title: l.profileEdit,
            children: const [LinearProgressIndicator()],
          ),
          error: (error, _) => FlowPage(
            title: l.profileEdit,
            children: [
              Text(profileFailure(l, error)),
              TextButton(
                onPressed: () => ref.invalidate(profileControllerProvider),
                child: Text(l.retryLabel),
              ),
            ],
          ),
        );
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({required this.profile, super.key});
  final StudentProfile profile;
  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.fullName);
  late final _phone = TextEditingController(text: widget.profile.phoneNumber);
  late final _major = TextEditingController(text: widget.profile.major);
  late final _year = TextEditingController(text: widget.profile.academicYear);
  late String _campus = widget.profile.preferredCampus ?? '';
  late String _vehicle = widget.profile.preferredVehicle ?? '';
  bool _saving = false;
  Object? _error;
  @override
  void dispose() {
    for (final c in [_name, _phone, _major, _year]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _normalizedPhone => _phone.text.replaceAll(RegExp(r'[\s()-]'), '');
  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final original = widget.profile;
      await ref
          .read(profileControllerProvider.notifier)
          .save(
            StudentProfile(
              id: original.id,
              email: original.email,
              fullName: _name.text.trim(),
              phoneNumber: _normalizedPhone,
              major: _major.text.trim(),
              academicYear: _year.text.trim(),
              photoUrl: original.photoUrl,
              preferredCampus: _campus,
              preferredVehicle: _vehicle,
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).profileSaved)),
        );
        context.pop();
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FlowPage(
      title: l.profileEdit,
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 18,
            children: [
              Text(
                l.profileEditHint,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              FormSection(
                title: l.profilePersonal,
                icon: Icons.person_outline,
                children: [
                  TextFormField(
                    controller: _name,
                    enabled: !_saving,
                    maxLength: 120,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    decoration: InputDecoration(
                      labelText: l.fullNameLabel,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l.profileNameRequired
                        : null,
                  ),
                  TextFormField(
                    initialValue: widget.profile.email,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: l.emailLabel,
                      helperText: l.profileEmailFixed,
                      prefixIcon: const Icon(Icons.alternate_email),
                    ),
                  ),
                  TextFormField(
                    controller: _phone,
                    enabled: !_saving,
                    maxLength: 25,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    decoration: InputDecoration(
                      labelText: l.phoneNumberLabel,
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                    validator: (_) =>
                        _normalizedPhone.isEmpty ||
                            (_normalizedPhone.length <= 20 &&
                                RegExp(r'^\+?[0-9]{9,20}$')
                                    .hasMatch(_normalizedPhone))
                        ? null
                        : l.profilePhoneInvalid,
                  ),
                ],
              ),
              FormSection(
                title: l.profileStudies,
                icon: Icons.school_outlined,
                children: [
                  TextFormField(
                    controller: _major,
                    enabled: !_saving,
                    maxLength: 60,
                    decoration: InputDecoration(
                      labelText: l.profileMajor,
                      hintText: l.profileMajorHint,
                    ),
                  ),
                  TextFormField(
                    controller: _year,
                    enabled: !_saving,
                    maxLength: 20,
                    decoration: InputDecoration(
                      labelText: l.profileYear,
                      hintText: l.profileYearHint,
                    ),
                  ),
                ],
              ),
              FormSection(
                title: l.profilePreferences,
                subtitle: l.profilePreferencesHint,
                icon: Icons.tune_rounded,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _campus,
                    decoration: InputDecoration(labelText: l.profileCampus),
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(l.profileNoPreference),
                      ),
                      DropdownMenuItem(
                        value: 'CENTRE',
                        child: Text(l.campusCentre),
                      ),
                      DropdownMenuItem(
                        value: 'TARGA',
                        child: Text(l.campusTarga),
                      ),
                    ],
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _campus = v!),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _vehicle,
                    decoration: InputDecoration(labelText: l.vehiclePreference),
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(l.profileNoPreference),
                      ),
                      DropdownMenuItem(value: 'CAR', child: Text(l.vehicleCar)),
                      DropdownMenuItem(
                        value: 'MOTO',
                        child: Text(l.vehicleMotorcycle),
                      ),
                      DropdownMenuItem(value: 'ANY', child: Text(l.vehicleAny)),
                    ],
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _vehicle = v!),
                  ),
                ],
              ),
              if (_error != null)
                Text(
                  profileFailure(l, _error!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              PrimaryButton(
                label: l.profileSave,
                icon: Icons.check_rounded,
                isLoading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
