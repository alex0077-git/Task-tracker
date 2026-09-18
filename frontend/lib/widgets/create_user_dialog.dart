import 'package:flutter/material.dart';

import '../services/api_service.dart';

/// Shared create-user / add-employee dialog.
/// Layout differences (title, width, confirm button style) are parameters only.
class CreateUserDialog extends StatefulWidget {
  const CreateUserDialog({
    super.key,
    this.title = 'Create user',
    this.contentWidth,
    this.useFilledConfirm = false,
    this.filledConfirmColor,
  });

  final String title;
  final double? contentWidth;
  final bool useFilledConfirm;
  final Color? filledConfirmColor;

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isStaff = false;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Username and password are required';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final error = await ApiService.instance.createUser(
      username: username,
      password: password,
      isStaff: _isStaff,
    );
    if (!mounted) {
      return;
    }
    if (error == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _isSaving = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fields = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _usernameController,
          enabled: !_isSaving,
          decoration: const InputDecoration(labelText: 'Username'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          enabled: !_isSaving,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Admin / Manager'),
          value: _isStaff,
          onChanged: _isSaving
              ? null
              : (value) {
                  setState(() {
                    _isStaff = value;
                  });
                },
        ),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );

    final confirmChild = _isSaving
        ? const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Text('Create');

    final confirmButton = widget.useFilledConfirm
        ? FilledButton(
            onPressed: _isSaving ? null : _save,
            style: widget.filledConfirmColor == null
                ? null
                : FilledButton.styleFrom(
                    backgroundColor: widget.filledConfirmColor,
                  ),
            child: confirmChild,
          )
        : TextButton(
            onPressed: _isSaving ? null : _save,
            child: confirmChild,
          );

    return AlertDialog(
      title: Text(widget.title),
      content: widget.contentWidth == null
          ? fields
          : SizedBox(width: widget.contentWidth, child: fields),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        confirmButton,
      ],
    );
  }
}
