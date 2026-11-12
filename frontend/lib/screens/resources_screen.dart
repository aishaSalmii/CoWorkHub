import 'package:flutter/material.dart';

import '../models/resource.dart';
import '../services/api_service.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/resource_form_dialog.dart';

/// Lists resources with filters, shows details, and lets users
/// create, edit and delete meeting rooms and desks.
class ResourcesScreen extends StatefulWidget {
  /// [api] can be replaced in tests; normally a real ApiService is used.
  final ApiService? api;

  const ResourcesScreen({super.key, this.api});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  late final ApiService _api = widget.api ?? ApiService();

  List<Resource> _resources = [];
  bool _loading = true;
  String? _error;

  // Filters
  String? _typeFilter; // null = all, 'MEETING_ROOM' or 'DESK'
  final _minCapacityController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  @override
  void dispose() {
    _minCapacityController.dispose();
    _locationController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadResources() async {
    // Read the filters; empty boxes mean "no filter".
    final minCapacityText = _minCapacityController.text.trim();
    final maxPriceText = _maxPriceController.text.trim();
    final minCapacity =
        minCapacityText.isEmpty ? null : int.tryParse(minCapacityText);
    final maxPrice = maxPriceText.isEmpty ? null : double.tryParse(maxPriceText);
    if ((minCapacityText.isNotEmpty && minCapacity == null) ||
        (maxPriceText.isNotEmpty && maxPrice == null)) {
      showMessage(context, 'Minimum capacity and maximum price must be numbers.',
          isError: true);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resources = await _api.getResources(
        type: _typeFilter,
        minCapacity: minCapacity,
        location: _locationController.text.trim(),
        maxPrice: maxPrice,
      );
      setState(() => _resources = resources);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _clearFilters() {
    setState(() => _typeFilter = null);
    _minCapacityController.clear();
    _locationController.clear();
    _maxPriceController.clear();
    _loadResources();
  }

  /// Opens the form. [existing] = edit; otherwise create a [newType].
  Future<void> _openForm({Resource? existing, String? newType}) async {
    final result = await showDialog<Resource>(
      context: context,
      builder: (context) =>
          ResourceFormDialog(resource: existing, resourceType: newType),
    );
    if (result == null) return; // the user closed the dialog

    try {
      final saved = existing == null
          ? await _api.createResource(result)
          : await _api.updateResource(existing.id!, result);
      if (!mounted) return;
      showMessage(context,
          '${saved.name} ${existing == null ? 'created' : 'updated'}.');
      await _loadResources(); // refresh the list
    } on ApiException catch (e) {
      if (!mounted) return;
      showMessage(context, e.message, isError: true);
    }
  }

  Future<void> _delete(Resource resource) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete resource?'),
        content: Text('Delete ${resource.name}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _api.deleteResource(resource.id!);
      if (!mounted) return;
      showMessage(context, '${resource.name} deleted.');
      await _loadResources(); // refresh the list
    } on ApiException catch (e) {
      // e.g. 409: "Resource '...' has bookings and cannot be deleted.
      //            Set its status to OUT_OF_SERVICE instead."
      if (!mounted) return;
      showMessage(context, e.message, isError: true);
    }
  }

  void _showDetails(Resource resource) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(resource.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detail('Type', resource.isMeetingRoom ? 'Meeting room' : 'Desk'),
            _detail('Location', resource.location),
            _detail('Capacity', '${resource.capacity}'),
            _detail('Hourly rate', '${resource.hourlyRate.toStringAsFixed(2)} QAR'),
            _detail('Status', resource.isActive ? 'Active' : 'Out of service'),
            if (resource.isMeetingRoom) ...[
              _detail('Projector', resource.hasProjector == true ? 'Yes' : 'No'),
              _detail('Video conference',
                  resource.hasVideoConference == true ? 'Yes' : 'No'),
            ] else
              _detail('Desk type', _deskTypeName(resource.deskType)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text('$label: $value'),
    );
  }

  String _deskTypeName(String? deskType) {
    switch (deskType) {
      case 'DEDICATED_DESK':
        return 'Dedicated desk';
      case 'STANDING_DESK':
        return 'Standing desk';
      default:
        return 'Hot desk';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToolbar(),
        _buildFilters(),
        const Divider(height: 1),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: () => _openForm(newType: 'MEETING_ROOM'),
            icon: const Icon(Icons.meeting_room),
            label: const Text('Add meeting room'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => _openForm(newType: 'DESK'),
            icon: const Icon(Icons.desk),
            label: const Text('Add desk'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SegmentedButton<String?>(
            segments: const [
              ButtonSegment(value: null, label: Text('All')),
              ButtonSegment(value: 'MEETING_ROOM', label: Text('Rooms')),
              ButtonSegment(value: 'DESK', label: Text('Desks')),
            ],
            selected: {_typeFilter},
            onSelectionChanged: (selection) {
              setState(() => _typeFilter = selection.first);
              _loadResources();
            },
          ),
          SizedBox(
            width: 140,
            child: TextField(
              controller: _minCapacityController,
              decoration: const InputDecoration(
                  labelText: 'Min capacity', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(
            width: 180,
            child: TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                  labelText: 'Location', border: OutlineInputBorder()),
            ),
          ),
          SizedBox(
            width: 140,
            child: TextField(
              controller: _maxPriceController,
              decoration: const InputDecoration(
                  labelText: 'Max price', border: OutlineInputBorder()),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          FilledButton.icon(
            onPressed: _loadResources,
            icon: const Icon(Icons.filter_alt),
            label: const Text('Apply filters'),
          ),
          TextButton(onPressed: _clearFilters, child: const Text('Clear')),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) return const LoadingView(message: 'Loading resources...');
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _loadResources);
    }
    if (_resources.isEmpty) {
      return const Center(child: Text('No resources match the filters.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final resource in _resources)
          Card(
            child: ListTile(
              leading: Icon(
                  resource.isMeetingRoom ? Icons.meeting_room : Icons.desk),
              title: Text(resource.name),
              subtitle: Text(
                  '${resource.isMeetingRoom ? 'Meeting room' : 'Desk'} • '
                  '${resource.location} • capacity ${resource.capacity} • '
                  '${resource.hourlyRate.toStringAsFixed(2)} QAR/hour'),
              onTap: () => _showDetails(resource),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Chip(
                    label: Text(resource.isActive ? 'Active' : 'Out of service'),
                    backgroundColor: resource.isActive
                        ? Colors.green.shade100
                        : Colors.grey.shade300,
                  ),
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: () => _openForm(existing: resource),
                    icon: const Icon(Icons.edit),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: () => _delete(resource),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}