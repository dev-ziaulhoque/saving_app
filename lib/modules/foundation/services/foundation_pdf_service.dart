import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../data/models/foundation_report_model.dart';

/// Renders with Flutter first so Bengali conjuncts and vowel signs remain
/// correctly shaped, then embeds each high-resolution A4 page in the PDF.
class FoundationPdfService {
  static Future<void> share(FoundationReportModel report) async {
    final renderer = _ModernReportRenderer(report);
    final pages = await renderer.render();
    final document = pw.Document(
      title: 'Foundation Financial Statement',
      author: 'SaveSmart',
      subject: 'Savings, investment, profit and expense report',
    );
    for (final page in pages) {
      document.addPage(pw.Page(
        pageFormat: pdf.PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Image(pw.MemoryImage(page), fit: pw.BoxFit.fill),
      ));
    }
    final directory = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
    final file = File('${directory.path}/foundation-statement-$stamp.pdf');
    await file.writeAsBytes(await document.save(), flush: true);
    await Share.shareXFiles([XFile(file.path)],
        text: 'আগামীর প্রত্যাশা ফাউন্ডেশন — আর্থিক প্রতিবেদন');
  }
}

class _ModernReportRenderer {
  _ModernReportRenderer(this.report);

  final FoundationReportModel report;
  static const width = 1240.0;
  static const height = 1754.0;
  static const margin = 64.0;
  static const navy = Color(0xff111827);
  static const indigo = Color(0xff4f46e5);
  static const green = Color(0xff059669);
  static const red = Color(0xffdc2626);
  static const slate = Color(0xff64748b);
  static const border = Color(0xffe2e8f0);
  static const soft = Color(0xfff8fafc);

  final money = NumberFormat('#,##0.##');
  final pages = <Uint8List>[];
  late ui.PictureRecorder recorder;
  late Canvas canvas;
  double y = 0;
  int pageNumber = 0;

  String amount(dynamic value) => '৳${money.format(value as num? ?? 0)}';

  Future<List<Uint8List>> render() async {
    _newPage(first: true);
    _summary();
    _section('সদস্যদের সঞ্চয়', 'MEMBER SAVINGS');
    _memberHeader();
    for (var i = 0; i < report.members.length; i++) {
      _memberRow(i + 1, report.members[i]);
    }

    _section('মাসভিত্তিক জমার বিস্তারিত', 'PAYMENT LEDGER');
    for (final member in report.members) {
      final payments = member['payments'] as List? ?? const [];
      if (payments.isNotEmpty) _paymentLedger(member, payments);
    }

    _section('বিনিয়োগ ও আয়', 'INVESTMENTS & RETURNS');
    if (report.investments.isEmpty) {
      _empty('কোনো বিনিয়োগ যোগ করা হয়নি');
    } else {
      for (final investment in report.investments) {
        _investmentCard(investment);
      }
    }

    _section('ফাউন্ডেশনের ব্যয়', 'EXPENSES');
    if (report.expenses.isEmpty) {
      _empty('কোনো ব্যয় যোগ করা হয়নি');
    } else {
      _expenseHeader();
      for (final expense in report.expenses) {
        _expenseRow(expense);
      }
    }
    _note();
    await _finishPage();
    return pages;
  }

