// lib/viewmodels/help_viewmodel.dart

import 'package:flutter/foundation.dart';
import '../services/ticket_service.dart';

class HelpViewModel extends ChangeNotifier {
  final _service = TicketService();

  // ── Ticket list ───────────────────────────────────────────────────────────
  List<SupportTicket> _tickets  = [];
  bool    _isLoading            = false;
  String? _listError;

  List<SupportTicket> get tickets   => _tickets;
  bool                get isLoading => _isLoading;
  String?             get listError => _listError;

  // ── Create form ───────────────────────────────────────────────────────────
  bool    _isSubmitting        = false;
  String? _submitError;
  bool    _submitSuccess       = false;
  String? _createdTicketNumber;

  bool    get isSubmitting        => _isSubmitting;
  String? get submitError         => _submitError;
  bool    get submitSuccess       => _submitSuccess;
  String? get createdTicketNumber => _createdTicketNumber;

  // ── Form fields ───────────────────────────────────────────────────────────
  String? _selectedCategory;
  String  _subject     = '';
  String  _description = '';

  String? _attachmentBase64;
  String? _attachmentMime;
  String? _attachmentFileName;

  String? get selectedCategory   => _selectedCategory;
  String  get subject            => _subject;
  String  get description        => _description;
  String? get attachmentFileName => _attachmentFileName;
  bool    get hasAttachment      => _attachmentBase64 != null;
  String? get attachmentPath     => _attachmentFileName;

  final List<String> categories = TicketService.categories;

  void setCategory(String? value) {
    _selectedCategory = value;
    notifyListeners();
  }

  void setSubject(String value) {
    _subject = value;
    notifyListeners();
  }

  void setDescription(String value) {
    _description = value;
    notifyListeners();
  }

  void setAttachment({
    required String base64,
    required String mime,
    required String fileName,
  }) {
    _attachmentBase64   = base64;
    _attachmentMime     = mime;
    _attachmentFileName = fileName;
    notifyListeners();
  }

  void clearAttachment() {
    _attachmentBase64   = null;
    _attachmentMime     = null;
    _attachmentFileName = null;
    notifyListeners();
  }

  // ── Detail ────────────────────────────────────────────────────────────────
  SupportTicket? _selectedTicket;
  bool           _loadingDetail = false;

  SupportTicket? get selectedTicket  => _selectedTicket;
  bool           get loadingDetail   => _loadingDetail;
  // Alias so both spellings work (TicketDetailScreen uses loadingDetail,
  // older code may use isLoadingDetail)
  bool           get isLoadingDetail => _loadingDetail;

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> loadTickets() async {
    _isLoading = true;
    _listError = null;
    notifyListeners();
    try {
      _tickets = await _service.getTickets();
    } catch (e) {
      _listError = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads the full ticket detail from the API and — crucially — syncs the
  /// fresh status back into the list so the list card shows the correct value.
  Future<void> loadTicketDetail(int id) async {
    _loadingDetail  = true;
    _selectedTicket = null;
    notifyListeners();

    _selectedTicket = await _service.getTicket(id);

    // ── FIX: sync updated status back into the list ───────────────────────
    // The list was loaded earlier and may be stale (e.g. shows "Open" while
    // the server has since changed it to "Closed"). Replace the matching
    // entry so the chip is correct when the user navigates back.
    if (_selectedTicket != null) {
      final idx = _tickets.indexWhere((t) => t.id == id);
      if (idx != -1) {
        _tickets[idx] = _selectedTicket!;
      }
    }
    // ─────────────────────────────────────────────────────────────────────

    _loadingDetail = false;
    notifyListeners();
  }

  Future<void> submitTicket() async {
    if (_selectedCategory == null ||
        _subject.trim().isEmpty ||
        _description.trim().isEmpty) {
      _submitError = 'Please fill all required fields';
      notifyListeners();
      return;
    }

    _isSubmitting  = true;
    _submitError   = null;
    _submitSuccess = false;
    notifyListeners();

    final result = await _service.createTicket(
      category:       _selectedCategory!,
      subject:        _subject.trim(),
      description:    _description.trim(),
      attachmentData: _attachmentBase64,
      attachmentMime: _attachmentMime,
    );

    _isSubmitting = false;

    if (result.success) {
      _submitSuccess       = true;
      _createdTicketNumber = result.ticket?.ticketNumber;
      if (result.ticket != null) {
        _tickets = [result.ticket!, ..._tickets];
      }
      _resetForm();
    } else {
      _submitError = result.error;
    }
    notifyListeners();
  }

  void _resetForm() {
    _selectedCategory   = null;
    _subject            = '';
    _description        = '';
    _attachmentBase64   = null;
    _attachmentMime     = null;
    _attachmentFileName = null;
  }

  void resetSubmitState() {
    _submitSuccess       = false;
    _submitError         = null;
    _createdTicketNumber = null;
    notifyListeners();
  }
}