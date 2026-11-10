import 'package:flutter/material.dart';

import '../models/member.dart';
import '../models/resource.dart';
import '../services/api_service.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';

/// Search availability and create a booking.
///
/// 1. The user picks a date, a start time and an end time.
/// 2. "Check availability" shows ALL active resources, each marked
///    "Available" or "Booked". (The backend decides; Flutter only displays.)
/// 3. The user chooses a resource, a member and the number of attendees.
/// 4. "Book now" sends the booking. The backend checks every rule:
///    an invalid booking (e.g. overlapping) shows the backend's message.
class NewBookingScreen extends StatefulWidget {
  /// [api] can be replaced in tests; normally a real ApiService is used.
  final ApiService? api;

  const NewBookingScreen({super.key, this.api});

  @override
  State<NewBookingScreen> createState() => _NewBookingScreenState();
}

class _NewBookingScreenState extends State<NewBookingScreen> {
  late final ApiService _api = widget.api ?? ApiService();
  final _formKey = GlobalKey<FormState>();
  final _attendeesController = TextEditingController(text: '1');

  // Step 1: when
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  String? _typeFilter; // null = all types, 'MEETING_ROOM' or 'DESK'

  // Members (loaded when the screen opens)
  List<Member> _members = [];
  bool _loadingMembers = true;
  String? _membersError;

  // Step 2: search results
  List<Resource>? _resources; // null = no search yet
  Set<int> _availableIds = {};
  bool _searching = false;
  String? _searchError;

  // Step 3: booking details
  Resource? _selectedResource;
  Member? _selectedMember;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _attendeesController.dispose();
    super.dispose();
  }

  DateTime get _start => DateTime(_date.year, _date.month, _date.day,
      _startTime.hour, _startTime.minute);

  DateTime get _end => DateTime(
      _date.year, _date.month, _date.day, _endTime.hour, _endTime.minute);

  Future<void> _loadMembers() async {
    setState(() {
      _loadingMembers = true;
      _membersError = null;
    });
      try {
      final members = await _api.getMembers();
      if (!mounted) return;
      setState(() => _members = members);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _membersError = e.message);
    } finally {
      if (mounted) setState(() => _loadingMembers = false);
    }
  }

  /// Loads all active resources and marks which ones are free.
  Future<void> _checkAvailability() async {
    // Obvious mistake: check it here before calling the backend.
    if (!_start.isBefore(_end)) {
      showMessage(context, 'The end time must be after the start time.',
          isError: true);
      return;
    }

    setState(() {
      _searching = true;
      _searchError = null;
      _selectedResource = null;
    });
    try {
      final all = await _api.getResources(type: _typeFilter);
            final available = await _api.getAvailableResources(
          start: _start, end: _end, type: _typeFilter);
      if (!mounted) return;
      setState(() {
        _resources = all.where((r) => r.isActive).toList();
        _availableIds = available.map((r) => r.id!).toSet();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _searchError = e.message);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedResource == null) {
      showMessage(context, 'Please choose a resource.', isError: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final booking = await _api.createBooking(
        memberId: _selectedMember!.id!,
        resourceId: _selectedResource!.id!,
        start: _start,
        end: _end,
        attendees: int.parse(_attendeesController.text),
      );
      if (!mounted) return;
      showMessage(context,
          'Booking confirmed: ${booking.resource.name}, total cost ${booking.totalCost.toStringAsFixed(2)} QAR');
      // Refresh the list so the booked resource now shows "Booked".
      await _checkAvailability();
    } on ApiException catch (e) {
      // e.g. 409: "'Boardroom' is already booked during the selected time."
      if (!mounted) return;
      showMessage(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingMembers) return const LoadingView(message: 'Loading members...');
    if (_membersError != null) {
      return ErrorView(message: _membersError!, onRetry: _loadMembers);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWhenSection(),
            const SizedBox(height: 24),
            _buildResultsSection(),
            if (_selectedResource != null) ...[
              const SizedBox(height: 24),
              _buildDetailsSection(),
            ],
          ],
        ),
      ),
    );
  }

  /// Step 1: date, times and type.
  Widget _buildWhenSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('1. When?', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(_formatDate(_date)),
            ),
            OutlinedButton.icon(
              onPressed: () => _pickTime(isStart: true),
              icon: const Icon(Icons.schedule),
              label: Text('From ${_startTime.format(context)}'),
            ),
            OutlinedButton.icon(
              onPressed: () => _pickTime(isStart: false),
              icon: const Icon(Icons.schedule),
              label: Text('To ${_endTime.format(context)}'),
            ),
            SegmentedButton<String?>(
              segments: const [
                ButtonSegment(value: null, label: Text('All')),
                ButtonSegment(value: 'MEETING_ROOM', label: Text('Rooms')),
                ButtonSegment(value: 'DESK', label: Text('Desks')),
              ],
              selected: {_typeFilter},
              onSelectionChanged: (selection) {
                setState(() => _typeFilter = selection.first);
              },
            ),
            FilledButton.icon(
              onPressed: _searching ? null : _checkAvailability,
              icon: const Icon(Icons.search),
              label: const Text('Check availability'),
            ),
          ],
        ),
      ],
    );
  }

  /// Step 2: all active resources, marked Available or Booked.
  Widget _buildResultsSection() {
    if (_searching) return const LoadingView(message: 'Checking availability...');
    if (_searchError != null) {
      return ErrorView(message: _searchError!, onRetry: _checkAvailability);
    }
    final resources = _resources;
    if (resources == null) {
      return const Text('Choose a date and times, then click "Check availability".');
    }
    if (resources.isEmpty) {
      return const Text('No active resources found.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('2. Choose a resource',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final resource in resources) _buildResourceTile(resource),
      ],
    );
  }

  Widget _buildResourceTile(Resource resource) {
    final isAvailable = _availableIds.contains(resource.id);
    final isSelected = _selectedResource?.id == resource.id;
    return Card(
      child: ListTile(
        selected: isSelected,
        // The selected resource shows a check mark instead of its type icon.
        leading: Icon(isSelected
            ? Icons.check_circle
            : (resource.isMeetingRoom ? Icons.meeting_room : Icons.desk)),
        title: Text(resource.name),
        subtitle: Text(
            '${resource.isMeetingRoom ? 'Meeting room' : 'Desk'} • ${resource.location} • '
            'capacity ${resource.capacity} • ${resource.hourlyRate.toStringAsFixed(2)} QAR/hour'),
        trailing: Chip(
          label: Text(isAvailable ? 'Available' : 'Booked'),
          backgroundColor:
              isAvailable ? Colors.green.shade100 : Colors.orange.shade100,
        ),
        onTap: () => setState(() => _selectedResource = resource),
      ),
    );
  }

  /// Step 3: member and attendees, then "Book now".
  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('3. Booking details',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        SizedBox(
          width: 400,
          child: DropdownButtonFormField<Member>(
            initialValue: _selectedMember,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Member',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final member in _members)
                DropdownMenuItem(
                  value: member,
                  child: Text('${member.fullName} (${member.email})'),
                ),
            ],
            onChanged: (member) => setState(() => _selectedMember = member),
            validator: (member) =>
                member == null ? 'Please choose a member.' : null,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 200,
          child: TextFormField(
            controller: _attendeesController,
            decoration: const InputDecoration(
              labelText: 'Attendees',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              final number = int.tryParse(value ?? '');
              if (number == null || number < 1) {
                return 'Enter a number of at least 1.';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text('Book ${_selectedResource!.name}'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }
}