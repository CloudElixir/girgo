import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../widgets/cart_icon_button.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: const [
          CartIconButton(),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.description_outlined,
              size: 80,
              color: AppColors.textLight,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No transactions yet',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your transaction history will appear here',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

