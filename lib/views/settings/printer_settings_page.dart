import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../../core/theme.dart';
import '../../core/user_feedback.dart';
import '../../services/bluetooth_service.dart';

class PrinterSettingsPage extends StatefulWidget {
  const PrinterSettingsPage({super.key});

  @override
  State<PrinterSettingsPage> createState() => _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends State<PrinterSettingsPage> {
  bool _isSearching = false;
  final _bluetoothService = BluetoothPrinterService();
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _connectedDevice;

  Future<void> _scanDevices() async {
    setState(() => _isSearching = true);
    try {
      final list = await _bluetoothService.getDevices();
      if (!mounted) return;
      setState(() => _devices = list);
    } catch (e) {
      if (!mounted) return;
      await UserFeedback.showErrorModal(context, e);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

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
    if (_devices.isEmpty) {
      return const Center(child: Text("Aucun appareil trouvé. Lance une recherche."));
    }

    return ListView.builder(
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        final isConnected = _connectedDevice?.address == device.address;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.print_rounded, color: AppColors.primary),
            title: Text(device.name ?? "Imprimante inconnue"),
            subtitle: Text(isConnected ? "Connecté" : "Non connecté"),
            trailing: TextButton(
              onPressed: () async {
                try {
                  await _bluetoothService.connect(device);
                  if (!mounted) return;
                  setState(() => _connectedDevice = device);
                  await UserFeedback.showSuccessModal(
                    context,
                    "Imprimante connectée: ${device.name ?? device.address}",
                  );
                } catch (e) {
                  if (!mounted) return;
                  await UserFeedback.showErrorModal(context, e);
                }
              },
              child: Text(isConnected ? "Connecté" : "Connecter"),
            ),
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
        onPressed: _isSearching ? null : _scanDevices,
        icon: Icon(_isSearching ? Icons.stop_rounded : Icons.search_rounded, color: Colors.white),
        label: Text(_isSearching ? "Recherche..." : "Rechercher une imprimante", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
    );
  }
}
