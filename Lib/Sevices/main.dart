// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/api_service.dart';
import 'utils/signal_generator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  runApp(MyApp(notifications: flutterLocalNotificationsPlugin));
}

class MyApp extends StatelessWidget {
  final FlutterLocalNotificationsPlugin notifications;
  const MyApp({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Robot Trading Signal',
      debugShowCheckedModeBanner: false,
      home: HomeScreen(notifications: notifications),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final FlutterLocalNotificationsPlugin notifications;
  const HomeScreen({super.key, required this.notifications});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum DataSource { forex, crypto }

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  final List<double> prices = [];
  Timer? timer;
  double lastPrice = 0;
  String signal = "Belum ada sinyal";
  String selectedPair = 'EUR/USD';
  DataSource source = DataSource.forex;
  int pollingSeconds = 10;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _fetchTick();
    timer = Timer.periodic(Duration(seconds: pollingSeconds), (_) => _fetchTick());
  }

  Future<void> _fetchTick() async {
    double? p;
    if (source == DataSource.forex) {
      p = await _api.fetchForexLatest(selectedPair);
    } else {
      final symbol = selectedPair.replaceAll('/', '').toUpperCase();
      p = await _api.fetchCryptoLatest(symbol);
    }

    if (p != null) {
      setState(() {
        lastPrice = p!;
        prices.add(p);
        if (prices.length > 120) prices.removeAt(0);
      });

      final s = generateSignalFromPrices(prices, shortN: 5, longN: 20);
      if (s != null && s != signal) {
        setState(() => signal = s);
        _showNotification(s, lastPrice);
      }
    }
  }

  Future<void> _showNotification(String s, double price) async {
    const androidDetails = AndroidNotificationDetails(
      'trading_channel',
      'Trading Signals',
      importance: Importance.high,
      priority: Priority.high,
    );
    const d = NotificationDetails(android: androidDetails);
    await widget.notifications.show(0, 'Signal: $s', 'Price: $price', d);
  }

  List<FlSpot> _toSpots() {
    final list = <FlSpot>[];
    for (int i = 0; i < prices.length; i++) {
      list.add(FlSpot(i.toDouble(), prices[i]));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final spots = _toSpots();
    double minY = spots.isEmpty ? 0 : spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.isEmpty ? 1 : spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('Robot Trading - Forex & Crypto')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<DataSource>(
                value: source,
                items: [
                  DropdownMenuItem(value: DataSource.forex, child: Text('Forex')),
                  DropdownMenuItem(value: DataSource.crypto, child: Text('Crypto')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    source = v;
                    selectedPair = source == DataSource.forex ? 'EUR/USD' : 'BTCUSDT';
                    prices.clear();
                    signal = 'Belum ada sinyal';
                  });
                },
                decoration: InputDecoration(labelText: 'Sumber Data'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: selectedPair,
                decoration: InputDecoration(labelText: 'Pair (e.g. EUR/USD or BTCUSDT)'),
                onChanged: (v) => setState(() => selectedPair = v),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(children: [
                Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Sinyal: $signal',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: signal == 'BUY'
                              ? Colors.green
                              : signal == 'SELL'
                                  ? Colors.red
                                  : Colors.black)),
                  Text('Harga: ${lastPrice.toStringAsFixed(6)}'),
                ])),
                ElevatedButton(
                    onPressed: () {
                      _fetchTick();
                    },
                    child: Text('Refresh'))
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: spots.isEmpty
                    ? Center(child: Text('Menunggu data...'))
                    : LineChart(
                        LineChartData(
                          minY: minY - (0.1 * (maxY - minY + 1)),
                          maxY: maxY + (0.1 * (maxY - minY + 1)),
                          lineBarsData: [
                            LineChartBarData(spots: spots, isCurved: true, dotData: FlDotData(show: false))
                          ],
                          titlesData: FlTitlesData(show: false),
                          gridData: FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
} 
// lib/utils/signal_generator.dart
String? generateSignalFromPrices(List<double> prices, {int shortN = 5, int longN = 20}) {
  if (prices.length < longN) return null;
  double ma(List<double> arr, int n) {
    final sub = arr.sublist(arr.length - n);
    return sub.reduce((a, b) => a + b) / sub.length;
  }

  final prevPrices = prices.sublist(0, prices.length - 1);
  if (prevPrices.length < longN) return null;

  final prevShort = ma(prevPrices, shortN);
  final prevLong = ma(prevPrices, longN);

  final curShort = ma(prices, shortN);
  final curLong = ma(prices, longN);

  if (prevShort <= prevLong && curShort > curLong) {
    return "BUY";
  } else if (prevShort >= prevLong && curShort < curLong) {
    return "SELL";
  }
  return null;
} 
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
name: forex_crypto_signal_app
description: Robot trading demo - forex + crypto realtime (demo).
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ">=2.18.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
  flutter_local_notifications: ^17.2.2
  fl_chart: ^0.60.0
  http: ^0.13.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/
