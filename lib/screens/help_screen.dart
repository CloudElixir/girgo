import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../widgets/cart_icon_button.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & FAQ'),
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
            Text(
              'Frequently Asked Questions',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildFAQItem(
              question: 'How do I place an order?',
              answer: 'Browse products, add items to cart, and proceed to checkout. Fill in your billing details and select a payment method.',
            ),
            _buildFAQItem(
              question: 'What payment methods are accepted?',
              answer: 'We accept Cash on Delivery (COD), UPI, and Debit/Credit Cards.',
            ),
            _buildFAQItem(
              question: 'How do subscriptions work?',
              answer: 'You can subscribe to products for regular deliveries. Subscriptions are activated after payment approval.',
            ),
            _buildFAQItem(
              question: 'Can I cancel my subscription?',
              answer: 'Yes, you can cancel your subscription anytime from the Subscriptions page in your profile.',
            ),
            _buildFAQItem(
              question: 'What is the delivery time?',
              answer: 'Delivery times vary by location. You will receive updates about your order status.',
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Need More Help?',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Contact our support team via Call Support or WhatsApp Support from the Profile page.',
              style: AppTextStyles.body,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ExpansionTile(
        title: Text(
          question,
          style: AppTextStyles.heading3,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              answer,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}

