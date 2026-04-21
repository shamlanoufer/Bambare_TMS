import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Printable / savable booking confirmation (A4 PDF) with optional header image.
abstract final class BookingReceiptPdf {
  static const _brand = 'BAMBARE TRAVELS';
  static const _gold = PdfColor.fromInt(0xFFE8B800);
  static const _ink = PdfColor.fromInt(0xFF1A1A1A);
  static const _muted = PdfColor.fromInt(0xFF5C5C5C);
  static const _cream = PdfColor.fromInt(0xFFFFF6E8);
  static const _cardBorder = PdfColor.fromInt(0xFFE0D4C5);

  /// Same asset as [BookingBackgroundLayer] — scenic strip + white fade feel when cropped.
  static const String _headerAsset = 'images/home/4.png';

  static Future<Uint8List> build({
    required String reference,
    required String tourTitle,
    required String location,
    required String travelDatesLabel,
    required String guestsLabel,
    required String pickup,
    required String leadGuest,
    required String phone,
    required String email,
    required String paymentLabel,
    required String specialRequests,
    required String totalLabel,
  }) async {
    pw.ImageProvider? headerImage;
    try {
      final data = await rootBundle.load(_headerAsset);
      headerImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      headerImage = null;
    }

    final doc = pw.Document(
      author: _brand,
      creator: _brand,
      title: 'Booking $reference',
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.Container(
          color: PdfColors.white,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _headerBand(headerImage),
              pw.Container(
                color: PdfColors.white,
                padding: const pw.EdgeInsets.fromLTRB(28, 22, 28, 28),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Text(
                      'Booking confirmation',
                      style: pw.TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        color: _muted,
                        fontWeight: pw.FontWeight.normal,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      _brand,
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.SizedBox(height: 18),
                    _referenceStrip(reference),
                    pw.SizedBox(height: 16),
                    _sectionCard(
                      title: 'TRIP DETAILS',
                      rows: [
                        _kv('Tour', tourTitle),
                        _kv('Location', location),
                        _kv('Travel dates', travelDatesLabel),
                        _kv('Guests', guestsLabel),
                        _kv('Pickup', pickup),
                      ],
                    ),
                    pw.SizedBox(height: 12),
                    _sectionCard(
                      title: 'GUEST & PAYMENT',
                      rows: [
                        _kv('Lead guest', leadGuest.isEmpty ? '—' : leadGuest),
                        _kv('Phone', phone.isEmpty ? '—' : phone),
                        _kv('Email', email.isEmpty ? '—' : email),
                        _kv('Payment', paymentLabel),
                        _kv('Special requests', specialRequests.isEmpty ? '—' : specialRequests),
                      ],
                    ),
                    pw.SizedBox(height: 20),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: pw.BoxDecoration(
                        color: _cream,
                        borderRadius: pw.BorderRadius.circular(10),
                        border: pw.Border.all(color: _cardBorder, width: 1),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Total',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: _ink,
                            ),
                          ),
                          pw.Text(
                            totalLabel,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: const PdfColor.fromInt(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 14),
                    pw.Center(
                      child: pw.Text(
                        'Thank you for choosing Bambare Travels.',
                        style: pw.TextStyle(fontSize: 9.5, color: _muted, fontStyle: pw.FontStyle.italic),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return doc.save();
  }

  static pw.Widget _headerBand(pw.ImageProvider? image) {
    if (image == null) {
      return pw.Container(
        height: 100,
        color: _gold,
        alignment: pw.Alignment.center,
        child: pw.Text(
          _brand,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
        ),
      );
    }
    return pw.Container(
      height: 118,
      alignment: pw.Alignment.center,
      child: pw.Image(image, fit: pw.BoxFit.cover),
    );
  }

  static pw.Widget _referenceStrip(String reference) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFFF6D5),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE8C84A), width: 1.2),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'BOOKING REFERENCE',
            style: pw.TextStyle(
              fontSize: 9,
              letterSpacing: 0.8,
              fontWeight: pw.FontWeight.bold,
              color: _muted,
            ),
          ),
          pw.Text(
            reference,
            style: pw.TextStyle(
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _sectionCard({
    required String title,
    required List<pw.Widget> rows,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFDFBF7),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _cardBorder, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 9,
              letterSpacing: 1,
              fontWeight: pw.FontWeight.bold,
              color: _muted,
            ),
          ),
          pw.SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  static pw.Widget _kv(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 108,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                color: _muted,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 9.5, color: _ink, lineSpacing: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}
