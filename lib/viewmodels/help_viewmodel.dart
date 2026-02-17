import 'package:flutter/foundation.dart';
import '../models/help_ticket_model.dart';

class HelpViewModel extends ChangeNotifier {
  List<HelpTicketModel> _tickets = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _submitError;
  bool _submitSuccess = false;

  // Form fields
  String? _selectedCategory;
  String _subject = '';
  String _description = '';
  String? _attachmentPath;

  List<HelpTicketModel> get tickets => _tickets;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get submitError => _submitError;
  bool get submitSuccess => _submitSuccess;
  String? get selectedCategory => _selectedCategory;
  String get subject => _subject;
  String get description => _description;
  String? get attachmentPath => _attachmentPath;

  final List<String> categories = [
    'Billing',
    'Technical Issue',
    'New Connection',
    'Plan Change',
    'KYC',
    'Other',
  ];

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

  void setAttachment(String? path) {
    _attachmentPath = path;
    notifyListeners();
  }

  Future<void> loadTickets() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));
    _tickets = []; // No tickets for this user
    _isLoading = false;
    notifyListeners();
  }

  Future<void> submitTicket() async {
    if (_selectedCategory == null || _subject.isEmpty || _description.isEmpty) {
      _submitError = 'Please fill all required fields';
      notifyListeners();
      return;
    }

    _isSubmitting = true;
    _submitError = null;
    _submitSuccess = false;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      final ticket = HelpTicketModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        category: _selectedCategory!,
        subject: _subject,
        description: _description,
        attachmentPath: _attachmentPath,
        createdAt: DateTime.now(),
      );
      _tickets.add(ticket);
      _submitSuccess = true;
      _resetForm();
    } catch (e) {
      _submitError = e.toString();
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void _resetForm() {
    _selectedCategory = null;
    _subject = '';
    _description = '';
    _attachmentPath = null;
  }

  void resetSubmitState() {
    _submitSuccess = false;
    _submitError = null;
    notifyListeners();
  }
}
