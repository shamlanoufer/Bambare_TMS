import 'package:cloud_firestore/cloud_firestore.dart';

/// User booking in `bookings` — created by the app; tours stay read-only in `tours`.
///
/// Fields: `user_id`, `reference`, `tour_id`, `tour_title`, `tour_image_url`,
/// `location`, `travel_date`, `adults`, `children`, `rooms`,
/// `subtotal_tours`, `service_fee`, `total_price`, `currency`, `pickup`, `duration`,
/// `status` (Confirmed | Pending | Completed | Cancelled),
/// guest fields, `created_at`, `updated_at`, optional `cancelled_at`.
class Booking {
  const Booking({
    required this.id,
    required this.userId,
    required this.reference,
    required this.tourId,
    required this.tourTitle,
    required this.tourImageUrl,
    required this.location,
    required this.travelDate,
    required this.adults,
    required this.children,
    required this.rooms,
    required this.totalPrice,
    this.subtotalTours = 0,
    this.serviceFee = 0,
    required this.currency,
    this.pickup = '',
    this.durationLabel = '',
    required this.status,
    required this.leadFirstName,
    required this.leadLastName,
    required this.phone,
    required this.email,
    required this.nationality,
    required this.specialRequests,
    required this.createdAt,
    this.cancelledAt,
  });

  final String id;
  final String userId;
  final String reference;
  final String tourId;
  final String tourTitle;
  final String tourImageUrl;
  final String location;
  final DateTime travelDate;
  final int adults;
  final int children;
  final int rooms;
  final double totalPrice;
  final double subtotalTours;
  final double serviceFee;
  final String currency;
  final String pickup;
  final String durationLabel;
  final String status;
  final String leadFirstName;
  final String leadLastName;
  final String phone;
  final String email;
  final String nationality;
  final String specialRequests;
  final DateTime createdAt;
  final DateTime? cancelledAt;

  factory Booking.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    final travel = d['travel_date'];
    DateTime travelDate;
    if (travel is Timestamp) {
      travelDate = travel.toDate();
    } else {
      travelDate = DateTime.now();
    }
    final created = d['created_at'];
    DateTime createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    } else {
      createdAt = DateTime.now();
    }
    final cancelled = d['cancelled_at'];
    DateTime? cancelledAt;
    if (cancelled is Timestamp) {
      cancelledAt = cancelled.toDate();
    }
    return Booking(
      id: doc.id,
      userId: (d['user_id'] as String?) ?? '',
      reference: (d['reference'] as String?)?.trim() ?? '',
      tourId: (d['tour_id'] as String?)?.trim() ?? '',
      tourTitle: (d['tour_title'] as String?)?.trim() ?? '',
      tourImageUrl: (d['tour_image_url'] as String?)?.trim() ?? '',
      location: (d['location'] as String?)?.trim() ?? '',
      travelDate: travelDate,
      adults: (d['adults'] as num?)?.toInt() ?? 0,
      children: (d['children'] as num?)?.toInt() ?? 0,
      rooms: (d['rooms'] as num?)?.toInt() ?? 1,
      totalPrice: (d['total_price'] as num?)?.toDouble() ?? 0,
      subtotalTours: (d['subtotal_tours'] as num?)?.toDouble() ?? 0,
      serviceFee: (d['service_fee'] as num?)?.toDouble() ?? 0,
      currency: (d['currency'] as String?)?.trim().toUpperCase() ?? 'LKR',
      pickup: (d['pickup'] as String?)?.trim() ?? '',
      durationLabel: (d['duration'] as String?)?.trim() ?? '',
      status: _normalizeBookingStatus(d['status']),
      leadFirstName: (d['lead_first_name'] as String?)?.trim() ?? '',
      leadLastName: (d['lead_last_name'] as String?)?.trim() ?? '',
      phone: (d['phone'] as String?)?.trim() ?? '',
      email: (d['email'] as String?)?.trim() ?? '',
      nationality: (d['nationality'] as String?)?.trim() ?? '',
      specialRequests: (d['special_requests'] as String?)?.trim() ?? '',
      createdAt: createdAt,
      cancelledAt: cancelledAt,
    );
  }

  static String _normalizeBookingStatus(dynamic raw) {
    final s = (raw as String?)?.trim();
    if (s == null || s.isEmpty) return 'Confirmed';
    switch (s.toLowerCase()) {
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      case 'completed':
      case 'complete':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'confirmed':
      default:
        return 'Confirmed';
    }
  }

  /// Same document appears in exactly one tab: Cancelled → Completed (past/done) → Upcoming.
  bool get isCancelled {
    switch (status) {
      case 'Cancelled':
        return true;
      default:
        return false;
    }
  }

  /// Admin can set `Completed`, or a **past** Confirmed/Pending trip counts as completed.
  bool get isCompleted {
    if (isCancelled) return false;
    if (status == 'Completed') return true;
    if (status != 'Confirmed' && status != 'Pending') return false;
    final tripDay = DateTime(travelDate.year, travelDate.month, travelDate.day);
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    return tripDay.isBefore(todayDay);
  }

  /// Future or today’s trip, still active (Confirmed / Pending).
  bool get isUpcoming {
    if (isCancelled) return false;
    if (status != 'Confirmed' && status != 'Pending') return false;
    final tripDay = DateTime(travelDate.year, travelDate.month, travelDate.day);
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    return !tripDay.isBefore(todayDay);
  }

  String get formattedTotalPrice {
    final p = totalPrice.round();
    final s = p.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      if (i > 0 && fromEnd % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '$currency $buf';
  }

  String travelDateLabelShort() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final d = travelDate;
    final nextDay = d.add(const Duration(days: 1));
    return '${months[d.month - 1]} ${d.day}-${nextDay.day}';
  }
}
