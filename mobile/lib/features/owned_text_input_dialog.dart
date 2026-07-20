import 'package:flutter/material.dart';

typedef OwnedTextInputValidator = String? Function(String value);

class OwnedTextInputDialog extends StatefulWidget {
  const OwnedTextInputDialog({
    required this.title,
    required this.label,
    required this.confirmLabel,
    this.initialValue = '',
    this.inputKey,
    this.confirmKey,
    this.validator,
    this.keyboardType,
    this.maxLength,
    this.maxLines = 1,
    this.trimResult = false,
    super.key,
  });

  final String title;
  final String label;
  final String confirmLabel;
  final String initialValue;
  final Key? inputKey;
  final Key? confirmKey;
  final OwnedTextInputValidator? validator;
  final TextInputType? keyboardType;
  final int? maxLength;
  final int maxLines;
  final bool trimResult;

  @override
  State<OwnedTextInputDialog> createState() => _OwnedTextInputDialogState();
}

class _OwnedTextInputDialogState extends State<OwnedTextInputDialog> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_closing) return;
    final value = _controller.text;
    final error = widget.validator?.call(value);
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }
    _closing = true;
    Navigator.pop(context, widget.trimResult ? value.trim() : value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: widget.inputKey,
        controller: _controller,
        autofocus: true,
        keyboardType: widget.keyboardType,
        maxLength: widget.maxLength,
        maxLines: widget.maxLines,
        decoration: InputDecoration(
          labelText: widget.label,
          errorText: _errorText,
        ),
        onChanged: (_) {
          if (_errorText != null) setState(() => _errorText = null);
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: _closing ? null : () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          key: widget.confirmKey,
          onPressed: _closing ? null : _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
