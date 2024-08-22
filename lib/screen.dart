import 'dart:convert';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:web_socket_channel/web_socket_channel.dart';
// ignore: depend_on_referenced_packages
import 'package:web_socket_channel/status.dart' as status;

class ImprovedCoinListScreen extends StatefulWidget {
  @override
  _ImprovedCoinListScreenState createState() => _ImprovedCoinListScreenState();
}

class _ImprovedCoinListScreenState extends State<ImprovedCoinListScreen> {
  final WebSocketChannel _channel = WebSocketChannel.connect(
    Uri.parse('ws://prereg.ex.api.ampiy.com/prices'),
  );

  List<Map<String, dynamic>> _allCoins = [];
  List<Map<String, dynamic>> _filteredCoins = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _channel.sink.add(json.encode({
      "method": "SUBSCRIBE",
      "params": ["all@ticker"],
      "cid": 1
    }));

    _channel.stream.listen(_onDataReceived);
    _searchController.addListener(_filterCoins);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _channel.sink.close(status.goingAway);
    super.dispose();
  }

  void _onDataReceived(dynamic data) {
    final parsedData = json.decode(data);

    if (parsedData['stream'] == 'all@fpTckr') {
      final List<Map<String, dynamic>> updatedCoins =
          _parseWebSocketData(parsedData['data']);

      setState(() {
        _allCoins = updatedCoins;
        _filterCoins();
      });
    }
  }

  List<Map<String, dynamic>> _parseWebSocketData(List<dynamic> data) {
    return data.map((coin) {
      final String symbol = coin['s'];
      return {
        "name": _getNameForSymbol(symbol),
        "symbol": symbol,
        "price": "₹ ${coin['c']}",
        "change": "${coin['P']}%",
        "icon": _getIconForSymbol(symbol),
        "color": _getColorForSymbol(symbol),
      };
    }).toList();
  }

  void _filterCoins() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCoins = _allCoins.where((coin) {
        final coinName = coin['name'].toLowerCase();
        final coinSymbol = coin['symbol'].toLowerCase();
        return coinName.contains(query) || coinSymbol.contains(query);
      }).toList();
    });
  }

  String _getNameForSymbol(String symbol) {
    switch (symbol) {
      case 'BTCINR':
        return 'Bitcoin';
      case 'ETHINR':
        return 'Ethereum';
      default:
        return symbol;
    }
  }

  IconData _getIconForSymbol(String symbol) {
    switch (symbol) {
      case 'BTCINR':
        return Icons.currency_bitcoin;
      case 'ETHINR':
        return Icons.currency_exchange;
      default:
        return Icons.monetization_on;
    }
  }

  Color _getColorForSymbol(String symbol) {
    switch (symbol) {
      case 'BTCINR':
        return Colors.orange;
      case 'ETHINR':
        return Colors.purple;
      case 'NEOINR':
        return Colors.green;
      case 'LTCINR':
        return Colors.yellow;
      case 'QTUMINR':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coins'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: Colors.tealAccent),
                hintText: 'Search by name...',
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                contentPadding: EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: Colors.white),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCoins.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 3,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _filteredCoins[index]["color"],
                      child: Icon(_filteredCoins[index]["icon"],
                          color: Colors.white),
                    ),
                    title: Text(_filteredCoins[index]["symbol"],
                        style: Theme.of(context).textTheme.bodyText1),
                    subtitle: Text(_filteredCoins[index]["name"],
                        style: Theme.of(context).textTheme.bodyText2),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _filteredCoins[index]["price"],
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _filteredCoins[index]["change"],
                          style: TextStyle(
                              color:
                                  _filteredCoins[index]["change"].contains('-')
                                      ? Colors.redAccent
                                      : Colors.greenAccent,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface,
        backgroundColor:
            Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        elevation: 5,
      ),
    );
  }
}
