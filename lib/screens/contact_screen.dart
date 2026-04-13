import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/theme.dart';
import '../widgets/cart_icon_button.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMap(String mapUrl) async {
    final uri = Uri.parse(mapUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact & Location'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: const [
          CartIconButton(),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 800;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: isWideScreen
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column - Contact Information
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // First Contact Section
                              _buildContactSection(
                                title: 'Reach Out to Us',
                                phone: '+91 9964544144',
                                email: 'girgoindia@gmail.com',
                                address: 'Site 357, 80 ft road AGB Layout, Opp Sapthagiri Medical College Hessarghatta Road, Chikkasandra Bangalore 560090',
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              // Second Contact Section
                              _buildContactSection(
                                title: 'Reach Out to Us',
                                phone: '+91 9964544144',
                                email: 'girgoindia@gmail.com',
                                address: 'Survey no 77 Kukkanahalli Near BGS college Kukkanahalli pin code 560080',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        // Right Column - Maps
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Our Office Map
                              _buildMapSection(
                                title: 'Our Office',
                                address: 'Site 357, 80 ft road AGB Layout, Opp Sapthagiri Medical College Hessarghatta Road, Chikkasandra Bangalore 560090',
                                mapUrl: 'https://www.google.com/maps/search/Site+357+80+ft+road+AGB+Layout+Opp+Sapthagiri+Medical+College+Hessarghatta+Road+Chikkasandra+Bangalore+560090/@13.0700725,77.5015497,2161m/data=!3m2!1e3!4b1?entry=ttu&g_ep=EgoyMDI1MTEwNC4xIKXMDSoASAFQAw%3D%3D',
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              // Our Gaushala Map
                              _buildMapSection(
                                title: 'Our Gaushala',
                                address: 'Survey no 77 Kukkanahalli Near BGS college Kukkanahalli pin code 560080',
                                mapUrl: 'https://www.google.com/maps/search/Survey+no+77+Kukkanahalli+Near+BGS+college+Kukkanahalli+pin+code+560080/@12.9898346,77.4630158,1081m/data=!3m2!1e3!4b1?entry=ttu&g_ep=EgoyMDI1MTEwNC4xIKXMDSoASAFQAw%3D%3D',
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // First Contact Section
                        _buildContactSection(
                          title: 'Reach Out to Us',
                          phone: '+91 9964544144',
                          email: 'girgoindia@gmail.com',
                          address: 'Site 357, 80 ft road AGB Layout, Opp Sapthagiri Medical College Hessarghatta Road, Chikkasandra Bangalore 560090',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        // Our Office Map
                        _buildMapSection(
                          title: 'Our Office',
                          address: 'Site 357, 80 ft road AGB Layout, Opp Sapthagiri Medical College Hessarghatta Road, Chikkasandra Bangalore 560090',
                          mapUrl: 'https://www.google.com/maps/search/Site+357+80+ft+road+AGB+Layout+Opp+Sapthagiri+Medical+College+Hessarghatta+Road+Chikkasandra+Bangalore+560090/@13.0700725,77.5015497,2161m/data=!3m2!1e3!4b1?entry=ttu&g_ep=EgoyMDI1MTEwNC4xIKXMDSoASAFQAw%3D%3D',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        // Second Contact Section
                        _buildContactSection(
                          title: 'Reach Out to Us',
                          phone: '+91 9964544144',
                          email: 'girgoindia@gmail.com',
                          address: 'Survey no 77 Kukkanahalli Near BGS college Kukkanahalli pin code 560080',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        // Our Gaushala Map
                        _buildMapSection(
                          title: 'Our Gaushala',
                          address: 'Survey no 77 Kukkanahalli Near BGS college Kukkanahalli pin code 560080',
                          mapUrl: 'https://www.google.com/maps/search/Survey+no+77+Kukkanahalli+Near+BGS+college+Kukkanahalli+pin+code+560080/@12.9898346,77.4630158,1081m/data=!3m2!1e3!4b1?entry=ttu&g_ep=EgoyMDI1MTEwNC4xIKXMDSoASAFQAw%3D%3D',
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContactSection({
    required String title,
    required String phone,
    required String email,
    required String address,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildContactItem(
          icon: Icons.phone,
          label: 'Company Phone:',
          value: phone,
          onTap: () => _makePhoneCall(phone),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildContactItem(
          icon: Icons.email,
          label: 'Company Mail:',
          value: email,
          onTap: () => _sendEmail(email),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildContactItem(
          icon: Icons.location_on,
          label: 'Address:',
          value: address,
          onTap: () {
            // Open address in map
            _openMap('https://maps.google.com/?q=${Uri.encodeComponent(address)}');
          },
        ),
      ],
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection({
    required String title,
    required String address,
    String? mapUrl,
  }) {
    // Use provided mapUrl or fallback to address search
    final urlToOpen = mapUrl ?? 'https://maps.google.com/?q=${Uri.encodeComponent(address)}';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          onTap: () {
            _openMap(urlToOpen);
          },
          child: Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.gray,
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              child: Stack(
                children: [
                  // Map preview placeholder
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map,
                          size: 48,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Tap to open in Maps',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          address,
                          style: AppTextStyles.caption,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextButton.icon(
          onPressed: () {
            _openMap(urlToOpen);
          },
          icon: const Icon(Icons.open_in_new, size: 16),
          label: const Text('View larger map'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

