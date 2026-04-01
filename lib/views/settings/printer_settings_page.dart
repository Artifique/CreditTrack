import 'package:flutter/material.dart';
import '../../core/theme.dart';

class PrinterSettingsPage extends StatefulWidget {
  const PrinterSettingsPage({super.key});

  @override
  State<PrinterSettingsPage> createState() => _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends State<PrinterSettingsPage> {
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Imprimante")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Configuration", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            _buildFormatSelector(),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Appareils à proximité", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (_isSearching) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildDeviceList()),
            _buildScanButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          _buildFormatOption("Format 58mm (Standard)", true),
          const Divider(),
          _buildFormatOption("Format 80mm (Large)", false),
        ],
      ),
    );
  }

  Widget _buildFormatOption(String label, bool isSelected) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Radio(value: isSelected, groupValue: true, onChanged: (v) {}, activeColor: AppColors.primary),
      ],
    );
  }

  Widget _buildDeviceList() {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.print_rounded, color: AppColors.primary),
            title: Text("Imprimante Thermique #$index"),
            subtitle: const Text("Non connecté"),
            trailing: TextButton(onPressed: () {}, child: const Text("Connecter")),
          ),
        );
      },
    );
  }

  Widget _buildScanButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: () => setState(() => _isSearching = !_isSearching),
        icon: Icon(_isSearching ? Icons.stop_rounded : Icons.search_rounded, color: Colors.white),
        label: Text(_isSearching ? "Arrêter le scan" : "Rechercher une imprimante", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
    );
  }
}
