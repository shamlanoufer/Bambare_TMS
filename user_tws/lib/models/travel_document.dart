import 'package:cloud_firestore/cloud_firestore.dart';

class TravelDocument {
  const TravelDocument({
    required this.id,
    required this.type,
    required this.issuingCountry,
    required this.fullName,
    required this.documentNo,
    required this.issueDate,
    required this.expiryDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String type; // Passport | National ID | Visa | Travel Insurance | Other
  final String issuingCountry;
  final String fullName;
  final String documentNo;
  final DateTime issueDate;
  final DateTime expiryDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isExpired => DateTime.now().isAfter(expiryDate);

  int get daysLeft {
    final now = DateTime.now();
    final a = DateTime(now.year, now.month, now.day);
    final b = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return b.difference(a).inDays;
  }

  bool get isExpiringSoon => !isExpired && daysLeft <= 121;

  static DateTime _tsToDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static TravelDocument fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return TravelDocument(
      id: doc.id,
      type: (d['type'] ?? 'Passport').toString(),
      issuingCountry: (d['issuing_country'] ?? 'Sri Lanka').toString(),
      fullName: (d['full_name'] ?? '').toString(),
      documentNo: (d['document_no'] ?? '').toString(),
      issueDate: _tsToDate(d['issue_date']),
      expiryDate: _tsToDate(d['expiry_date']),
      createdAt: _tsToDate(d['created_at']),
      updatedAt: _tsToDate(d['updated_at']),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'type': type,
      'issuing_country': issuingCountry,
      'full_name': fullName,
      'document_no': documentNo,
      'issue_date': Timestamp.fromDate(issueDate),
      'expiry_date': Timestamp.fromDate(expiryDate),
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'type': type,
      'issuing_country': issuingCountry,
      'full_name': fullName,
      'document_no': documentNo,
      'issue_date': Timestamp.fromDate(issueDate),
      'expiry_date': Timestamp.fromDate(expiryDate),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}

