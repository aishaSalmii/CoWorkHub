import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/member.dart';
import '../models/resource.dart';
import '../services/api_service.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';

/// Home screen: summary information about the coworking space
/// and the list of today's bookings.
class DashboardScreen extends StatefulWidget {
  /// [api] can be replaced in tests; normally a real ApiService is used.
  final ApiService? api;

  const DashboardScreen({super.key, this.api});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final ApiService _api = widget.api ?? ApiService();

  List<Resource> _resources = [];
  List<Member> _members = [];
  List<Booking> _bookings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Loads resources, members and bookings at the same time.
  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.getResources(),
        _api.getMembers(),
        _api.getBookings(),
      ]);
      if (!mounted) return;
      setState(() {
        _resources = results[0] as List<Resource>;
        _members = results[1] as List<Member>;
        _bookings = results[2] as List<Booking>;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------- Summary numbers ----------

  int get _activeCount => _resources.where((r) => r.isActive).length;
  int get _outOfServiceCount => _resources.length - _activeCount;
  int get _roomCount => _resources.where((r) => r.isMeetingRoom).length;
  int get _deskCount => _resources.where((r) => r.isDesk).length;

  /// Confirmed bookings that start today, earliest first.
  List<Booking> get _todaysBookings {
    final today = DateTime.now();
    final list = _bookings
        .where((b) => !b.isCancelled && _isSameDay(b.startDateTime, today))
        .toList();
    list.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    return list;
  }

  /// Confirmed bookings that start after today.
  int get _upcomingCount {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day + 1);
    return _bookings
        .where((b) => !b.isCancelled && !b.startDateTime.isBefore(endOfToday))
        .length;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView(message: 'Loading dashboard...');
    if (_error != null) return ErrorView(message: _error!, onRetry: _loadData);

    final todays = _todaysBookings;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Welcome to CoWorkHub',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _SummaryCard(
                icon: Icons.meeting_room_outlined,
                title: 'Resources',
                value: '${_resources.length}',
                details:
                    '$_roomCount rooms • $_deskCount desks\n'
                    '$_activeCount active • $_outOfServiceCount out of service',
              ),
              _SummaryCard(
                icon: Icons.people_outline,
                title: 'Members',
                value: '${_members.length}',
                details: 'registered members',
              ),
              _SummaryCard(
                icon: Icons.today_outlined,
                title: "Today's bookings",
                value: '${todays.length}',
                details: 'confirmed bookings today',
              ),
              _SummaryCard(
                icon: Icons.event_outlined,
                title: 'Upcoming',
                value: '$_upcomingCount',
                details: 'confirmed bookings after today',
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            "Today's bookings",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (todays.isEmpty)
            const Text('No bookings today.')
          else
            for (final booking in todays)
              Card(
                child: ListTile(
                  leading: Icon(
                    booking.resource.isMeetingRoom
                        ? Icons.meeting_room
                        : Icons.desk,
                  ),
                  title: Text(booking.resource.name),
                  subtitle: Text(
                    '${_formatTime(booking.startDateTime)}–${_formatTime(booking.endDateTime)}'
                    '  •  ${booking.member.fullName}'
                    '  •  ${booking.attendees} attendee(s)',
                  ),
                  trailing: Text('${booking.totalCost.toStringAsFixed(2)} QAR'),
                ),
              ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dateTime.hour)}:${two(dateTime.minute)}';
  }
}

/// One summary box on the dashboard: an icon, a big number and a label.
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String details;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 240,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(value, style: theme.textTheme.displaySmall),
              const SizedBox(height: 4),
              Text(details, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
