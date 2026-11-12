import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
enum _Filter { current, past, all }
class BookingsScreen extends StatefulWidget {
  final ApiService? api;
  const BookingsScreen({
    super.key,
    this.api,
  });
  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}
class _BookingsScreenState extends State<BookingsScreen> {
  late final ApiService _api;
  List<Booking> _bookings = [];
  _Filter _filter = _Filter.current;
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _api = widget.api ?? ApiService();
    _loadBookings();
  }
  Future<void> _loadBookings() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bookings = await _api.getBookings();
      bookings.sort(
        (a, b) => b.startDateTime.compareTo(a.startDateTime),
      );
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }
  List<Booking> get _visibleBookings {
    switch (_filter) {
      case _Filter.current:
        return _bookings.where((booking) => !booking.isPast).toList();
      case _Filter.past:
        return _bookings.where((booking) => booking.isPast).toList();
      case _Filter.all:
        return _bookings;
    }
  }
  Future<void> _cancel(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel booking?'),
          content: const Text(
            'Are you sure you want to cancel this booking?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Keep booking'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Cancel booking'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    try {
      await _api.cancelBooking(booking.id);
      if (!mounted) return;
      showMessage(
        context,
        'Booking cancelled.',
      );
      await _loadBookings();
    } catch (e) {
      if (!mounted) return;
      showMessage(
        context,
        e.toString(),
        isError: true,
      );
    }
  }
  Future<void> _edit(Booking booking) async {
    final change = await showDialog<_BookingChange>(
      context: context,
      builder: (context) {
        return _EditBookingDialog(
          booking: booking,
        );
      },
    );
    if (change == null) return;
    try {
      final updated = await _api.updateBooking(
        bookingId: booking.id,
        memberId: booking.member.id!,
        resourceId: booking.resource.id!,
        start: change.start,
        end: change.end,
        attendees: change.attendees,
      );
      if (!mounted) return;
      showMessage(
        context,
        'Booking updated. New total cost: ${updated.totalCost}',
      );
      await _loadBookings();
    } catch (e) {
      if (!mounted) return;
      showMessage(
        context,
        e.toString(),
        isError: true,
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<_Filter>(
            segments: const [
              ButtonSegment<_Filter>(
                value: _Filter.current,
                label: Text('Current'),
              ),
              ButtonSegment<_Filter>(
                value: _Filter.past,
                label: Text('Past'),
              ),
              ButtonSegment<_Filter>(
                value: _Filter.all,
                label: Text('All'),
              ),
            ],
            selected: {_filter},
            onSelectionChanged: (selection) {
              setState(() {
                _filter = selection.first;
              });
            },
          ),
        ),
        Expanded(
          child: _buildBody(),
        ),
      ],
    );
  }
  Widget _buildBody() {
    if (_loading) {
      return const LoadingView(
        message: 'Loading bookings...',
      );
    }
    if (_error != null) {
      return ErrorView(
        message: _error!,
        onRetry: _loadBookings,
      );
    }
    final bookings = _visibleBookings;
    if (bookings.isEmpty) {
      return const Center(
        child: Text('No bookings found.'),
      );
    }
    return ListView.builder(
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final canChange =
            !booking.isCancelled && !booking.isPast;
        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking #${booking.id}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Member: ${booking.member.fullName}',
                ),
                Text(
                  'Resource: ${booking.resource.name}',
                ),
                Text(
                  'Start: ${booking.startDateTime}',
                ),
                Text(
                  'End: ${booking.endDateTime}',
                ),
                Text(
                  'Attendees: ${booking.attendees}',
                ),
                Text(
                  'Total cost: ${booking.totalCost}',
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(booking.status),
                  backgroundColor: booking.isCancelled
                      ? Colors.grey.shade300
                      : Colors.green.shade100,
                ),
                if (canChange) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: () => _edit(booking),
                        icon: const Icon(Icons.edit),
                        label: const Text('Change'),
                      ),
                      TextButton.icon(
                        onPressed: () => _cancel(booking),
                        icon: const Icon(Icons.cancel),
                        label: const Text('Cancel'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
class _BookingChange {
  final DateTime start;
  final DateTime end;
  final int attendees;
  const _BookingChange({
    required this.start,
    required this.end,
    required this.attendees,
  });
}
class _EditBookingDialog extends StatefulWidget {
  final Booking booking;
  const _EditBookingDialog({
    required this.booking,
  });
  @override
  State<_EditBookingDialog> createState() {
    return _EditBookingDialogState();
  }
}
class _EditBookingDialogState extends State<_EditBookingDialog> {
  late DateTime _start;
  late DateTime _end;
  late final TextEditingController _attendeesController;
  String? _error;
  @override
  void initState() {
    super.initState();
    _start = widget.booking.startDateTime;
    _end = widget.booking.endDateTime;
    _attendeesController = TextEditingController(
      text: widget.booking.attendees.toString(),
    );
  }
  @override
  void dispose() {
    _attendeesController.dispose();
    super.dispose();
  }
  Future<DateTime?> _pickDateTime(
    DateTime initial,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) {
      return null;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) {
      return null;
    }
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }
  void _save() {
    final attendees = int.tryParse(
      _attendeesController.text.trim(),
    );
    if (!_end.isAfter(_start)) {
      setState(() {
        _error = 'End time must be after start time.';
      });
      return;
    }
    if (attendees == null || attendees < 1) {
      setState(() {
        _error = 'Enter a valid number of attendees.';
      });
      return;
    }
    Navigator.pop(
      context,
      _BookingChange(
        start: _start,
        end: _end,
        attendees: attendees,
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change booking'),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Start'),
              subtitle: Text(
                _start.toString(),
              ),
              trailing: const Icon(
                Icons.calendar_month,
              ),
              onTap: () async {
                final selected = await _pickDateTime(
                  _start,
                );
                if (selected != null) {
                  setState(() {
                    _start = selected;
                    _error = null;
                  });
                }
              },
            ),
            ListTile(
              title: const Text('End'),
              subtitle: Text(
                _end.toString(),
              ),
              trailing: const Icon(
                Icons.calendar_month,
              ),
              onTap: () async {
                final selected = await _pickDateTime(
                  _end,
                );
                if (selected != null) {
                  setState(() {
                    _end = selected;
                    _error = null;
                  });
                }
              },
            ),
            TextField(
              controller: _attendeesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Attendees',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
