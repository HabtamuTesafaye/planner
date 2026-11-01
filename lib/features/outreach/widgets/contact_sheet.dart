import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/form_message.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/sheet_frame.dart';
import '../../../data/app_exception.dart';
import '../../../data/models/contact.dart';
import '../../../data/repositories/contacts_repository.dart';
import '../../auth/providers/auth_providers.dart';
import 'status_sheet.dart';

/// Add or edit a lead. Only the name is required, so adding takes seconds.
class ContactSheet extends ConsumerStatefulWidget {
  const ContactSheet({
    required this.spaceId,
    required this.today,
    this.existing,
    super.key,
  });

  final String spaceId;
  final DateTime today;
  final Contact? existing;

  @override
  ConsumerState<ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends ConsumerState<ContactSheet> {
  final _formKey = GlobalKey<FormState>();
  late final Contact? _c = widget.existing;
  late final _name = TextEditingController(text: _c?.name);
  late final _business = TextEditingController(text: _c?.business);
  late final _channel = TextEditingController(text: _c?.channel);
  late final _price = TextEditingController(
    text: _c?.price == null ? '' : Money.amount(_c!.price!),
  );
  late final _notes = TextEditingController(text: _c?.notes);
  late ContactStatus _status = _c?.status ?? ContactStatus.contacted;
  // New leads: follow up in three days unless changed.
  late DateTime? _followUp = _c == null
      ? widget.today.add(const Duration(days: 3))
      : _c.nextFollowUp;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _business, _channel, _price, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final now = DateTime.now();
    final contact = Contact(
      id: _c?.id ?? newUuid(),
      spaceId: widget.spaceId,
      ownerId: _c?.ownerId ?? ref.read(currentUserIdProvider).value,
      name: _name.text,
      business: _business.text,
      channel: _channel.text,
      status: _status,
      nextFollowUp: _followUp,
      price: _price.text.trim().isEmpty
          ? null
          : Money.parsePositive(_price.text),
      notes: _notes.text,
      createdAt: _c?.createdAt ?? now,
      updatedAt: now,
    );
    final repo = ref.read(contactsRepositoryProvider);
    try {
      await (_c == null ? repo.add(contact) : repo.update(contact));
      if (mounted) Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final d = await pickFollowUp(
      context,
      today: widget.today,
      initial: _followUp,
    );
    if (d != null) setState(() => _followUp = d);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SheetFrame(
      title: _c == null ? 'New contact' : 'Edit contact',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                autofocus: _c == null,
                maxLength: Contact.maxName,
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v?.trim() ?? '').isEmpty
                    ? 'Who did you reach out to?'
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _business,
                maxLength: Contact.maxBusiness,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Business',
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final s in ContactStatus.values)
                    ChoiceChip(
                      label: Text(s.label),
                      selected: s == _status,
                      onSelected: (_) => setState(() => _status = s),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Symbols.event),
                label: Text(
                  _followUp == null
                      ? 'No follow-up date'
                      : 'Follow up ${DateFormat.MMMEd().format(_followUp!)}',
                ),
              ),
              if (_followUp != null)
                TextButton(
                  onPressed: () => setState(() => _followUp = null),
                  style: TextButton.styleFrom(foregroundColor: colors.muted),
                  child: const Text('Clear date'),
                ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _channel,
                maxLength: Contact.maxChannel,
                decoration: const InputDecoration(
                  labelText: 'Channel',
                  hintText: 'Phone, WhatsApp, Telegram…',
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) =>
                    (v?.trim() ?? '').isEmpty || Money.parsePositive(v!) != null
                    ? null
                    : 'Enter an amount above zero.',
                decoration: const InputDecoration(
                  labelText: 'Price (optional)',
                  suffixText: Money.currency,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _notes,
                maxLength: Contact.maxNotes,
                minLines: 2,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  counterText: '',
                ),
              ),
            ],
          ),
        ),
        FormMessage(message: _error),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(label: 'Save', loading: _saving, onPressed: _save),
      ],
    );
  }
}
