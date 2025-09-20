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
