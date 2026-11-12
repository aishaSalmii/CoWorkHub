import 'package:flutter/material.dart';

import '../models/member.dart';

/// Form to add a new member, or to edit [member] when it is given.
class MemberFormDialog extends StatefulWidget {
  /// The member to edit. null = add a new member.
  final Member? member;

  const MemberFormDialog({super.key, this.member});

  @override
  State<MemberFormDialog> createState() => _MemberFormDialogState();
}

class _MemberFormDialogState extends State<MemberFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // When editing, the boxes start with the member's current values.
  late final _nameController = TextEditingController(
    text: widget.member?.fullName ?? '',
  );
  late final _emailController = TextEditingController(
    text: widget.member?.email ?? '',
  );
  late final _phoneController = TextEditingController(
    text: widget.member?.phoneNumber ?? '',
  );

  bool get _isEditing => widget.member != null;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.pop(
      context,
      Member(
        id: widget.member?.id,
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit member' : 'Add member'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) {
                    return 'Email is required.';
                  }
                  final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!emailPattern.hasMatch(email)) {
                    return 'Enter a valid email.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone is required.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}