import 'package:flutter/material.dart';
import '../constants/theme.dart';

/// Visual order tracking aligned with admin statuses:
/// Pending → Paid → Confirmed → Shipped → Delivered (Cancelled shown separately).
class OrderTrackingTimeline extends StatelessWidget {
  const OrderTrackingTimeline({
    super.key,
    required this.status,
  });

  final String status;

  static const _steps = <_TrackStep>[
    _TrackStep('Order received', 'We have your order'),
    _TrackStep('Confirmed', 'Preparing your items'),
    _TrackStep('Out for delivery', 'On the way to you'),
    _TrackStep('Delivered', 'Enjoy your Girgo order'),
  ];

  /// How many timeline steps are fully completed (0–4).
  int _completedCount(String s) {
    switch (s) {
      case 'Cancelled':
        return -1;
      case 'Pending':
        return 0;
      case 'Paid':
        return 1;
      case 'Confirmed':
      case 'Packed':
        return 2;
      case 'Shipped':
      case 'Out for Delivery':
        return 3;
      case 'Delivered':
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = _completedCount(status);

    if (done < 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red.shade700),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'This order was cancelled.',
                style: TextStyle(
                  color: Colors.red.shade900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Track order', style: AppTextStyles.heading2),
        const SizedBox(height: AppSpacing.md),
        ...List.generate(_steps.length, (i) {
          final step = _steps[i];
          final isDone = i < done;
          final isCurrent = i == done && done < _steps.length;
          final isLast = i == _steps.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? AppColors.primary
                            : isCurrent
                                ? AppColors.white
                                : AppColors.gray,
                        border: Border.all(
                          color: isDone || isCurrent ? AppColors.primary : AppColors.border,
                          width: isCurrent ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        isDone ? Icons.check : Icons.circle_outlined,
                        color: isDone
                            ? AppColors.white
                            : isCurrent
                                ? AppColors.primary
                                : AppColors.textLight,
                        size: 20,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: i < done
                              ? AppColors.primary.withOpacity(0.5)
                              : AppColors.border,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: isDone ? AppColors.black : AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.subtitle,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _TrackStep {
  final String title;
  final String subtitle;

  const _TrackStep(this.title, this.subtitle);
}
