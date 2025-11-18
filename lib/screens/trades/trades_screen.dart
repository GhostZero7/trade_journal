// Trades screen
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/theme_service.dart';
import '../../providers/trades_provider.dart';

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
  File? _screenshot;
  final ImagePicker _picker = ImagePicker();

  bool _loading = false;
  bool _uploadingImage = false;

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

    double result =
        _type == "Buy" ? (exit - entry) * lots : (entry - exit) * lots;

    setState(() => _profit = result);
  }

  // -----------------------------
  // Screenshot Upload Functions
  // -----------------------------
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _screenshot = File(image.path);
      });
    }
  }

  Future<String?> _uploadScreenshot() async {
    if (_screenshot == null) return null;

    setState(() => _uploadingImage = true);

    try {
      final String fileName =
          'trade_screenshot_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef =
          FirebaseStorage.instance.ref().child('trade_screenshots/$fileName');
      final UploadTask uploadTask = storageRef.putFile(_screenshot!);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() => _uploadingImage = false);
      return downloadUrl;
    } catch (e) {
      setState(() => _uploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload screenshot: $e')),
      );
      return null;
    }
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
      String? screenshotUrl;
      if (_screenshot != null) {
        screenshotUrl = await _uploadScreenshot();
      }

      final tradeData = {
        "symbol": _pair,
        "type": _type,
        "amount": double.tryParse(_lotCtrl.text) ?? 0,
        "result": _profit >= 0 ? "Win" : "Loss",
        "profit": _profit,
        "notes": _notesCtrl.text.trim(),
        "screenshotUrl": screenshotUrl,
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.primary.withOpacity(0.6)),
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
  // Screenshot Preview Widget
  // -----------------------------
  Widget _buildScreenshotPreview() {
    final theme = _getTheme(context);

    if (_screenshot == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: theme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.primary.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(Icons.photo_library, size: 50, color: theme.textFaded),
            const SizedBox(height: 10),
            Text("No screenshot selected",
                style: TextStyle(color: theme.textFaded)),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            image: DecorationImage(
              image: FileImage(_screenshot!),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: CircleAvatar(
            backgroundColor: theme.cardDark.withOpacity(0.8),
            child: IconButton(
              icon:
                  Icon(Icons.close, color: theme.textLight, size: 20),
              onPressed: () {
                setState(() => _screenshot = null);
              },
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
          Text("Pair",
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: theme.textFaded)),
          const SizedBox(height: 6),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.cardDark,
              border: Border.all(color: theme.primary.withOpacity(0.6)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _pair,
                dropdownColor: theme.cardDark,
                style: TextStyle(color: theme.textLight),
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

          // Buy / Sell Toggle
          Text("Type",
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: theme.textFaded)),
          const SizedBox(height: 6),

          Row(children: [
            _typeButton("Buy", Colors.green, context),
            const SizedBox(width: 12),
            _typeButton("Sell", Colors.red, context),
          ]),

          const SizedBox(height: 20),

          // Input fields
          _inputField(context: context, label: "Entry Price", controller: _entryCtrl),
          const SizedBox(height: 16),

          _inputField(context: context, label: "Exit Price", controller: _exitCtrl),
          const SizedBox(height: 16),

          _inputField(context: context, label: "Lots", controller: _lotCtrl),
          const SizedBox(height: 20),

          // Profit Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _profit >= 0
                  ? Colors.green.withOpacity(0.15)
                  : Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Profit:",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textLight)),
                Text(
                  _profit.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _profit >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Screenshot upload preview
          Text("Trade Screenshot (Optional)",
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: theme.textFaded)),
          const SizedBox(height: 6),

          _buildScreenshotPreview(),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickImage,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: theme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _uploadingImage
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.primary,
                      ),
                    )
                  : Icon(Icons.photo_library, color: theme.primary),
              label: Text(
                _uploadingImage ? "Uploading..." : "Select Screenshot",
                style: TextStyle(color: theme.primary),
              ),
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
                  ),
                  child: const Text(
                    "Save Trade",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
        ]),
      ),
    );
  }

  // -----------------------------
  // BUY / SELL Button
  // -----------------------------
  Widget _typeButton(String label, Color color, BuildContext context) {
    final theme = _getTheme(context);
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
