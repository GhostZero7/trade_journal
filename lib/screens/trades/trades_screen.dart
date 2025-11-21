// lib/screens/trades/add_trade_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/theme_service.dart';
import '../../providers/trades_provider.dart';
// Ensure this import points to your new service file
import '../../services/market_data_service.dart'; 

class AddTradeScreen extends StatefulWidget {
  const AddTradeScreen({super.key});

  @override
  State<AddTradeScreen> createState() => _AddTradeScreenState();
}

class _AddTradeScreenState extends State<AddTradeScreen> {
  // Controllers
  final _entryCtrl = TextEditingController();
  final _exitCtrl = TextEditingController();
  final _lotCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // Trade values
  // Twelve Data prefers slash format (EUR/USD)
  String _pair = "EUR/USD"; 
  String _type = "Buy";
  double _profit = 0.0;
  bool _loading = false;
  
  // Market Data State
  final _marketService = MarketDataService(); 
  Timer? _priceTimer;
  double? _currentMarketPrice; // Nullable to handle loading state
  bool _isPriceUp = true; 
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _startPriceFeed();
  }

  @override
  void dispose() {
    _priceTimer?.cancel();
    _entryCtrl.dispose();
    _exitCtrl.dispose();
    _lotCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // -----------------------------
  // Market Price Logic
  // -----------------------------
  void _startPriceFeed() {
    _priceTimer?.cancel();
    
    // Fetch immediately on load
    _fetchRealPrice();

    // Update every 15 seconds to respect Free Tier limits
    _priceTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        _fetchRealPrice();
      }
    });
  }

  Future<void> _fetchRealPrice() async {
    // Reset error state if we are retrying manually, 
    // but don't wipe the old price immediately to avoid flickering
    if (_hasError) {
      setState(() => _hasError = false);
    }

    final price = await _marketService.getPrice(_pair);
    
    if (!mounted) return;

    if (price != null) {
      setState(() {
        _hasError = false;
        // Determine if price went up or down compared to last fetch
        if (_currentMarketPrice != null) {
          _isPriceUp = price >= _currentMarketPrice!;
        }
        _currentMarketPrice = price;
      });
    } else {
      // Only show error if we don't have a cached price
      if (_currentMarketPrice == null) {
        setState(() => _hasError = true);
      }
      print("Failed to fetch price for $_pair");
    }
  }

  // Theme helper
  AppColors _getTheme(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context, listen: true);
    return themeService.isDarkMode ? AppColors.dark : AppColors.light;
  }

  // -----------------------------
  // Auto Calculate P/L
  // -----------------------------
  void _calculatePL() {
    double entry = double.tryParse(_entryCtrl.text) ?? 0;
    double exit = double.tryParse(_exitCtrl.text) ?? 0;
    double lots = double.tryParse(_lotCtrl.text) ?? 0;

    if (entry == 0 || exit == 0 || lots == 0) {
      setState(() => _profit = 0);
      return;
    }

    double multiplier = 1.0;
    if (_pair.contains("XAU")) multiplier = 100.0; // Gold usually 100oz contract
    if (_pair.contains("JPY")) multiplier = 1000.0; // JPY pip multiplier

    double result = _type == "Buy" 
        ? (exit - entry) * lots * multiplier
        : (entry - exit) * lots * multiplier;

    setState(() => _profit = result);
  }

  // -----------------------------
  // Save Using Provider
  // -----------------------------
  Future<void> _saveTrade() async {
    if (_entryCtrl.text.isEmpty ||
        _exitCtrl.text.isEmpty ||
        _lotCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final tradeData = {
        "symbol": _pair.replaceAll('/', ''), // Save as EURUSD (no slash) for database consistency if preferred
        "type": _type,
        "amount": double.tryParse(_lotCtrl.text) ?? 0,
        "result": _profit >= 0 ? "Win" : "Loss",
        "profit": _profit,
        "notes": _notesCtrl.text.trim(),
        "createdAt": DateTime.now(),
        "entryPrice": double.tryParse(_entryCtrl.text) ?? 0,
        "exitPrice": double.tryParse(_exitCtrl.text) ?? 0,
      };

      await Provider.of<TradesProvider>(context, listen: false)
          .addTrade(tradeData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Trade added successfully!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving trade: $e")),
      );
    }

    setState(() => _loading = false);
  }

  // -----------------------------
  // Input Field UI Component
  // -----------------------------
  Widget _inputField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    TextInputType type = TextInputType.number,
    Widget? suffix,
  }) {
    final theme = _getTheme(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14, color: theme.textFaded)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: type,
          style: TextStyle(color: theme.textLight),
          onChanged: (_) => _calculatePL(),
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.cardDark,
            suffixIcon: suffix,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.primary.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // -----------------------------
  // MAIN BUILD UI
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    final theme = _getTheme(context);
    
    // Determine decimal formatting
    int decimals = _pair.contains("JPY") ? 2 : (_pair.contains("XAU") ? 2 : 5);
    
    // Build the Price String or Error Message
    String priceDisplay = "Loading...";
    if (_hasError) {
      priceDisplay = "Offline";
    } else if (_currentMarketPrice != null) {
      priceDisplay = _currentMarketPrice!.toStringAsFixed(decimals);
    }

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text("Add Trade", style: TextStyle(color: theme.textLight)),
        backgroundColor: theme.background,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.textLight),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Pair Dropdown
          Text("Instrument",
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: theme.textFaded)),
          const SizedBox(height: 6),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.cardDark,
              border: Border.all(color: theme.primary.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _pair,
                dropdownColor: theme.cardDark,
                style: TextStyle(color: theme.textLight, fontSize: 16, fontWeight: FontWeight.w600),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: "EUR/USD", child: Text("EUR/USD")),
                  DropdownMenuItem(value: "GBP/USD", child: Text("GBP/USD")),
                  DropdownMenuItem(value: "XAU/USD", child: Text("XAU/USD (Gold)")),
                  DropdownMenuItem(value: "USD/JPY", child: Text("USD/JPY")),
                ],
                onChanged: (v) {
                  setState(() {
                    _pair = v!;
                    _currentMarketPrice = null; // Clear old price
                    _hasError = false; 
                    _startPriceFeed(); // Restart feed for new pair
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 20),
          
          // ==============================
          // LIVE MARKET PRICE CARD
          // ==============================
          GestureDetector(
            onTap: () {
              // Retry on tap if error
              if (_hasError) {
                 _fetchRealPrice();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: theme.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _hasError 
                      ? theme.error 
                      : (_isPriceUp ? theme.success.withOpacity(0.3) : theme.error.withOpacity(0.3)),
                  width: 1
                ),
                boxShadow: [
                   BoxShadow(
                    color: _hasError 
                        ? Colors.transparent 
                        : (_isPriceUp ? theme.success : theme.error).withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                   )
                ]
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Current $_pair Price", 
                        style: TextStyle(color: theme.textFaded, fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Price or Error Icon
                          _hasError 
                              ? Icon(Icons.wifi_off, color: theme.error, size: 24)
                              : Text(priceDisplay, 
                                  style: TextStyle(
                                    color: theme.textLight, 
                                    fontSize: 24, 
                                    fontWeight: FontWeight.bold
                                  )
                                ),
                          
                          const SizedBox(width: 8),
                          
                          // Trend Arrow or Refresh Icon
                          if (!_hasError && _currentMarketPrice != null)
                            Icon(
                              _isPriceUp ? Icons.arrow_upward : Icons.arrow_downward,
                              color: _isPriceUp ? theme.success : theme.error,
                              size: 18,
                            )
                        ],
                      ),
                    ],
                  ),
                  
                  // "Use" Button
                  ElevatedButton.icon(
                    onPressed: (_currentMarketPrice == null || _hasError) 
                        ? null // Disable if no data
                        : () {
                            _entryCtrl.text = _currentMarketPrice!.toStringAsFixed(decimals);
                            _calculatePL();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Entry set to $_pair price"),
                                duration: const Duration(milliseconds: 800),
                                backgroundColor: theme.primary,
                              )
                            );
                          },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text("Use"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.background,
                      foregroundColor: theme.primary,
                      elevation: 0,
                      side: BorderSide(color: theme.primary.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                    ),
                  )
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Buy / Sell Toggle
          Row(children: [
            _typeButton("Buy", theme.success, context),
            const SizedBox(width: 12),
            _typeButton("Sell", theme.error, context),
          ]),

          const SizedBox(height: 20),

          // Input fields
          _inputField(
            context: context, 
            label: "Entry Price", 
            controller: _entryCtrl,
            suffix: IconButton(
              icon: Icon(Icons.refresh, color: theme.textFaded, size: 20),
              onPressed: () => _entryCtrl.clear(),
            )
          ),
          const SizedBox(height: 16),

          _inputField(context: context, label: "Exit Price", controller: _exitCtrl),
          const SizedBox(height: 16),

          _inputField(context: context, label: "Lots / Size", controller: _lotCtrl),
          const SizedBox(height: 20),

          // Profit Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _profit >= 0
                  ? theme.success.withOpacity(0.15)
                  : theme.error.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Estimated P/L:",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textLight)),
                Text(
                  _profit >= 0 ? "+${_profit.toStringAsFixed(2)}" : _profit.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _profit >= 0 ? theme.success : theme.error,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Notes
          _inputField(
            context: context,
            label: "Notes",
            controller: _notesCtrl,
            type: TextInputType.text,
          ),

          const SizedBox(height: 30),

          // Save Button
          _loading
              ? Center(child: CircularProgressIndicator(color: theme.primary))
              : ElevatedButton(
                  onPressed: _saveTrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: theme.cardDark,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                    shadowColor: theme.primary.withOpacity(0.4),
                  ),
                  child: const Text(
                    "Save Trade",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  // -----------------------------
  // BUY / SELL Button
  // -----------------------------
  Widget _typeButton(String label, Color color, BuildContext context) {
    final bool active = _type == label;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = label;
          _calculatePL();
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? color : color.withOpacity(0.4), width: 1.5),
            boxShadow: active ? [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ] : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
                color: active ? Colors.white : color,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
        ),
      ),
    );
  }
}