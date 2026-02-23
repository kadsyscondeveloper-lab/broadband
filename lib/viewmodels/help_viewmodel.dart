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

  // Attachment — stored as base64 + mime type
  String? _attachmentBase64;
  String? _attachmentMime;
  String? _attachmentFileName; // display only

  String? get selectedCategory   => _selectedCategory;
  String  get subject            => _subject;
  String  get description        => _description;
  String? get attachmentFileName => _attachmentFileName;
  bool    get hasAttachment      => _attachmentBase64 != null;

  // Keep compatible with existing create screen which uses attachmentPath for display
  String? get attachmentPath => _attachmentFileName;

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
    _attachmentBase64    = base64;
    _attachmentMime      = mime;
    _attachmentFileName  = fileName;
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

  SupportTicket? get selectedTicket => _selectedTicket;
  bool           get loadingDetail  => _loadingDetail;

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

  Future<void> loadTicketDetail(int id) async {
    _loadingDetail  = true;
    _selectedTicket = null;
    notifyListeners();
    _selectedTicket = await _service.getTicket(id);
    _loadingDetail  = false;
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