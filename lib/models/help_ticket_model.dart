class HelpTicketModel {
  final String id;
  final String category;
  final String subject;
  final String description;
  final String? attachmentPath;
  final DateTime createdAt;
  final String status;

  HelpTicketModel({
    required this.id,
    required this.category,
    required this.subject,
    required this.description,
    this.attachmentPath,
    required this.createdAt,
    this.status = 'Open',
  });
}

class PaymentTransactionModel {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String status;
  final String type;

  PaymentTransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.status,
    required this.type,
  });
}
