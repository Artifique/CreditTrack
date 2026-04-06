import 'transaction_model.dart';

/// Arguments optionnels pour [NewTransactionPage] (route nommée ou [MaterialPageRoute]).
class NewTransactionRouteArgs {
  final TransactionType? initialType;
  /// Montant suggéré pour un transfert de bénéfice UV (ex. bénéfice disponible).
  final double? suggestedProfitUvAmount;

  const NewTransactionRouteArgs({
    this.initialType,
    this.suggestedProfitUvAmount,
  });
}
