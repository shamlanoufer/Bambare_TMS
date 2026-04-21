import 'package:cloud_firestore/cloud_firestore.dart';

/// Booking document from Firestore `bookings` collection.
class Booking {
  const Booking({
    required this.id,
    required this.status,
    required this.tourId,
    required this.tourTitle,
    required this.reference,
    required this.travelDate,
    required this.createdAt,
    required this.email,
    required this.phone,
    required this.tourImageUrl,
    required this.location,
    required this.totalPrice,
    required this.currency,
    this.leadFirstName = '',
    this.leadLastName = '',
  });

  final String id;
  final String status;
  /// Firestore `tour_id` — used for guest reviews subcollection.
  final String tourId;
  final String tourTitle;
  final String reference;
  final DateTime travelDate;
  final DateTime createdAt;
  final String email;
  final String phone;
  final String tourImageUrl;
  final String location;
  final double totalPrice;
  final String currency;
  final String leadFirstName;
  final String leadLastName;

  String get leadDisplayName {
    final a = leadFirstName.trim();
    final b = leadLastName.trim();
    if (a.isEmpty && b.isEmpty) return '';
    if (a.isEmpty) return b;
    if (b.isEmpty) return a;
    return '$a $b';
  }

  bool get isCancelled {
    final s = status.toLowerCase();
    return s == 'cancelled' || s == 'canceled';
  }

  DateTime get _startOfToday {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool get isUpcoming => !isCancelled && !travelDate.isBefore(_startOfToday);

  bool get isCompleted => !isCancelled && travelDate.isBefore(_startOfToday);

  String travelDateLabelShort() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final nextDay = travelDate.add(const Duration(days: 1));
    return '${months[travelDate.month - 1]} ${travelDate.day}-${nextDay.day}';
  }

  String get formattedTotalPrice => '$currency ${_commaFormat(totalPrice.round())}';

  static String _commaFormat(int n) {
    final s = n.abs().toString();
    final buf = StringBuffer(n < 0 ? '-' : '');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  factory Booking.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final travelTs = d['travel_date'];
    final createdTs = d['created_at'];
    DateTime travelDate = DateTime.now();
    if (travelTs is Timestamp) {
      travelDate = travelTs.toDate();
    }
    DateTime createdAt = DateTime.now();
    if (createdTs is Timestamp) {
      createdAt = createdTs.toDate();
    }
    return Booking(
      id: doc.id,
      status: d['status'] as String? ?? 'Confirmed',
      tourId: (d['tour_id'] as String? ?? '').trim(),
      tourTitle: d['tour_title'] as String? ?? '',
      reference: d['reference'] as String? ?? doc.id,
      travelDate: travelDate,
      createdAt: createdAt,
      email: d['email'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      tourImageUrl: d['tour_image_url'] as String? ?? '',
      location: d['location'] as String? ?? '',
      totalPrice: (d['total_price'] as num?)?.toDouble() ?? 0,
      currency: d['currency'] as String? ?? 'LKR',
      leadFirstName: (d['lead_first_name'] as String? ?? '').trim(),
      leadLastName: (d['lead_last_name'] as String? ?? '').trim(),
    );
  }
}
