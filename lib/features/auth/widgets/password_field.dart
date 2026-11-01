import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Password input with a show/hide toggle and autofill support.
class PasswordField extends StatefulWidget {
  const PasswordField({
    required this.controller,
    required this.validator,
    required this.isNewPassword,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final FormFieldValidator<String> validator;

  /// Sign-up uses the "new password" autofill hint so password managers
  /// offer to save it.
  final bool isNewPassword;
  final VoidCallback? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      obscureText: !_visible,
      enableSuggestions: false,
      autocorrect: false,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      autofillHints: [
        if (widget.isNewPassword)
          AutofillHints.newPassword
        else
          AutofillHints.password,
      ],
      onFieldSubmitted: (_) => widget.onSubmitted?.call(),
      decoration: InputDecoration(
        labelText: 'Password',
        helperText: widget.isNewPassword ? 'At least 8 characters' : null,
        suffixIcon: IconButton(
          onPressed: () => setState(() => _visible = !_visible),
          tooltip: _visible ? 'Hide password' : 'Show password',
          icon: Icon(_visible ? Symbols.visibility_off : Symbols.visibility),
        ),
      ),
    );
  }
}
