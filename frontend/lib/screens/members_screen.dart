import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../models/member.dart';
import '../services/api_service.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/member_form_dialog.dart';


/// Lists members, creates members and shows a member's bookings.
/// Owner: Ghada (placeholder created in the project skeleton).
class MembersScreen extends StatefulWidget {
  final ApiService? api;
  const MembersScreen({
    super.key,
    this.api,
  });
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
      showMessage(
        context,
        'Member ${created.fullName} added.',
      );
      await _loadMembers();
    } catch (e) {
      if (!mounted) return;
      showMessage(
        context,
        e.toString(),
        isError: true,
      );
    }
  }
Future<void> _showBookings(Member member) async {
    if (member.id == null) return;
    await showDialog<void>(
      context: context,
      builder: (context) => _MemberBookingsDialog(
        member: member,
        api: _api,
      ),
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
        Expanded(
          child: _buildBody(),
        ),
      ],
    );
  }
Widget _buildBody() {
    if (_loading) {
      return const LoadingView(
        message: 'Loading members...',
      );
    }
    if (_error != null) {
      return ErrorView(
        message: _error!,
        onRetry: _loadMembers,
      );
    }
    if (_members.isEmpty) {
      return const Center(
        child: Text('No members found.'),
      );
    }
    return ListView.builder(
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text(member.fullName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.email),
                Text(member.phoneNumber),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showBookings(member),
          ),
        );
      },
    );
  }
}
class _MemberBookingsDialog extends StatelessWidget {
  final Member member;
  final ApiService api;
  const _MemberBookingsDialog({
    required this.member,
    required this.api,
  });
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${member.fullName} - Bookings'),
      content: SizedBox(
        width: 550,
        height: 400,
        child: FutureBuilder<List<Booking>>(
          future: api.getMemberBookings(member.id!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView(
                message: 'Loading bookings...',
              );
            }
            if (snapshot.hasError) {
              return ErrorView(
                message: snapshot.error.toString(),
              );
            }
            final bookings = snapshot.data ?? [];
            if (bookings.isEmpty) {
              return const Center(
                child: Text(
                  'No bookings found for this member.',
                ),
              );
            }
            return ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return Card(
                  child: ListTile(
                    title: Text(
                      'Booking #${booking.id}',
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                          'Status: ${booking.status}',
                        ),
                        Text(
                          'Total cost: ${booking.totalCost}',
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

  }}
