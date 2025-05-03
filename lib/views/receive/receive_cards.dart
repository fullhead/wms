import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wms/core/constants.dart';
import 'package:wms/core/utils.dart';
import 'package:wms/models/receive.dart';

/// Карточка записи приёмки.
class ReceiveCard extends StatelessWidget {
  final Receive receive;
  final String? token;
  final VoidCallback onTap;

  const ReceiveCard({
    super.key,
    required this.receive,
    this.token,
    required this.onTap,
  });

  /* ──────────────────────────────────────────────────────────
   *  Вспомогательный виджет строки
   * ────────────────────────────────────────────────────────── */
  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: Colors.deepOrange, size: 16),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.titleSmall),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /* ──────────────────────────────────────────────────────────
   *  Build
   * ────────────────────────────────────────────────────────── */
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: AppConstants.apiBaseUrl + receive.product.productImage,
            httpHeaders:
                token != null ? {"Authorization": "Bearer $token"} : {},
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          receive.product.productName,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildInfoRow(context, Icons.qr_code, 'Штрихкод:',
                receive.product.productBarcode),
            const SizedBox(height: 4),
            _buildInfoRow(context, Icons.category, 'Категория:',
                receive.product.productCategory.categoryName),
            const SizedBox(height: 4),
            _buildInfoRow(
                context, Icons.location_on, 'Ячейка:', receive.cell.cellName),
            const SizedBox(height: 4),
            _buildInfoRow(context, Icons.confirmation_number, 'Количество:',
                receive.receiveQuantity.toString()),
            const SizedBox(height: 4),
            _buildInfoRow(context, Icons.calendar_today, 'Дата:',
                formatDateTime(receive.receiveDate)),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Skeleton-карточка, показывается во время загрузки.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        title: Container(
            width: double.infinity, height: 16, color: Colors.grey.shade300),
        subtitle: Container(
            margin: const EdgeInsets.only(top: 10),
            width: double.infinity,
            height: 14,
            color: Colors.grey.shade300),
      ),
    );
  }
}
