import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/form_message.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/sheet_frame.dart';
import '../../../data/models/income.dart';

/// Amount (+ optional note) sheet, used for "Add income" and "Set target".
/// [onSave] gets cents and the note; it returns an error message or null.
class AmountSheet extends StatefulWidget {
  const AmountSheet({
    required this.title,
    required this.buttonLabel,
    required this.onSave,
    this.withNote = false,
    this.initialCents,
    super.key,
  });

  final String title;
  final String buttonLabel;
  final bool withNote;
  final int? initialCents;
  final Future<String?> Function(int cents, String note) onSave;

  @override
  State<AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<AmountSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: widget.initialCents == null
        ? ''
        : Money.amount(widget.initialCents! / 100),
  );
  final _note = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final value = Money.parsePositive(_amount.text)!;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSave((value * 100).round(), _note.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      title: widget.title,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _amount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: widget.withNote
                    ? TextInputAction.next
                    : TextInputAction.done,
                onFieldSubmitted: widget.withNote ? null : (_) => _save(),
                validator: (v) => Money.parsePositive(v ?? '') == null
                    ? 'Enter an amount above zero.'
                    : null,
                style: Theme.of(context).textTheme.headlineSmall!
                    .copyWith(fontFeatures: AppTextStyles.tabular),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  suffixText: Money.currency,
                ),
              ),
              if (widget.withNote) ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _note,
                  maxLength: IncomeEntry.maxNote,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    hintText: 'Who paid, for what',
                    counterText: '',
                  ),
                ),
              ],
            ],
          ),
        ),
        FormMessage(message: _error),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: widget.buttonLabel,
          loading: _saving,
          onPressed: _save,
        ),
      ],
    );
  }
}
