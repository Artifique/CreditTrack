import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';

class BluetoothPrinterService {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  // Récupérer la liste des appareils appairés
  Future<List<BluetoothDevice>> getDevices() async {
    return await bluetooth.getBondedDevices();
  }

  // Connexion à l'imprimante
  Future<void> connect(BluetoothDevice device) async {
    await bluetooth.connect(device);
  }

  // Impression du reçu thermique
  Future<void> printReceipt(TransactionModel transaction, String businessName) async {
    bool? isConnected = await bluetooth.isConnected;
    if (isConnected != true) return;

    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt);

    // Design du reçu pour imprimante thermique
    bluetooth.printCustom(businessName.toUpperCase(), 3, 1); // Taille 3, Centré
    bluetooth.printNewLine();
    bluetooth.printCustom("--------------------------------", 1, 1);
    bluetooth.printCustom("TYPE: ${transaction.type.name.toUpperCase()}", 2, 0);
    bluetooth.printCustom("CLIENT: ${transaction.clientName}", 1, 0);
    bluetooth.printCustom("TEL: ${transaction.clientPhone}", 1, 0);
    bluetooth.printCustom("--------------------------------", 1, 1);
    bluetooth.printCustom("TOTAL: ${transaction.amount} CFA", 3, 1);
    bluetooth.printCustom("--------------------------------", 1, 1);
    bluetooth.printCustom("Date: $dateStr", 1, 1);
    bluetooth.printNewLine();
    bluetooth.printCustom("Merci de votre confiance !", 1, 1);
    bluetooth.printNewLine();
    bluetooth.printNewLine();
    bluetooth.printNewLine(); // Espace pour la découpe
  }
}
