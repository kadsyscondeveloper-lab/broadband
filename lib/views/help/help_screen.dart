// lib/views/help/help_screen.dart
// Keeps your existing UI — only replaces the dummy data with real API calls.

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/help_viewmodel.dart';
import '../../services/ticket_service.dart';
import 'create_ticket_screen.dart';
import 'ticket_detail_screen.dart';

class HelpScreen extends StatefulWidget {
  final HelpViewModel viewModel;

  const HelpScreen({super.key, required this.viewModel});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadTickets();
    });
  }

  void _openCreateTicket() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTicketScreen(viewModel: widget.viewModel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Help'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          GestureDetector(
            onTap: _openCreateTicket,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final vm = widget.viewModel;

          if (vm.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          // ── Error state ────────────────────────────────────────────────
          if (vm.listError != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.textLight, size: 48),
                    const SizedBox(height: 12),
                    Text(vm.listError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textLight)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: vm.loadTickets,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary),
                      child: const Text('Retry',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          }

          // ── Empty state ────────────────────────────────────────────────
          if (vm.tickets.isEmpty) {
            return _EmptyTickets(onCreateTap: _openCreateTicket);
          }

          // ── Ticket list ────────────────────────────────────────────────
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vm.tickets.length,
            itemBuilder: (context, index) {
              final t = vm.tickets[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TicketDetailScreen(
                      viewModel: vm,
                      ticketId:  t.id,
                    ),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(t.subject,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppColors.textDark)),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: AppColors.textLight),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(children: [
                        Text(t.category,
                            style: const TextStyle(
                                color: AppColors.textGrey, fontSize: 12)),
                        const Text(' · ',
                            style: TextStyle(color: AppColors.textGrey)),
                        Text(t.ticketNumber,
                            style: const TextStyle(
                                color: AppColors.textGrey, fontSize: 12)),
                      ]),
                      const SizedBox(height: 8),
                      _StatusChip(status: t.status),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    String label;
    switch (status) {
      case 'in_progress':
        bg = Colors.orange.shade50; fg = Colors.orange.shade700; label = 'In Progress';
        break;
      case 'resolved':
        bg = Colors.green.shade50;  fg = Colors.green.shade700;  label = 'Resolved';
        break;
      case 'closed':
        bg = Colors.grey.shade100;  fg = Colors.grey.shade700;   label = 'Closed';
        break;
      default:
        bg = Colors.blue.shade50;   fg = Colors.blue.shade700;   label = 'Open';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Empty state (unchanged from your original) ────────────────────────────────

class _EmptyTickets extends StatelessWidget {
  final VoidCallback onCreateTap;
  const _EmptyTickets({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                    color: Colors.red.shade50, shape: BoxShape.circle),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close, color: Colors.red.shade300, size: 18),
                          Icon(Icons.close, color: Colors.red.shade300, size: 18),
                          const SizedBox(height: 4),
                          Icon(Icons.sentiment_dissatisfied,
                              color: Colors.red.shade300, size: 20),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8, left: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Icon(Icons.close,
                            size: 12, color: Colors.red.shade400),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text('No Help Tickets Available',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
              const SizedBox(height: 12),
              const Text("You don't have any open support\nrequests right now.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textGrey, height: 1.5)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onCreateTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Create Ticket',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}