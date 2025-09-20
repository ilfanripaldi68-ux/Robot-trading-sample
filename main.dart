import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(RobotTradingApp(notifications: flutterLocalNotificationsPlugin));
}

class RobotTradingApp extends StatelessWidget {
  final FlutterLocalNotificationsPlugin notifications;
  const RobotTradingApp({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Robot Trading Signal',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TradingHome(notifications: notifications),
    );
  }
}

class TradingHome extends StatefulWidget {
  final FlutterLocalNotificationsPlugin notifications;
  const TradingHome({super.key, required this.notifications});

  @override
  State<TradingHome> createState() => _TradingHomeState();
}

class _TradingHomeState extends State<TradingHome> {
  String signal = "Belum ada sinyal";
  String sl = "-";
  List<FlSpot> spots = [];
  double time = 0;
  double lastPrice = 1000;
  Timer? timer;
  final Random rnd = Random();

  @override
  void initState() {
    super.initState();
    // initialize chart data
    for (int i = 0; i < 30; i++) {
      spots.add(FlSpot(i.toDouble(), lastPrice));
      time = i.toDouble();
    }
    // start realtime simulation
    timer = Timer.periodic(Duration(seconds: 1), (_) => _addPriceTick());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _addPriceTick() {
    // simulate small random walk
    final change = (rnd.nextDouble() - 0.5) * 10; // +/-5
    lastPrice = (lastPrice + change).clamp(0.0, double.infinity);
    time += 1;
    spots.add(FlSpot(time, lastPrice));
    if (spots.length > 120) {
      spots.removeAt(0);
      // shift x-values to keep them compact
      final base = spots.first.x;
      spots = spots.map((s) => FlSpot(s.x - base, s.y)).toList();
      time = spots.last.x;
    }
    setState(() {});
  }

  void _generateSignal({bool? forceBuy}) {
    final isBuy = forceBuy ?? rnd.nextBool();
    final newSl = (rnd.nextInt(80) + 10).toString(); // 10..89 pips
    sl = "$newSl pips";

    setState(() {
      signal = isBuy ? "BUY" : "SELL";
    });

    _showNotification("$signal - SL: $sl");
  }

  Future<void> _showNotification(String message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'trading_channel',
      'Trading Signals',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await widget.notifications.show(
      0,
      'Trading Signal',
      message,
      platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Robot Trading Signal")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Sinyal saat ini",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(height: 6),
                          Text(signal,
                              style: TextStyle(
                                  fontSize: 20,
                                  color: signal == "BUY"
                                      ? Colors.green
                                      : signal == "SELL"
                                          ? Colors.red
                                          : Colors.black,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 6),
                          Text("SL: $sl"),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _generateSignal(),
                      child: Text("Generate"),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            Expanded(
              child: Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: LineChart(
                    LineChartData(
                      minY: spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 10,
                      maxY: spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 10,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(show: false),
                        )
                      ],
                      titlesData: FlTitlesData(show: false),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _generateSignal(forceBuy: true),
                  icon: Icon(Icons.trending_up),
                  label: Text("Force BUY"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                ElevatedButton.icon(
                  onPressed: () => _generateSignal(forceBuy: false),
                  icon: Icon(Icons.trending_down),
                  label: Text("Force SELL"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text("Data harga simulasi (realtime): ${lastPrice.toStringAsFixed(2)}"),
          ],
        ),
      ),
    );
  }
}
