import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';

/*
  This is a sample receipt object
  {
		"id": "order_RmGVIYRnDyRSbH",
		"key": "ultra",
		"days": 365,
		"plan": "PREMIUM",
		"time": "2025-12-01T12:59:44.600036",
		"amount": 118,
		"details": {
			"gstIN": "24AAICR6070Q1ZS",
			"address": "266/324, 266/324, Old Labour Colony, Lucknow Division, Lucknow, Uttar Pradesh, India - 226004 ",
			"businessName": "Arham's shop"
		},
		"isUltra": true,
		"currency": "INR",
		"baseAmount": 1
	}
*/

String getBillingPeriod(dynamic details) {
  final time = details['time'];
  final startDate = DateTime.parse(time);
  final endDate = startDate.add(Duration(days: details['days']));
  return "${DateFormat("dd/MM/yyyy").format(startDate)} - ${DateFormat("dd/MM/yyyy").format(endDate)}";
}

Widget buildSubscriptionReceiptTemplate1(dynamic details, dynamic logo) {
  return Container(
    child: Column(
      crossAxisAlignment: .start,
      children: [
        SizedBox(width: double.infinity),
        SizedBox(width: 100, height: 100, child: Image(MemoryImage(logo))),
        SizedBox(height: 10),
        Text(
          "Invoice for Billing Period ${getBillingPeriod(details)}",
          style: TextStyle(fontSize: 20, color: PdfColors.black),
        ),
        SizedBox(height: 10),
        Row(
          crossAxisAlignment: .start,
          mainAxisAlignment: .spaceBetween,
          children: [
            Column(
              mainAxisSize: .min,
              crossAxisAlignment: .start,
              children: [
                Text(
                  "From",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text("Xero Apps Pvt Ltd", style: TextStyle(fontSize: 12)),
                Text(
                  "Malad, Mumbai,\nMaharastra, 400097, INDIA",
                  style: TextStyle(fontSize: 12),
                ),
                Text("GSTIN: 27AAACX3827F1ZC", style: TextStyle(fontSize: 12)),
                Text("HSN Code: 998315", style: TextStyle(fontSize: 12)),
              ],
            ),
            SizedBox(
              width: 270,
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                children: [
                  Text(
                    "Invoice Details",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisAlignment: .spaceBetween,
                    children: [
                      Text("Invoice Number: ", style: TextStyle(fontSize: 12)),
                      Text(
                        "${details['invoiceNo']}",
                        textAlign: .right,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: .spaceBetween,
                    children: [
                      Text("Transaction ID: ", style: TextStyle(fontSize: 12)),
                      Text(
                        "${details['id']}",
                        textAlign: .right,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: .spaceBetween,
                    children: [
                      Text("Date of issue: ", style: TextStyle(fontSize: 12)),
                      Text(
                        DateFormat("dd/MM/yyyy hh:mm:ss a").format(DateTime.parse(details['time'])),
                        textAlign: .right,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          crossAxisAlignment: .start,
          mainAxisAlignment: .spaceBetween,
          children: [
            Column(
              mainAxisSize: .min,
              crossAxisAlignment: .start,
              children: [
                Text(
                  "Bill To & Place of Supply",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  "${details['details']['businessName'] ?? "-"}",
                  style: TextStyle(fontSize: 12),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    "${details['details']['address'] ?? "-"}",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                Text(
                  "GSTIN: ${details['details']['gstIN'] ?? "-"}",
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            SizedBox(
              width: 270,
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                children: [
                  Text(
                    "Plan Details",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisAlignment: .spaceBetween,
                    children: [
                      Text("Plan: ", style: TextStyle(fontSize: 12)),
                      Text(
                        "${details['isUltra'] ? "ULTRA" : details['plan']}",
                        textAlign: .right,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: .spaceBetween,
                    children: [
                      Text("Validity: ", style: TextStyle(fontSize: 12)),
                      Text(
                        "${details['days']} days from Date of Issue",
                        textAlign: .right,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Text(
          "Summary",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            Text("Plan Price: ", style: TextStyle(fontSize: 14)),
            Text(
              "${details['baseAmount'] / 100} ${details['currency']}",
              textAlign: .right,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        if (details['baseAmount'] != details['amount']) ...[
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Text("GST: (18%)", style: TextStyle(fontSize: 12)),
              Text(
                "${(details['amount'] - details['baseAmount']) / 100} ${details['currency']}",
                textAlign: .right,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            Text(
              "Total: ",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              "${details['amount'] / 100} ${details['currency']}",
              textAlign: .right,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    ),
  );
}
