import 'package:bf_control_centre/core/utils/subscription_receipt_template_1.dart';
import 'package:flutter/material.dart' hide EdgeInsets;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart' show PdfPageFormat;
import 'package:pdf/widgets.dart' show MultiPage, Document, Context, EdgeInsets;
import 'package:printing/printing.dart';

class ReceiptPreviewPage extends StatefulWidget {
  const ReceiptPreviewPage({super.key, required this.details});

  final dynamic details;

  @override
  State<ReceiptPreviewPage> createState() => _ReceiptPreviewPageState();
}

class _ReceiptPreviewPageState extends State<ReceiptPreviewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Invoice Preview")),
      body: PdfPreview(
        initialPageFormat: PdfPageFormat.a4,
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: "BillingFast Receipt ${widget.details['id']}.pdf",
        build: (format) async {
          final pdf = Document();
          final logo = (await rootBundle.load('assets/images/logo.png'));
          pdf.addPage(
            MultiPage(
              pageFormat: format,
              margin: EdgeInsets.all(16),
              build: (Context context) => [
                buildSubscriptionReceiptTemplate1(
                  widget.details,
                  logo.buffer.asUint8List(),
                ),
              ],
            ),
          );
          return pdf.save();
        },
      ),
    );
  }
}
