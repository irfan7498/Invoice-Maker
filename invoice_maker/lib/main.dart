import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart'; // ✅ This is required for PdfPageFormat
import 'package:pdf/widgets.dart' as pw; // For PDF layout
import 'package:printing/printing.dart'; // For printing/export
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'history_page.dart';
import 'invoice_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDocDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocDir.path);

  await Hive.openBox('invoices'); // This is our local box for invoice storage

  runApp(InvoiceApp());
}

class InvoiceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invoice Maker',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: InvoicePage(),
    );
  }
}

class InvoiceItem {
  TextEditingController nameController = TextEditingController();
  TextEditingController qtyController = TextEditingController();
  TextEditingController priceController = TextEditingController();
}

class InvoicePage extends StatefulWidget {
  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  List<InvoiceItem> items = [InvoiceItem()];
  String invoiceText = '';
  double total = 0.0;
  final clientController = TextEditingController();

  void addItem() {
    setState(() {
      items.add(InvoiceItem());
    });
  }

  void generateInvoice() {
    double sum = 0.0;
    StringBuffer buffer = StringBuffer();
    buffer.writeln("Client: ${clientController.text}\n");

    for (var item in items) {
      String name = item.nameController.text;
      int qty = int.tryParse(item.qtyController.text) ?? 0;
      double price = double.tryParse(item.priceController.text) ?? 0.0;
      double totalPrice = qty * price;

      buffer.writeln("$name  x$qty  = ₹$totalPrice");
      sum += totalPrice;
    }

    buffer.writeln("\nTotal Amount: ₹${sum.toStringAsFixed(2)}");

    setState(() {
      invoiceText = buffer.toString();
      total = sum;
    });
    saveInvoiceToLocal();
  }

  void generatePDFInvoice() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Invoice",
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                "Client: ${clientController.text}",
                style: pw.TextStyle(fontSize: 18),
              ),
              pw.SizedBox(height: 20),

              pw.Table.fromTextArray(
                headers: ['Item', 'Qty', 'Price', 'Total'],
                data: items.map((item) {
                  final name = item.nameController.text;
                  final qty = int.tryParse(item.qtyController.text) ?? 0;
                  final price =
                      double.tryParse(item.priceController.text) ?? 0.0;
                  final total = qty * price;
                  return [
                    name,
                    '$qty',
                    '₹$price',
                    '₹${total.toStringAsFixed(2)}',
                  ];
                }).toList(),
              ),

              pw.SizedBox(height: 20),
              pw.Text(
                "Total Amount: ₹${total.toStringAsFixed(2)}",
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );

    // Preview or print PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  void saveInvoiceToLocal() {
    final box = Hive.box('invoices');

    List<Map<String, dynamic>> invoiceItems = items.map((item) {
      return {
        'name': item.nameController.text,
        'qty': int.tryParse(item.qtyController.text) ?? 0,
        'price': double.tryParse(item.priceController.text) ?? 0.0,
      };
    }).toList();

    InvoiceData invoice = InvoiceData(
      client: clientController.text,
      items: invoiceItems,
      total: total,
    );

    box.add(invoice.toMap());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Invoice Maker')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: clientController,
              decoration: InputDecoration(labelText: "Client Name"),
            ),
            SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (_, index) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: items[index].nameController,
                            decoration: InputDecoration(labelText: 'Item Name'),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: items[index].qtyController,
                            decoration: InputDecoration(labelText: 'Qty'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: items[index].priceController,
                            decoration: InputDecoration(labelText: 'Price'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    Divider(),
                  ],
                );
              },
            ),
            ElevatedButton(onPressed: addItem, child: Text("Add Item")),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: generateInvoice,
              child: Text("Generate Invoice"),
            ),
            ElevatedButton.icon(
              onPressed: generatePDFInvoice,
              icon: Icon(Icons.picture_as_pdf),
              label: Text("Export as PDF"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => HistoryPage()),
                );
              },
              child: Text("View Saved "),
            ),

            SizedBox(height: 20),
            if (invoiceText.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade100,
                ),
                child: Text(invoiceText, style: TextStyle(fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }
}
