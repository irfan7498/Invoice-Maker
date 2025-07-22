import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'invoice_model.dart';

class HistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final box = Hive.box('invoices');

    return Scaffold(
      appBar: AppBar(title: Text("Saved Invoices")),
      body: ListView.builder(
        itemCount: box.length,
        itemBuilder: (context, index) {
          final map = box.getAt(index);
          final invoice = InvoiceData.fromMap(Map<String, dynamic>.from(map));

          return Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              title: Text("Client: ${invoice.client}"),
              subtitle: Text("Total: ₹${invoice.total.toStringAsFixed(2)}"),
              trailing: Text("${invoice.items.length} items"),
            ),
          );
        },
      ),
    );
  }
}