  void _newPage({bool first = false}) {
    recorder = ui.PictureRecorder();
    canvas = Canvas(recorder);
    pageNumber++;
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, height),
        Paint()..color = Colors.white);
    canvas.drawRect(
        const Rect.fromLTWH(0, 0, width, 16), Paint()..color = indigo);
    if (first) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(margin, 58, width - margin * 2, 210),
              const Radius.circular(28)),
          Paint()..color = navy);
      canvas.drawCircle(const Offset(width - 145, 105), 92,
          Paint()..color = indigo.withValues(alpha: .7));
      canvas.drawCircle(const Offset(width - 82, 205), 58,
          Paint()..color = green.withValues(alpha: .55));
      _text('আগামীর প্রত্যাশা ফাউন্ডেশন', margin + 34, 91, 38, Colors.white,
          bold: true, maxWidth: 850);
      _text('সর্বমোট সঞ্চয়, বিনিয়োগ ও আর্থিক প্রতিবেদন', margin + 34, 151, 24,
          const Color(0xffcbd5e1),
          maxWidth: 850);
      _text('LIVE FINANCIAL STATEMENT', margin + 34, 207, 15,
          const Color(0xffa5b4fc),
          bold: true, letterSpacing: 2);
      y = 302;
    } else {
      _text('আগামীর প্রত্যাশা ফাউন্ডেশন', margin, 48, 24, navy, bold: true);
      _text('আর্থিক প্রতিবেদন', width - margin - 190, 53, 16, slate);
      canvas.drawLine(
          const Offset(margin, 92),
          const Offset(width - margin, 92),
          Paint()
            ..color = border
            ..strokeWidth = 2);
      y = 120;
    }
  }

  void _summary() {
    final s = report.summary;
    final cards = [
      ('মোট জমা', amount(s['total_collected']), green),
      ('মোট বকেয়া', amount(s['total_due']), red),
      ('মোট বিনিয়োগ', amount(s['total_invested']), indigo),
      ('মোট প্রফিট', amount(s['total_profit']), const Color(0xff0d9488)),
      ('মোট ব্যয়', amount(s['total_expenses']), const Color(0xffea580c)),
      ('বর্তমান নগদ', amount(s['available_cash']), navy),
    ];
    _text('এক নজরে', margin, y, 25, navy, bold: true);
    _text('সর্বশেষ হিসাব অনুযায়ী', margin + 135, y + 7, 14, slate);
    y += 48;
    const gap = 16.0;
    const cardWidth = (width - margin * 2 - gap * 2) / 3;
    for (var i = 0; i < cards.length; i++) {
      final row = i ~/ 3;
      final col = i % 3;
      final x = margin + col * (cardWidth + gap);
      final top = y + row * 112;
      _card(Rect.fromLTWH(x, top, cardWidth, 94));
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, top, 7, 94), const Radius.circular(4)),
          Paint()..color = cards[i].$3);
      _text(cards[i].$1, x + 22, top + 17, 14, slate);
      _text(cards[i].$2, x + 22, top + 45, 23, cards[i].$3,
          bold: true, maxWidth: cardWidth - 40);
    }
    y += 230;
  }

  void _section(String title, String eyebrow) {
    _ensure(92);
    y += 24;
    _text(eyebrow, margin, y, 12, indigo, bold: true, letterSpacing: 1.8);
    _text(title, margin, y + 23, 28, navy, bold: true);
    canvas.drawLine(
        Offset(margin, y + 68),
        Offset(width - margin, y + 68),
        Paint()
          ..color = border
          ..strokeWidth = 2);
    y += 84;
  }

  void _memberHeader() {
    _ensure(52);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(margin, y, width - margin * 2, 44),
            const Radius.circular(10)),
        Paint()..color = navy);
    _text('#  সদস্য', margin + 16, y + 12, 13, Colors.white, bold: true);
    _text('মাসিক', 650, y + 12, 13, Colors.white, bold: true);
    _text('মোট', 790, y + 12, 13, Colors.white, bold: true);
    _text('জমা', 930, y + 12, 13, Colors.white, bold: true);
    _text('বকেয়া', 1060, y + 12, 13, Colors.white, bold: true);
    y += 52;
  }

  void _memberRow(int index, Map<String, dynamic> member) {
    final payments = member['payments'] as List? ?? const [];
    final rowHeight = payments.isEmpty ? 60.0 : 91.0;
    if (!_ensure(rowHeight + 8)) _memberHeader();
    final bg = index.isEven ? soft : Colors.white;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(margin, y, width - margin * 2, rowHeight),
            const Radius.circular(10)),
        Paint()..color = bg);
    _text('$index. ${member['name'] ?? 'সদস্য'}', margin + 16, y + 16, 16, navy,
        bold: true, maxWidth: 530);
    _text(amount(member['monthly_amount']), 650, y + 17, 15, slate);
    _text(amount(member['required']), 790, y + 17, 15, navy, bold: true);
    _text(amount(member['paid']), 930, y + 17, 15, green, bold: true);
    _text(amount(member['due']), 1060, y + 17, 15, red, bold: true);
    if (payments.isNotEmpty) {
      final confirmed =
          payments.where((p) => (p as Map)['status'] == 'confirmed').length;
      _text(
          'মাসভিত্তিক জমা: $confirmed মাস নিশ্চিত • মোট ${payments.length}টি এন্ট্রি',
          margin + 42,
          y + 55,
          12,
          slate,
          maxWidth: 900);
    }
    y += rowHeight + 5;
  }

  void _investmentCard(Map<String, dynamic> item) {
    final profits = item['profits'] as List? ?? const [];
    final boxHeight = 104.0 + (profits.length * 34).clamp(0, 204).toDouble();
    _ensure(boxHeight + 14);
    _card(Rect.fromLTWH(margin, y, width - margin * 2, boxHeight));
    canvas.drawCircle(Offset(margin + 34, y + 35), 17,
        Paint()..color = indigo.withValues(alpha: .13));
    _text('↗', margin + 23, y + 21, 20, indigo, bold: true);
    _text(item['title']?.toString() ?? 'বিনিয়োগ', margin + 62, y + 18, 20, navy,
        bold: true, maxWidth: 550);
    _text('বিনিয়োগ ${amount(item['amount'])}', 770, y + 20, 15, slate);
    _text('আয় ${amount(item['profit_total'])}', 1010, y + 20, 15, green,
        bold: true);
    _text(
        'তারিখ: ${item['invested_at'] ?? '-'}  •  অবস্থা: ${item['status'] ?? '-'}',
        margin + 62,
        y + 54,
        13,
        slate);
    var py = y + 91;
    for (final raw in profits.take(6)) {
      final profit = Map<String, dynamic>.from(raw as Map);
      _text('${profit['profit_month'] ?? '-'}', margin + 62, py, 13, slate);
      _text(amount(profit['amount']), 1010, py, 14, green, bold: true);
      py += 34;
    }
    y += boxHeight + 14;
  }

  void _paymentLedger(Map<String, dynamic> member, List payments) {
    _ensure(62);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(margin, y, width - margin * 2, 48),
            const Radius.circular(9)),
        Paint()..color = const Color(0xffeef2ff));
    _text(
        member['name']?.toString() ?? 'সদস্য', margin + 16, y + 12, 16, indigo,
        bold: true);
    _text('${payments.length}টি এন্ট্রি', width - margin - 125, y + 13, 13,
        slate);
    y += 54;
    for (final raw in payments) {
      final payment = Map<String, dynamic>.from(raw as Map);
      _ensure(44);
      final confirmed = payment['status'] == 'confirmed';
      _text(payment['month']?.toString() ?? '-', margin + 20, y + 10, 13, navy);
      _text(payment['status']?.toString().toUpperCase() ?? '-', 690, y + 10, 11,
          confirmed ? green : const Color(0xffd97706),
          bold: true);
      _text(
          amount(payment['amount']), 1030, y + 9, 14, confirmed ? green : slate,
          bold: true);
      canvas.drawLine(Offset(margin + 14, y + 39),
          Offset(width - margin - 14, y + 39), Paint()..color = border);
      y += 42;
    }
    y += 12;
  }

  void _expenseHeader() {
    _ensure(50);
    canvas.drawRect(Rect.fromLTWH(margin, y, width - margin * 2, 42),
        Paint()..color = const Color(0xfffff7ed));
    _text('তারিখ', margin + 16, y + 11, 13, const Color(0xff9a3412),
        bold: true);
    _text('বিবরণ', 310, y + 11, 13, const Color(0xff9a3412), bold: true);
    _text('ক্যাটাগরি', 820, y + 11, 13, const Color(0xff9a3412), bold: true);
    _text('পরিমাণ', 1040, y + 11, 13, const Color(0xff9a3412), bold: true);
    y += 48;
  }

  void _expenseRow(Map<String, dynamic> expense) {
    if (!_ensure(54)) _expenseHeader();
    _text(expense['expense_date']?.toString() ?? '-', margin + 16, y + 13, 14,
        slate);
    _text(expense['title']?.toString() ?? '-', 310, y + 13, 14, navy,
        bold: true, maxWidth: 470);
    _text(expense['category']?.toString() ?? 'general', 820, y + 13, 13, slate,
        maxWidth: 180);
    _text(amount(expense['amount']), 1040, y + 13, 14, red, bold: true);
    canvas.drawLine(Offset(margin, y + 48), Offset(width - margin, y + 48),
        Paint()..color = border);
    y += 52;
  }

  void _empty(String message) {
    _ensure(76);
    _card(Rect.fromLTWH(margin, y, width - margin * 2, 66));
    _text(message, margin + 22, y + 21, 15, slate);
    y += 78;
  }

  void _note() {
    _ensure(110);
    y += 28;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(margin, y, width - margin * 2, 78),
            const Radius.circular(14)),
        Paint()..color = const Color(0xffeef2ff));
    _text('তথ্যসূত্র', margin + 20, y + 15, 14, indigo, bold: true);
    _text(
        'এই প্রতিবেদন নিশ্চিত payment এবং বর্তমান accounting ledger থেকে স্বয়ংক্রিয়ভাবে তৈরি।',
        margin + 20,
        y + 42,
        13,
        slate,
        maxWidth: width - margin * 2 - 40);
    y += 100;
  }

  bool _ensure(double needed) {
    if (y + needed <= height - 90) return true;
    _finishPageSync();
    _newPage();
    return false;
  }

  void _card(Rect rect) {
    canvas.drawShadow(
        Path()
          ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16))),
        const Color(0x180f172a),
        8,
        false);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)),
        Paint()..color = Colors.white);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(16)),
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  void _text(String text, double x, double top, double size, Color color,
      {bool bold = false, double? maxWidth, double letterSpacing = 0}) {
    final painter = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              fontFamily: 'NotoSansBengali',
              fontFamilyFallback: const ['Nunito'],
              fontSize: size,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: color,
              height: 1.25,
              letterSpacing: letterSpacing)),
      textDirection: ui.TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth ?? width - x - margin);
    painter.paint(canvas, Offset(x, top));
    painter.dispose();
  }

  void _footer() {
    canvas.drawLine(const Offset(margin, height - 65),
        const Offset(width - margin, height - 65), Paint()..color = border);
    _text(
        'SaveSmart • Generated ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
        margin,
        height - 48,
        11,
        slate);
    _text('পৃষ্ঠা $pageNumber', width - margin - 75, height - 48, 11, slate);
  }

  void _finishPageSync() {
    _footer();
    final picture = recorder.endRecording();
    _pendingPictures.add(picture);
  }

  final _pendingPictures = <ui.Picture>[];

  Future<void> _finishPage() async {
    _finishPageSync();
    for (final picture in _pendingPictures) {
      final image = await picture.toImage(width.toInt(), height.toInt());
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      pages.add(data!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    }
    _pendingPictures.clear();
  }
}
