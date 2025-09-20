// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String twelveApiKey = 'YOUR_TWELVEDATA_KEY';

  Future<double?> fetchForexLatest(String pair) async {
    try {
      final url = Uri.parse(
          'https://api.twelvedata.com/time_series?symbol=$pair&interval=1min&outputsize=1&apikey=$twelveApiKey');
      final resp = await http.get(url).timeout(Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final j = json.decode(resp.body);
        if (j['values'] != null && j['values'].isNotEmpty) {
          final priceStr = j['values'][0]['close'];
          return double.tryParse(priceStr);
        }
      }
    } catch (e) {}
    return null;
  }

  Future<double?> fetchCryptoLatest(String symbol) async {
    try {
      final url = Uri.parse('https://api.binance.com/api/v3/ticker/price?symbol=$symbol');
      final resp = await http.get(url).timeout(Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final j = json.decode(resp.body);
        final priceStr = j['price'];
        return double.tryParse(priceStr);
      }
    } catch (e) {}
    return null;
  }
}
