import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field_v2/countries.dart' show countries, Country;
import 'package:intl_phone_field_v2/helpers.dart';
import 'package:intl_phone_field_v2/phone_number.dart' as intl_phone;
import 'package:phone_numbers_parser/phone_numbers_parser.dart' as libphone;

import '../../core/booking_background.dart';
import '../../models/tour.dart';
import '../../services/booking_receipt_pdf.dart';
import '../../services/booking_service.dart';
import '../../utils/pdf_save.dart';
import 'my_bookings_screen.dart';

class _BookingPayOpt {
  const _BookingPayOpt({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
}

const _kBookingPaymentOptions = <_BookingPayOpt>[
  _BookingPayOpt(
    id: 'card',
    title: 'Credit / Debit Card',
    subtitle: 'Visa, Mastercard, Amex',
    icon: Icons.credit_card_rounded,
    iconColor: Color(0xFF1565C0),
  ),
  _BookingPayOpt(
    id: 'pay_at_counter',
    title: 'Pay at Counter',
    subtitle: 'Cash on arrival',
    icon: Icons.storefront_outlined,
    iconColor: Color(0xFF6A1B9A),
  ),
  _BookingPayOpt(
    id: 'paypal',
    title: 'PayPal',
    subtitle: 'Secure online payment',
    icon: Icons.account_balance_wallet_outlined,
    iconColor: Color(0xFF0D47A1),
  ),
  _BookingPayOpt(
    id: 'special',
    title: 'Special Payment',
    subtitle: 'Bank transfer, corporate invoice, or promo — we will contact you',
    icon: Icons.workspace_premium_outlined,
    iconColor: Color(0xFFC9A000),
  ),
];

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, required this.tour});

  final Tour tour;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  static const _accent = Color(0xFFE8B800);
  static const _bg = Color(0xFFFFFBF0);

  // Wizard state: 1 to 4
  int _currentStep = 1;

  // -- Step 1 State --
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  int _adults = 2;
  int _children = 0;
  int _rooms = 1;

  bool get _showRoomsOption {
    final cat = widget.tour.category.trim().toLowerCase();
    final title = widget.tour.title.trim().toLowerCase();
    final isFood = widget.tour.visibility.environmentFood || cat == 'food';
    final isCookery = widget.tour.visibility.activityCookery ||
        title.contains('cookery') ||
        title.contains('cook');
    return !(isFood || isCookery);
  }

  // -- Step 2 State --
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _specialCtrl = TextEditingController();

  late Country _selectedPhoneCountry;
  String? _phoneFieldError;
  // E.164 after step 2 passes validation (used for Firestore + receipt).
  String _leadPhoneE164 = '';

  /// Step 3 — payment method (`_kBookingPaymentOptions` id).
  String _selectedPaymentMethodId = _kBookingPaymentOptions.first.id;

  // Price calculations
  double get _adultPrice => widget.tour.price * _adults;
  double get _childPrice => widget.tour.price * 0.25 * _children; // Child is 25% of adult
  double get _serviceFee => 500.0;
  double get _totalPrice => _adultPrice + _childPrice + _serviceFee;

  String _formatCurrency(double amount) {
    final s = amount.round().toString();
    final buf = StringBuffer('');
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      if (i > 0 && fromEnd % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _formatDateShort(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final nextDay = d.add(const Duration(days: 1));
    return '${months[d.month - 1]} ${d.day}-${nextDay.day}';
  }

  String _paymentMethodLabel() {
    for (final o in _kBookingPaymentOptions) {
      if (o.id == _selectedPaymentMethodId) return o.title;
    }
    return _kBookingPaymentOptions.first.title;
  }

  Widget _buildPaymentMethodSection() {
    const borderColor = Color(0xFFE8C84A);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'SELECT PAYMENT METHOD',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: const Color(0xFF4E342E),
            ),
          ),
          const SizedBox(height: 14),
          ..._kBookingPaymentOptions.map(
            (o) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PaymentMethodOptionTile(
                title: o.title,
                subtitle: o.subtitle,
                icon: o.icon,
                iconColor: o.iconColor,
                selected: _selectedPaymentMethodId == o.id,
                borderColor: borderColor,
                accent: _accent,
                onTap: () => setState(() {
                  _selectedPaymentMethodId = o.id;
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _savedReference;
  bool _submitting = false;
  bool _downloading = false;

  final _bookingService = BookingService();

  @override
  void initState() {
    super.initState();
    _selectedPhoneCountry = countries.firstWhere(
      (c) => c.code == 'LK',
      orElse: () => countries.first,
    );
  }

  String _toE164(intl_phone.PhoneNumber phone) {
    var full = phone.completeNumber.replaceAll(RegExp(r'\s'), '');
    if (!full.startsWith('+')) full = '+$full';
    return full;
  }

  String? _validateLeadPhone(intl_phone.PhoneNumber phone) {
    final digits = phone.number.trim().replaceAll(RegExp(r'\s'), '');
    if (digits.isEmpty) {
      return 'Please enter your phone number.';
    }
    final full = _toE164(phone);
    try {
      final parsed = libphone.PhoneNumber.parse(full);
      if (!parsed.isValid()) {
        return 'Please enter a valid phone number for the selected country.';
      }
    } catch (_) {
      return 'Please enter a valid phone number for the selected country.';
    }
    return null;
  }

  String? _validateEmailField(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Please enter your email address.';
    final ok = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(s);
    if (!ok) return 'Please enter a valid email address.';
    return null;
  }

  intl_phone.PhoneNumber _leadPhoneModel() {
    return intl_phone.PhoneNumber(
      countryISOCode: _selectedPhoneCountry.code,
      countryCode: '+${_selectedPhoneCountry.fullCountryCode}',
      number: _phoneCtrl.text.trim(),
    );
  }

  List<Country> _filteredCountriesForPicker(String query) {
    final q = query.trim();
    if (q.isEmpty) {
      final list = List<Country>.from(countries);
      list.sort(
        (a, b) => a.localizedName('en').compareTo(b.localizedName('en')),
      );
      return list;
    }
    final list = countries.stringSearch(q);
    list.sort(
      (a, b) => a.localizedName('en').compareTo(b.localizedName('en')),
    );
    return list;
  }

  Future<void> _openCountryPicker() async {
    final search = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final maxH = MediaQuery.sizeOf(ctx).height * 0.85;
        return SafeArea(
          child: SizedBox(
            height: maxH,
            child: StatefulBuilder(
              builder: (context, setModalState) {
                final list = _filteredCountriesForPicker(search.text);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: TextField(
                        controller: search,
                        style: GoogleFonts.plusJakartaSans(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Search country or dial code',
                          hintStyle: GoogleFonts.plusJakartaSans(color: Colors.black38),
                          prefixIcon: const Icon(Icons.search, color: Colors.black45),
                          filled: true,
                          fillColor: const Color(0xFFFFF6D5).withValues(alpha: 0.6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (_) => setModalState(() {}),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final co = list[i];
                          return ListTile(
                            leading: Text(
                              co.flag,
                              style: const TextStyle(fontSize: 22),
                            ),
                            title: Text(
                              co.localizedName('en'),
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: Text(
                              '+${co.dialCode}',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              setState(() {
                                _selectedPhoneCountry = co;
                                _phoneFieldError = null;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
    search.dispose();
  }

  Widget _buildPhoneRow() {
    final err = _phoneFieldError;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: const Color(0xFFFFF6D5).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: _openCountryPicker,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 12, top: 14, bottom: 14, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedPhoneCountry.flag,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_drop_down, color: Colors.black45),
                      const SizedBox(width: 2),
                      Text(
                        '+${_selectedPhoneCountry.dialCode}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.plusJakartaSans(fontSize: 14),
                  onChanged: (_) => setState(() => _phoneFieldError = null),
                  decoration: InputDecoration(
                    hintText: 'Enter mobile number',
                    hintStyle: GoogleFonts.plusJakartaSans(color: Colors.black38),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.fromLTRB(4, 14, 16, 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (err != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 8),
            child: Text(
              err,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.red.shade700,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _downloadBookingReceipt() async {
    if (_downloading) return;
    final ref = _savedReference ?? 'booking';
    final safeFile =
        ref.replaceAll(RegExp(r'[^\w\-]'), '_').replaceAll('__', '_');
    final guest = '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'
        .trim();
    final guestsLabel = _showRoomsOption
        ? (() {
            final roomsWord = _rooms == 1 ? 'room' : 'rooms';
            return '$_adults adults${_children > 0 ? ', $_children children' : ''} · $_rooms $roomsWord';
          })()
        : '$_adults adults${_children > 0 ? ', $_children children' : ''}';

    setState(() => _downloading = true);
    try {
      final bytes = await BookingReceiptPdf.build(
        reference: ref,
        tourTitle: widget.tour.title,
        location: widget.tour.locationLabel,
        travelDatesLabel: _formatDateShort(_selectedDate),
        guestsLabel: guestsLabel,
        pickup: 'Colombo Fort - 5:30 AM',
        leadGuest: guest,
        phone: _leadPhoneE164,
        email: _emailCtrl.text.trim(),
        paymentLabel: _paymentMethodLabel(),
        specialRequests: _specialCtrl.text.trim(),
        totalLabel:
            '${widget.tour.currency} ${_formatCurrency(_totalPrice)}',
      );
      final savedTo = await savePdfBytes(
        bytes: bytes,
        baseName: 'bambare_booking_$safeFile',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedTo == null
                ? 'Could not save PDF on this device'
                : 'PDF saved: $savedTo',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not download: $e')),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _specialCtrl.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    if (_currentStep == 2) {
      setState(() => _phoneFieldError = null);
      if (!_formKey.currentState!.validate()) {
        return;
      }
      final phone = _leadPhoneModel();
      final phoneErr = _validateLeadPhone(phone);
      if (phoneErr != null) {
        setState(() => _phoneFieldError = phoneErr);
        return;
      }
      _leadPhoneE164 = _toE164(phone);
    }
    if (_currentStep == 3) {
      await _submitBooking();
      return;
    }
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    }
  }

  Future<void> _submitBooking() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final ref = await _bookingService.createBooking(
        tourId: widget.tour.id,
        tourTitle: widget.tour.title,
        tourImageUrl: widget.tour.imageUrl,
        location: widget.tour.locationLabel,
        travelDate: _selectedDate,
        adults: _adults,
        children: _children,
        rooms: _showRoomsOption ? _rooms : 0,
        totalPrice: _totalPrice,
        subtotalTours: _adultPrice + _childPrice,
        serviceFee: _serviceFee,
        currency: widget.tour.currency,
        pickup: 'Colombo Fort - 5:30 AM',
        durationLabel: '2 Days, 1 Night',
        leadFirstName: _firstNameCtrl.text.trim(),
        leadLastName: _lastNameCtrl.text.trim(),
        phone: _leadPhoneE164,
        email: _emailCtrl.text.trim(),
        nationality: '',
        specialRequests: _specialCtrl.text.trim(),
        paymentMethod: _paymentMethodLabel(),
      );
      if (!mounted) return;
      setState(() {
        _savedReference = ref;
        _submitting = false;
        _currentStep = 4;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save booking: $e')),
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BookingBackgroundLayer(
        child: Stack(
        children: [
          // Background Hero Fade
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 250,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.tour.imageUrl.startsWith('http'))
                  Image.network(widget.tour.imageUrl, fit: BoxFit.cover)
                else
                  Image.asset(
                    widget.tour.imageUrl, 
                    fit: BoxFit.cover,
                    errorBuilder: (_,__,___) => Container(color: Colors.grey.shade300),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.9),
                        _bg,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Column(
            children: [
              SizedBox(height: topPad + 10),
              // App Bar equivalent
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep < 4)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black45),
                        onPressed: _prevStep,
                      )
                    else
                      const SizedBox(width: 48), // Spacer

                    Text(
                      _currentStep == 4 ? 'Confirm Booking' : 'Book Tours',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black38,
                      ),
                    ),
                    const SizedBox(width: 48), // Spacer
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Wizard Progress
              if (_currentStep < 4)
                _WizardIndicator(currentStep: _currentStep),

              // Scrollable Steps Content
              Expanded(
                child: IndexedStack(
                  index: _currentStep - 1,
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                    _buildStep4(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  // ---------------------------------------------------------
  // STEP 1: DATE & GUESTS
  // ---------------------------------------------------------
  Widget _buildStep1() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Inline Calendar embedded in simple Container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10, offset: const Offset(0, 4),
                      )
                    ]
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: _accent, 
                        onPrimary: Colors.black87,
                        onSurface: Colors.black87,
                      ),
                    ),
                    child: CalendarDatePicker(
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      onDateChanged: (val) {
                        setState(() => _selectedDate = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  'Number of Guests',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                _CounterRow(
                  label: 'Adults',
                  sub: 'Age 15+',
                  count: _adults,
                  onDec: _adults > 1 ? () => setState(() => _adults--) : null,
                  onInc: _adults < 10 ? () => setState(() => _adults++) : null,
                ),
                const SizedBox(height: 16),
                _CounterRow(
                  label: 'Children',
                  sub: 'Age 3-12',
                  count: _children,
                  onDec: _children > 0 ? () => setState(() => _children--) : null,
                  onInc: _children < 5 ? () => setState(() => _children++) : null,
                ),
                if (_showRoomsOption) ...[
                  const SizedBox(height: 16),
                  _CounterRow(
                    label: 'Rooms',
                    sub: 'Under 3',
                    count: _rooms,
                    onDec: _rooms > 1 ? () => setState(() => _rooms--) : null,
                    onInc: _rooms < 5 ? () => setState(() => _rooms++) : null,
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        // Bottom Total breakdown
        _BottomPricingSection(
          adults: _adults,
          children: _children,
          adultPrice: _adultPrice,
          childPrice: _childPrice,
          serviceFee: _serviceFee,
          totalPrice: _totalPrice,
          onContinue: _nextStep,
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // STEP 2: USER DETAILS FORM
  // ---------------------------------------------------------
  Widget _buildStep2() {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPad + 40),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6D5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Booking Summery', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(widget.tour.title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _IconTextRow(icon: '📅', text: _formatDateShort(_selectedDate)),
                      Text('$_adults Adults, ${(_children > 0 ? '$_children Child' : '')}', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _IconTextRow(icon: '⏱️', text: '2 Days, 1 Night'),
                      Text('LKR ${_formatCurrency(_totalPrice)}', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            Text(
              'Lead Guest Information',
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87),
            ),
            const SizedBox(height: 16),

            _buildLabel('First Name'),
            _buildTextField(_firstNameCtrl, 'Enter first name'),
            
            _buildLabel('Last Name'),
            _buildTextField(_lastNameCtrl, 'Enter last name'),

            _buildLabel('Phone Number'),
            _buildPhoneRow(),

            _buildLabel('Email address'),
            _buildTextField(
              _emailCtrl,
              'Enter email address',
              keyboardType: TextInputType.emailAddress,
              extraValidator: _validateEmailField,
            ),

            _buildLabel('Special Requests'),
            _buildTextField(_specialCtrl, 'Any special requests (optional)', required: false, maxLines: 3),

            const SizedBox(height: 24),
            _ActionButton(label: 'Continue', onTap: _nextStep, isPrimary: true),
            const SizedBox(height: 12),
            _ActionButton(label: 'Back', onTap: _prevStep, isPrimary: false),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 12),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint, {
    bool required = true,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? extraValidator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.plusJakartaSans(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(color: Colors.black38),
        filled: true,
        fillColor: const Color(0xFFFFF6D5).withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (val) {
        if (extraValidator != null) {
          final err = extraValidator(val);
          if (err != null) return err;
        }
        if (required && (val == null || val.trim().isEmpty)) {
          return 'This field is required';
        }
        return null;
      },
    );
  }

  // ---------------------------------------------------------
  // STEP 3: REVIEW SUMMARY
  // ---------------------------------------------------------
  Widget _buildStep3() {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPad + 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tour Review Info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6D5).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.tour.title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.redAccent, size: 14),
                    const SizedBox(width: 4),
                    Text('${widget.tour.locationLabel}, Sri Lanka', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 20),
                _SummaryRow(icon: '📅', label: 'Date', val: _formatDateShort(_selectedDate)),
                _SummaryRow(icon: '👥', label: 'Guests', val: '$_adults Adults, ${(_children > 0 ? '$_children Children' : '')}'),
                const _SummaryRow(icon: '⏱️', label: 'Duration', val: '2 Days, 1 Night'),
                const _SummaryRow(icon: '🚖', label: 'Pickup', val: 'Colombo Fort - 5:30 AM'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Price Breakdown
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PRICE BREAKDOWN', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Colors.black54)),
                const SizedBox(height: 16),
                _BreakdownRow(label: 'Tour ($_adults Adults)', amount: 'LKR ${_formatCurrency(_adultPrice)}'),
                if (_children > 0)
                  _BreakdownRow(label: 'Child ($_children)', amount: 'LKR ${_formatCurrency(_childPrice)}'),
                _BreakdownRow(label: 'Service fee', amount: 'LKR ${_formatCurrency(_serviceFee)}'),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Colors.black12, height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Due', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
                    Text('LKR ${_formatCurrency(_totalPrice)}', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildPaymentMethodSection(),
          const SizedBox(height: 16),

          // Cancellation Policy
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A Cancellation Policy', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFE8B800))),
                const SizedBox(height: 6),
                Text('> 7 days before - Full refund\n< 3-7 days before - 50% refund\n< 3 days before - No refund', style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.5, color: Colors.black87)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6D5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Booking will be confirmed immediately. Our team will contact you with further details.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.4, color: Colors.black87),
            ),
          ),

          const SizedBox(height: 24),
          _ActionButton(
            label: _submitting ? 'Saving…' : 'Continue',
            onTap: _submitting ? null : () => _nextStep(),
            isPrimary: true,
          ),
          const SizedBox(height: 12),
          _ActionButton(
            label: 'Back',
            onTap: _submitting ? null : _prevStep,
            isPrimary: false,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // STEP 4: SUCCESS CONFIRMATION
  // ---------------------------------------------------------
  Widget _buildStep4() {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPad + 40),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Giant Checkmark
          Container(
            width: 90, height: 90,
            decoration: const BoxDecoration(
              color: Color(0xFFA5D6A7),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.check_box_rounded, color: Colors.white, size: 50),
            ),
          ),
          const SizedBox(height: 24),

          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black87),
              children: const [
                TextSpan(text: 'Booking '),
                TextSpan(text: 'Confirmed!', style: TextStyle(color: Color(0xFF4CAF50))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your ${widget.tour.title} adventure is all set!\nConfirmation sent to ${_emailCtrl.text.isNotEmpty ? _emailCtrl.text : "your email"}.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 32),

          // Receipt Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ]
            ),
            child: Column(
              children: [
                Text('BOOKING REFERENCE', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Colors.black54)),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: const Color(0xFFFFF6D5), borderRadius: BorderRadius.circular(8)),
                  alignment: Alignment.center,
                  child: Text(_savedReference ?? '—', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87)),
                ),
                const SizedBox(height: 24),
                _ReceiptRow(label: 'Tour', val: widget.tour.title),
                _ReceiptRow(label: 'Date', val: _formatDateShort(_selectedDate)),
                _ReceiptRow(label: 'Guests', val: '$_adults Adults${(_children > 0 ? ', $_children Child' : '')}'),
                const _ReceiptRow(label: 'Pickup', val: 'Colombo Fort - 5:30 AM'),
                _ReceiptRow(label: 'Payment', val: _paymentMethodLabel()),
                _ReceiptRow(label: 'Total Paid', val: 'LKR ${_formatCurrency(_totalPrice)}', isBold: true),
                const SizedBox(height: 24),
                // Barcode fake
                Container(
                  height: 4, width: 140,
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          _ActionButton(
            label: 'View Booking',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MyBookingsScreen(),
                ),
              );
            },
            isPrimary: true,
          ),
          const SizedBox(height: 12),
          _ActionButton(
            label: _downloading ? 'Preparing…' : 'Download',
            onTap: _downloading ? null : _downloadBookingReceipt,
            isPrimary: false,
          ),
          const SizedBox(height: 12),
          _ActionButton(
            label: 'Back', 
            onTap: () {
              Navigator.of(context)
                ..pop()
                ..pop(); // Return home/tours
            }, 
            isPrimary: false
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// REUSABLE WIZARD COMPONENTS
// ---------------------------------------------------------

class _WizardIndicator extends StatelessWidget {
  final int currentStep;
  const _WizardIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StepCircle(num: 1, isActive: currentStep >= 1),
          _StepLine(isActive: currentStep >= 2),
          _StepCircle(num: 2, isActive: currentStep >= 2),
          _StepLine(isActive: currentStep >= 3),
          _StepCircle(num: 3, isActive: currentStep >= 3),
          _StepLine(isActive: currentStep >= 4),
          _StepCircle(num: 4, isActive: currentStep >= 4),
        ],
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int num;
  final bool isActive;
  const _StepCircle({required this.num, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE8B800) : Colors.black12,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$num',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w800,
            color: isActive ? Colors.black87 : Colors.black45,
          ),
        ),
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool isActive;
  const _StepLine({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 3,
        color: isActive ? const Color(0xFFE8B800) : Colors.black12,
      ),
    );
  }
}

// ---------------------------------------------------------
// STEP 1 COMPONENTS
// ---------------------------------------------------------

class _CounterRow extends StatelessWidget {
  final String label;
  final String sub;
  final int count;
  final VoidCallback? onDec;
  final VoidCallback? onInc;

  const _CounterRow({required this.label, required this.sub, required this.count, this.onDec, this.onInc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6D5).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
                Text(sub, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
          _CircBtn(icon: Icons.remove, onTap: onDec),
          SizedBox(
            width: 40,
            child: Center(
              child: Text('$count', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
            ),
          ),
          _CircBtn(icon: Icons.add, onTap: onInc),
        ],
      ),
    );
  }
}

class _CircBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CircBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFC0DAEF).withValues(alpha: 0.6), // Mockup shows a light blue tint
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: onTap != null ? Colors.blue.shade800 : Colors.black26),
      ),
    );
  }
}

class _BottomPricingSection extends StatelessWidget {
  final int adults;
  final int children;
  final double adultPrice;
  final double childPrice;
  final double serviceFee;
  final double totalPrice;
  final VoidCallback onContinue;

  const _BottomPricingSection({
    required this.adults, required this.children, required this.adultPrice, required this.childPrice, required this.serviceFee, required this.totalPrice, required this.onContinue
  });

  String _fmt(double a) {
    final s = a.round().toString();
    final buf = StringBuffer('');
    for (var i = 0; i < s.length; i++) {
        final fromEnd = s.length - i;
        if (i > 0 && fromEnd % 3 == 0) buf.write(',');
        buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))
        ]
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPad + 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Adult x $adults', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
              Text('LKR ${_fmt(adultPrice)}', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
            ],
          ),
          if (children > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Child x $children', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
                Text('LKR ${_fmt(childPrice)}', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Service fee', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
              Text('LKR ${_fmt(serviceFee)}', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.black12, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
              Text('LKR ${_fmt(totalPrice)}', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 20),
          _ActionButton(label: 'Continue', onTap: onContinue, isPrimary: true),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// SHARED UI COMPONENTS
// ---------------------------------------------------------

class _IconTextRow extends StatelessWidget {
  final String icon;
  final String text;
  const _IconTextRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String icon;
  final String label;
  final String val;
  const _SummaryRow({required this.icon, required this.label, required this.val});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 24, child: Text(icon, style: const TextStyle(fontSize: 14))),
          SizedBox(width: 70, child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54))),
          const SizedBox(width: 10),
          Expanded(child: Text(val, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87), textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String amount;
  const _BreakdownRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.black54)),
          Text(amount, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
        ],
      ),
    );
  }
}

class _PaymentMethodOptionTile extends StatelessWidget {
  const _PaymentMethodOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.selected,
    required this.borderColor,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool selected;
  final Color borderColor;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFFFF6D5).withValues(alpha: 0.85)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? accent : borderColor,
              width: selected ? 2 : 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF4E342E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        height: 1.3,
                        color: Colors.brown.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: accent, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String val;
  final bool isBold;
  const _ReceiptRow({required this.label, required this.val, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black54))),
          Expanded(child: Text(val, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600, color: Colors.black87), textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;
  const _ActionButton({required this.label, required this.onTap, required this.isPrimary});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? const Color(0xFFE8B800) : const Color(0xFFFFF6D5),
          foregroundColor: Colors.black87,
          elevation: isPrimary ? 2 : 0,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // Stadium like mockup
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
