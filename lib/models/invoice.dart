enum InvoiceStatus {
  pendingApproval('Pending Approval'),
  approved('Approved'),
  financed('Financed'),
  paid('Paid'),
  rejected('Rejected');

  const InvoiceStatus(this.label);
  final String label;
}

class InvoiceDocument {
  const InvoiceDocument({required this.name, required this.sizeKb});

  final String name;
  final int sizeKb;

  factory InvoiceDocument.fromJson(Map<String, dynamic> json) =>
      InvoiceDocument(name: json['name'] as String, sizeKb: (json['sizeKb'] as num).toInt());

  Map<String, dynamic> toJson() => {'name': name, 'sizeKb': sizeKb};
}

class Invoice {
  const Invoice({
    required this.id,
    required this.number,
    required this.supplierId,
    required this.supplierName,
    required this.buyerId,
    required this.buyerName,
    required this.amount,
    required this.issueDate,
    required this.dueDate,
    required this.status,
    required this.updatedAt,
    this.poNumber = '',
    this.description = '',
    this.documents = const [],
    this.fraudFlags = const [],
    this.rejectionReason,
  });

  final String id;
  final String number;
  final String supplierId;
  final String supplierName;
  final String buyerId;
  final String buyerName;
  final double amount;
  final DateTime issueDate;
  final DateTime dueDate;
  final InvoiceStatus status;
  final DateTime updatedAt;
  final String poNumber;
  final String description;
  final List<InvoiceDocument> documents;

  /// Warnings raised by the fraud & duplicate-invoice checks.
  final List<String> fraudFlags;
  final String? rejectionReason;

  bool get isFlagged => fraudFlags.isNotEmpty;

  int daysToDue([DateTime? now]) => dueDate.difference(now ?? DateTime.now()).inDays;

  Invoice copyWith({
    InvoiceStatus? status,
    DateTime? updatedAt,
    List<String>? fraudFlags,
    String? rejectionReason,
  }) {
    return Invoice(
      id: id,
      number: number,
      supplierId: supplierId,
      supplierName: supplierName,
      buyerId: buyerId,
      buyerName: buyerName,
      amount: amount,
      issueDate: issueDate,
      dueDate: dueDate,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      poNumber: poNumber,
      description: description,
      documents: documents,
      fraudFlags: fraudFlags ?? this.fraudFlags,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      number: json['number'] as String,
      supplierId: json['supplierId'] as String,
      supplierName: json['supplierName'] as String,
      buyerId: json['buyerId'] as String,
      buyerName: json['buyerName'] as String,
      amount: (json['amount'] as num).toDouble(),
      issueDate: DateTime.parse(json['issueDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      status: InvoiceStatus.values.byName(json['status'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      poNumber: json['poNumber'] as String? ?? '',
      description: json['description'] as String? ?? '',
      documents: (json['documents'] as List<dynamic>? ?? [])
          .map((d) => InvoiceDocument.fromJson(d as Map<String, dynamic>))
          .toList(),
      fraudFlags: (json['fraudFlags'] as List<dynamic>? ?? []).cast<String>(),
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'supplierId': supplierId,
        'supplierName': supplierName,
        'buyerId': buyerId,
        'buyerName': buyerName,
        'amount': amount,
        'issueDate': issueDate.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'status': status.name,
        'updatedAt': updatedAt.toIso8601String(),
        'poNumber': poNumber,
        'description': description,
        'documents': documents.map((d) => d.toJson()).toList(),
        'fraudFlags': fraudFlags,
        'rejectionReason': rejectionReason,
      };
}
