import 'dart:convert';
import 'package:http/http.dart' as http;

class MarketDataService {
  // TODO: Replace with your actual Twelve Data API key
  static const String _apiKey = '56eeb8405a0545dea76da1b39fa51803'; 
  static const String _baseUrl = 'https://api.twelvedata.com';

  /// Fetches the current price for a given symbol (e.g., "EUR/USD", "XAU/USD")
  /// Renamed from getPrice to getQuotePrice to match usage in AddTradeScreen.
  Future<double?> getQuotePrice(String symbol) async {
    try {
      // Twelve Data format usually requires a slash for forex, e.g., EUR/USD
      // We'll ensure the format is correct.
      String formattedSymbol = symbol;
      if (!symbol.contains('/') && symbol.length == 6) {
        // Convert EURUSD to EUR/USD for the API if needed, 
        // though Twelve Data often accepts both. Let's try raw first.
      }

      final url = Uri.parse('$_baseUrl/price?symbol=$symbol&apikey=$_apiKey');
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check if error is returned
        if (data['code'] != null && data['code'] != 200) {
          print('API Error: ${data['message']}');
          return null;
        }

        if (data['price'] != null) {
          return double.tryParse(data['price'].toString());
        }
      } else {
        print('Server Error: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      print('Network Error fetching price: $e');
      return null;
    }
  }
}