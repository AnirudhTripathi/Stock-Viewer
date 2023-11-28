import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class Stock {
  String symbol;
  double price;
  final String name;
  int refreshInterval;

  Stock({
    required this.symbol,
    required this.price,
    required this.name,
    required this.refreshInterval,
  });
}

class StockProvider extends ChangeNotifier {
  List<Stock> stocks = [];

  void addStock(Stock stock) {
    stocks.add(stock);
    notifyListeners();
  }

  Future<void> updateStockPrices() async {
    for (var stock in stocks) {
      double newPrice = await simulateStockPriceUpdate();
      stock.price = newPrice;
    }
    notifyListeners();
  }

  Future<double> simulateStockPriceUpdate() async {
    await Future.delayed(Duration(seconds: 1));
    return Random().nextDouble() * 100;
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'lato',
        colorSchemeSeed: Colors.deepPurpleAccent.shade100,
        useMaterial3: true,
      ),
      home: ChangeNotifierProvider(
        create: (context) => StockProvider(),
        child: StocksListScreen(),
      ),
    );
  }
}

class StocksListScreen extends StatefulWidget {
  @override
  _StocksListScreenState createState() => _StocksListScreenState();
}

class _StocksListScreenState extends State<StocksListScreen> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent.shade100,
        elevation: 3,
        shadowColor: Colors.grey.shade700,
        centerTitle: true,
        title: const Text(
          'Stock Viewer',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 25),
          const Text(
            'Enter the number of Stocks upto 10',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.only(left: 25, right: 25, top: 5),
            child: Form(
              key: _formKey,
              child: TextFormField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      width: 1,
                      color: Colors.transparent,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(25)),
                  ),
                  labelText: 'Enter the number',
                  filled: true,
                  fillColor: Colors.brown.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a number';
                  }
                  return null;
                },
              ),
            ),
          ),
          const SizedBox(height: 15),
          FilledButton(
            onPressed: () {
              if (_formKey.currentState?.validate() == true) {
                int numberOfStocks = int.parse(_controller.text);
                _fetchStocks(numberOfStocks);
              }
            },
            child: const Text(
              'Check Stocks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Consumer<StockProvider>(
              builder: (context, stockProvider, _) {
                return ListView.builder(
                  itemCount: stockProvider.stocks.length,
                  itemBuilder: (context, index) {
                    var stock = stockProvider.stocks[index];
                    return Container(
                      height: 80,
                      padding: const EdgeInsets.all(8.0),
                      margin: const EdgeInsets.only(
                          left: 10, right: 10, bottom: 10),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                                offset: Offset(0, 5),
                                color: const Color.fromARGB(255, 255, 205, 189)
                                    .withOpacity(.1),
                                spreadRadius: 1,
                                blurRadius: 10)
                          ] // BoxShado
                          ),
                      child: ListTile(
                        title: Text('${stock.symbol} - ${stock.name}'),
                        subtitle:
                            Text('Price: \$${stock.price.toStringAsFixed(2)}'),
                        trailing: Text('Interval: ${stock.refreshInterval}s'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Provider.of<StockProvider>(context, listen: false)
              .updateStockPrices();
        },
        child: const Icon(Icons.update),
      ),
    );
  }

  void _fetchStocks(int numberOfStocks) async {
    try {
      final List<Map<String, String>> stockData = [
        {'symbol': 'AAPL', 'name': 'Apple Inc.'},
        {'symbol': 'GOOGL', 'name': 'Alphabet Inc.'},
        {'symbol': 'MSFT', 'name': 'Microsoft Corporation'},
        {'symbol': 'TSLA', 'name': 'Tesla Inc'},
        {'symbol': 'AMZN', 'name': 'Amazon.com Inc'},
        {'symbol': 'NFLX', 'name': 'Netflix Inc'},
        {'symbol': 'NVDA', 'name': 'NVIDIA Corp'},
        {'symbol': 'PYPL', 'name': 'PayPal Holdings Inc'},
        {'symbol': 'ADBE', 'name': 'Adobe Inc'},
        {
          'symbol': 'IBM',
          'name': 'International Business Machines Corporation'
        },
      ];

      final List<Stock> stocks = [];

      for (int i = 0; i < min(numberOfStocks, stockData.length); i++) {
        final Map<String, String> stockInfo = stockData[i];

        final Stock stock = Stock(
          symbol: stockInfo['symbol']!,
          name: stockInfo['name']!,
          price: 0.0,
          refreshInterval: Random().nextInt(5) + 1,
        );

        stocks.add(stock);
      }

      Provider.of<StockProvider>(context, listen: false).stocks.clear();
      Provider.of<StockProvider>(context, listen: false).stocks.addAll(stocks);

      await _fetchPreviousClose(stocks);
    } catch (error) {
      print('Error fetching stocks: $error');
    }
  }

  Future<void> _fetchPreviousClose(List<Stock> stocks) async {
    try {
      final List<Map<String, dynamic>> previousCloseData = [];

      for (var stock in stocks) {
        final response = await http.get(
          Uri.parse(
              'https://api.polygon.io/v2/aggs/ticker/${stock.symbol}/prev?apiKey=w3hHjT3eajQdtKDBsPytPp0MQmkElQjq'),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          final double previousClose = data['results'][0]['c'];

          previousCloseData.add({
            'symbol': stock.symbol,
            'previousClose': previousClose,
          });
        } else {
          print('Failed to fetch previous close for ${stock.symbol}');
        }
      }

      await _storePreviousCloseData(previousCloseData);
    } catch (error) {
      print('Error fetching previous close data: $error');
    }
  }

  Future<void> _storePreviousCloseData(List<Map<String, dynamic>> data) async {
  try {
    // Convert List<Map<String, dynamic>> to List<List<dynamic>>
    final List<List<dynamic>> csvData = data.map((row) => row.values.toList()).toList();

    final String csvString = ListToCsvConverter().convert(csvData);

    final directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/previous_close_data.csv');
    await file.writeAsString(csvString);

    print('Previous close data stored at: ${file.path}');
  } catch (error) {
    print('Error storing previous close data: $error');
  }
}

}
