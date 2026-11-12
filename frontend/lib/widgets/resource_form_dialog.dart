import 'package:flutter/material.dart';

import '../models/resource.dart';

/// A dialog with a form to create or edit a resource.
///
/// - To create: pass [resourceType] ('MEETING_ROOM' or 'DESK').
/// - To edit: pass the existing [resource]; its type cannot change.
///
/// Returns the filled-in [Resource] when "Save" is pressed with valid input,
/// or null when the dialog is closed.
class ResourceFormDialog extends StatefulWidget {
  final Resource? resource;
  final String resourceType;

  ResourceFormDialog({super.key, this.resource, String? resourceType})
      : resourceType = resource?.resourceType ?? resourceType ?? 'MEETING_ROOM';

  @override
  State<ResourceFormDialog> createState() => _ResourceFormDialogState();
}

class _ResourceFormDialogState extends State<ResourceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController =
      TextEditingController(text: widget.resource?.name ?? '');
  late final _locationController =
      TextEditingController(text: widget.resource?.location ?? '');
  late final _capacityController =
      TextEditingController(text: '${widget.resource?.capacity ?? 1}');
  late final _rateController = TextEditingController(
      text: widget.resource?.hourlyRate.toStringAsFixed(2) ?? '');

  late String _status = widget.resource?.status ?? 'ACTIVE';
  late bool _hasProjector = widget.resource?.hasProjector ?? false;
  late bool _hasVideoConference = widget.resource?.hasVideoConference ?? false;
  late String _deskType = widget.resource?.deskType ?? 'HOT_DESK';

  bool get _isRoom => widget.resourceType == 'MEETING_ROOM';
  bool get _isEditing => widget.resource != null;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _save() {
    // Check the form before sending anything to the backend.
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Resource(
        id: widget.resource?.id,
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        // A desk is always for one person.
        capacity: _isRoom ? int.parse(_capacityController.text) : 1,
        hourlyRate: double.parse(_rateController.text),
        status: _status,
        resourceType: widget.resourceType,
        hasProjector: _isRoom ? _hasProjector : null,
        hasVideoConference: _isRoom ? _hasVideoConference : null,
        deskType: _isRoom ? null : _deskType,
      ),
    );
  }

  String? _required(String? value, String field) =>
      (value == null || value.trim().isEmpty) ? '$field is required.' : null;

  @override
  Widget build(BuildContext context) {
    final typeName = _isRoom ? 'meeting room' : 'desk';
    return AlertDialog(
      title: Text(_isEditing ? 'Edit $typeName' : 'New $typeName'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: 'Name', border: OutlineInputBorder()),
                  validator: (value) => _required(value, 'Name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                      labelText: 'Location', border: OutlineInputBorder()),
                  validator: (value) => _required(value, 'Location'),
                ),
                const SizedBox(height: 12),
                if (_isRoom) ...[
                  TextFormField(
                    controller: _capacityController,
                    decoration: const InputDecoration(
                        labelText: 'Capacity', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final number = int.tryParse(value ?? '');
                      if (number == null || number < 1) {
                        return 'Capacity must be a whole number of at least 1.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _rateController,
                  decoration: const InputDecoration(
                      labelText: 'Hourly rate (QAR)',
                      border: OutlineInputBorder()),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    final number = double.tryParse(value ?? '');
                    if (number == null || number <= 0) {
                      return 'Hourly rate must be a number greater than 0.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: 'Status', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                    DropdownMenuItem(
                        value: 'OUT_OF_SERVICE', child: Text('Out of service')),
                  ],
                  onChanged: (value) => setState(() => _status = value!),
                ),
                const SizedBox(height: 12),
                if (_isRoom) ...[
                  SwitchListTile(
                    title: const Text('Projector'),
                    value: _hasProjector,
                    onChanged: (value) => setState(() => _hasProjector = value),
                  ),
                  SwitchListTile(
                    title: const Text('Video conference'),
                    value: _hasVideoConference,
                    onChanged: (value) =>
                        setState(() => _hasVideoConference = value),
                  ),
                ] else
                  DropdownButtonFormField<String>(
                    initialValue: _deskType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                        labelText: 'Desk type', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'HOT_DESK', child: Text('Hot desk')),
                      DropdownMenuItem(
                          value: 'DEDICATED_DESK', child: Text('Dedicated desk')),
                      DropdownMenuItem(
                          value: 'STANDING_DESK', child: Text('Standing desk')),
                    ],
                    onChanged: (value) => setState(() => _deskType = value!),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}