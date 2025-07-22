class InvoiceData {
  final String client;
  final List<Map<String, dynamic>> items;
  final double total;

  InvoiceData({required this.client, required this.items, required this.total});

  Map<String, dynamic> toMap() {
    return {'client': client, 'items': items, 'total': total};
  }

  factory InvoiceData.fromMap(Map<String, dynamic> map) {
    return InvoiceData(
      client: map['client'],
      items: List<Map<String, dynamic>>.from(map['items']),
      total: map['total'],
    );
  }
}
