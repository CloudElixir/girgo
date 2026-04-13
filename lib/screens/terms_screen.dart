import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../widgets/cart_icon_button.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: const [
          CartIconButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildParagraph(
              'By using the Girgo app, you agree to the following:',
            ),
            const SizedBox(height: AppSpacing.md),
            _buildBullet('Orders are subject to product availability and delivery area coverage.'),
            _buildBullet('Prices and offers may change without prior notice.'),
            _buildBullet('Customers are responsible for providing accurate delivery details.'),
            _buildBullet('Misuse of offers, fake orders, or fraudulent activities may lead to account suspension.'),
            _buildBullet('Girgo reserves the right to modify, update, or terminate services at any time.'),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(text, style: AppTextStyles.body);
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.md, bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}
