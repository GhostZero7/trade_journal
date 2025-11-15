// Trades screen
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';

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
  String _pair = "EURUSD";
  String _type = "Buy";
  double _profit = 0.0;

  bool _loading = false;

  // ------------------------
  // Auto Calculate P/L
  // ------------------------
  void _calculatePL() {
    double entry = double.tryParse(_entryCtrl.text) ?? 0;
    double exit = double.tryParse(_exitCtrl.text) ?? 0;
    double lots = double.tryParse(_lotCtrl.text) ?? 0;

    if (entry == 0 || exit == 0 || lots == 0) {
      setState(() => _profit = 0);
      return;
    }

    double result =
        _type == "Buy" ? (exit - entry) * lots : (entry - exit) * lots;

    setState(() => _profit = result);
  }

  // ------------------------
  // Save Trade to Firestore
  // ------------------------
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

    await FirebaseFirestore.instance.collection("trades").add({
      "pair": _pair,
      "type": _type,
      "entry": double.tryParse(_entryCtrl.text) ?? 0,
      "exit": double.tryParse(_exitCtrl.text) ?? 0,
      "lots": double.tryParse(_lotCtrl.text) ?? 0,
      "profit": _profit,
      "notes": _notesCtrl.text.trim(),
      "created_at": Timestamp.now(),
    });

    setState(() => _loading = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Trade added")),
      );
    }
  }

  // ------------------------
  // UI COMPONENT
  // ------------------------
  Widget _inputField(
      {required String label,
      required TextEditingController controller,
      TextInputType type = TextInputType.number}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: type,
          onChanged: (_) => _calculatePL(),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.transparent,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.primary.withOpacity(0.6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------
  // MAIN BUILD UI
  // ------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Add Trade"),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ---------------- Pair Dropdown ----------------
          const Text("Pair",
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 6),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.6), width: 1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _pair,
                items: const [
                  DropdownMenuItem(value: "EURUSD", child: Text("EURUSD")),
                  DropdownMenuItem(value: "GBPUSD", child: Text("GBPUSD")),
                  DropdownMenuItem(value: "XAUUSD", child: Text("XAUUSD")),
                  DropdownMenuItem(value: "USDJPY", child: Text("USDJPY")),
                ],
                onChanged: (v) => setState(() => _pair = v!),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ---------------- Buy / Sell Toggle ----------------
          const Text("Type",
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 6),

          Row(children: [
            _typeButton("Buy", Colors.green),
            const SizedBox(width: 12),
            _typeButton("Sell", Colors.red),
          ]),

          const SizedBox(height: 20),

          // ---------------- Inputs ----------------
          _inputField(label: "Entry Price", controller: _entryCtrl),
          const SizedBox(height: 16),

          _inputField(label: "Exit Price", controller: _exitCtrl),
          const SizedBox(height: 16),

          _inputField(label: "Lots", controller: _lotCtrl),
          const SizedBox(height: 20),

          // ---------------- Profit Box ----------------
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _profit >= 0 ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Profit:",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text("${_profit.toStringAsFixed(2)}",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _profit >= 0 ? Colors.green : Colors.red)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ---------------- Notes ----------------
          _inputField(
              label: "Notes", controller: _notesCtrl, type: TextInputType.text),

          const SizedBox(height: 30),

          // ---------------- Save Button ----------------
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _saveTrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    "Save Trade",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
        ]),
      ),
    );
  }

  // BUY / SELL BUTTON
  Widget _typeButton(String label, Color color) {
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
            border: Border.all(color: color, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
                color: active ? Colors.white : color,
                fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
