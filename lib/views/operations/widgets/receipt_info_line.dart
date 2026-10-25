import 'package:flutter/material.dart';

/// Ligne d'affichage clé/valeur pour les reçus et tickets de transaction.
class ReceiptInfoLine extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? labelColor;
  final Color? valueColor;
  final VoidCallback? onCopy;
  final IconData? icon;

  const ReceiptInfoLine({
    super.key,
    required this.label,
    required this.value,
    this.isBold = false,
    this.labelColor,
    this.valueColor,
    this.onCopy,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultLabelColor = labelColor ?? theme.colorScheme.onSurfaceVariant;
    final defaultValueColor = valueColor ?? theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: defaultLabelColor),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: defaultLabelColor,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                      color: defaultValueColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onCopy != null) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: onCopy,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.copy_rounded,
                        size: 15,
                        color: defaultLabelColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
