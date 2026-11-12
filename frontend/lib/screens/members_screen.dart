import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/member.dart';
import '../services/api_service.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/member_form_dialog.dart';

/// Lists members, creates and edits members and shows a member's bookings.
class MembersScreen extends StatefulWidget {
  final ApiService? api;
  const MembersScreen({super.key, this.api});
  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  late final ApiService _api;
  List<Member> _members = [];
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _api = widget.api ?? ApiService();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final members = await _api.getMembers();
      if (!mounted) return;
      setState(() {
        _members = members;
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

  Future<void> _addMember() async {
    final member = await showDialog<Member>(
      context: context,
      builder: (context) => const MemberFormDialog(),
    );
    if (member == null) return;
    try {
      final created = await _api.createMember(member);
      if (!mounted) return;
      showMessage(context, 'Member ${created.fullName} added.');
      await _loadMembers();
    } catch (e) {
      if (!mounted) return;
      showMessage(context, e.toString(), isError: true);
    }
  }

  Future<void> _editMember(Member member) async {
    if (member.id == null) return;
    final edited = await showDialog<Member>(
      context: context,
      builder: (context) => MemberFormDialog(member: member),
    );
    if (edited == null) return;
    try {
      final updated = await _api.updateMember(member.id!, edited);
      if (!mounted) return;
      showMessage(context, 'Member ${updated.fullName} updated.');
      await _loadMembers();
    } catch (e) {
      if (!mounted) return;
      showMessage(context, e.toString(), isError: true);
    }
  }

  Future<void> _showBookings(Member member) async {
    if (member.id == null) return;
    await showDialog<void>(
      context: context,
      builder: (context) => _MemberBookingsDialog(member: member, api: _api),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.icon(
                onPressed: _addMember,
                icon: const Icon(Icons.person_add),
                label: const Text('Add member'),
              ),
            ],
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const LoadingView(message: 'Loading members...');
    }
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _loadMembers);
    }
    if (_members.isEmpty) {
      return const Center(child: Text('No members found.'));
    }
    return ListView.builder(
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text(member.fullName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(member.email), Text(member.phoneNumber)],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit member',
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editMember(member),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _showBookings(member),
          ),
        );
      },
    );
  }
}

class _MemberBookingsDialog extends StatefulWidget {
  final Member member;
  final ApiService api;
  const _MemberBookingsDialog({required this.member, required this.api});
  @override
  State<_MemberBookingsDialog> createState() => _MemberBookingsDialogState();
}

class _MemberBookingsDialogState extends State<_MemberBookingsDialog> {
  // Loaded ONCE when the dialog opens (not again on every rebuild).
  late final Future<List<Booking>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _bookingsFuture = widget.api.getMemberBookings(widget.member.id!);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.member.fullName} - Bookings'),
      content: SizedBox(
        width: 550,
        height: 400,
        child: FutureBuilder<List<Booking>>(
          future: _bookingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView(message: 'Loading bookings...');
            }
            if (snapshot.hasError) {
              return ErrorView(message: snapshot.error.toString());
            }
            final bookings = snapshot.data ?? [];
            if (bookings.isEmpty) {
              return const Center(
                child: Text('No bookings found for this member.'),
              );
            }
            return ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return Card(
                  child: ListTile(
                    title: Text('Booking #${booking.id}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Resource: ${booking.resource.name}'),
                        Text(
                          'Start: ${_formatDateTime(booking.startDateTime)}',
                        ),
                        Text('End: ${_formatDateTime(booking.endDateTime)}'),
                        Text('Status: ${booking.status}'),
                        Text(
                          'Total cost: ${booking.totalCost.toStringAsFixed(2)} QAR',
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// Formats a date and time as 2026-12-01 10:00
String _formatDateTime(DateTime dateTime) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${dateTime.year}-${two(dateTime.month)}-${two(dateTime.day)} '
      '${two(dateTime.hour)}:${two(dateTime.minute)}';
}