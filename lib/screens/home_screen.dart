import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import '../constants/theme.dart';
import '../providers/products_provider.dart';
import '../providers/tab_controller_provider.dart';
import '../models/product.dart';
import '../services/firestore_service.dart';
import 'product_detail_screen.dart';
import 'blog_detail_screen.dart';
import '../widgets/cart_icon_button.dart';
import '../widgets/product_thumbnail.dart';
import '../utils/data_url_image_decoder.dart';
import '../utils/bundled_asset_path.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _configuredFeaturedEntries({
    required List<dynamic> ids,
    required List<String> titles,
    required Map<String, Product> byId,
  }) {
    final out = <Map<String, dynamic>>[];
    for (var i = 0; i < ids.length && i < 8; i++) {
      final id = ids[i].toString();
      if (id.isEmpty) continue;
      final product = byId[id];
      if (product == null) continue;
      out.add({
        'id': id,
        'product': product,
        'title': i < titles.length ? titles[i] : '',
      });
    }
    return out;
  }

  String _compactName(String input) {
    final s = input.trim();
    if (s.isEmpty) return 'Product';
    final words = s.split(RegExp(r'\s+'));
    if (words.length <= 3) return s;
    return words.take(3).join(' ');
  }

  String? userName;
  String? userLocation;
  String? userProfileImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('HOME SCREEN LOADED');
    });
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? 'User Name';
      userLocation = prefs.getString('userLocation') ?? '';
      userProfileImage = prefs.getString('userProfileImage') ?? '';
    });
  }

  // Helper method to get responsive spacing
  double _getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return baseSpacing * 0.75; // Smaller spacing for very small screens
    } else if (screenWidth < 400) {
      return baseSpacing * 0.85;
    }
    return baseSpacing;
  }

  // Helper method to get responsive font size
  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return baseSize * 0.85; // Smaller font for very small screens
    } else if (screenWidth < 400) {
      return baseSize * 0.9;
    }
    return baseSize;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = _getResponsiveSpacing(context, AppSpacing.md);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeader(context),
              SizedBox(height: spacing),
              // Promotional Banner
              _buildPromotionalBanner(context),
              SizedBox(height: _getResponsiveSpacing(context, AppSpacing.xl)),
              // Our Featured Products Section
              _buildFeaturesSection(context),
              SizedBox(height: _getResponsiveSpacing(context, AppSpacing.xl)),
              // Blogs Section
              _buildBlogsSection(context),
              SizedBox(height: _getResponsiveSpacing(context, AppSpacing.xl)),
              // Footer
              _buildFooter(context),
              SizedBox(height: _getResponsiveSpacing(context, AppSpacing.xl)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = screenWidth < 360 ? 50.0 : 60.0;
    final padding = _getResponsiveSpacing(context, AppSpacing.md);
    final fontSize = _getResponsiveFontSize(context, 18.0);
    
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Row(
        children: [
          // Profile/Logo
          GestureDetector(
            onTap: () {
              final tabController = Provider.of<TabControllerProvider>(context, listen: false);
              tabController.setIndex(3);
            },
            child: Container(
              width: logoSize,
              height: logoSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF0B510E),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: _buildHomeProfileAvatar(logoSize),
              ),
            ),
          ),
          SizedBox(width: padding),
          // Welcome Message and Location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0B510E),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  userName ?? 'User',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: _getResponsiveFontSize(context, 14.0),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if ((userLocation ?? '').isNotEmpty)
                  Text(
                    userLocation!,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: _getResponsiveFontSize(context, 12.0),
                      color: AppColors.textLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            color: const Color(0xFF0B510E),
            onPressed: () {
              final tabController = Provider.of<TabControllerProvider>(context, listen: false);
              tabController.setIndex(3);
            },
            tooltip: 'Profile',
          ),
          const CartIconButton(),
        ],
      ),
    );
  }

  Widget _buildHomeProfileAvatar(double logoSize) {
    final profileImage = userProfileImage ?? '';
    if (profileImage.startsWith('data:image')) {
      final bytes = DataUrlImageDecoder.decode(profileImage);
      if (bytes.isNotEmpty) {
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.person, size: logoSize * 0.5);
          },
        );
      }
    }

    return Image.asset(
      normalizeBundledAssetPath('signup/logo.png'),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.person, size: logoSize * 0.5);
      },
    );
  }

  Widget _buildPromotionalBanner(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bannerHeight = screenHeight < 700 
        ? (screenHeight * 0.25).clamp(140.0, 180.0)
        : 180.0;
    final horizontalPadding = _getResponsiveSpacing(context, AppSpacing.md);
    final bannerPadding = _getResponsiveSpacing(context, AppSpacing.lg);
    
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService.getHomeOffers(),
      builder: (context, snapshot) {
        final offersList = snapshot.data;
        final useDefault = snapshot.hasError ||
            !snapshot.hasData ||
            offersList == null ||
            offersList.isEmpty;

        // Show default banner if no offers or error
        if (useDefault) {
    return Container(
            margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
            height: bannerHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF2D5016),
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            normalizeBundledAssetPath('signup/homesign.PNG'),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF2D5016)),
          ),
          Container(color: const Color(0xFF2D5016).withValues(alpha: 0.72)),
          Padding(
                  padding: EdgeInsets.all(bannerPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                      Text(
                  'Get Pure A2 Milk & A2 Ghee\nFlat 50% Off on Your First Order!',
                  style: TextStyle(
                          fontSize: _getResponsiveFontSize(context, 18.0),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.3,
                  ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                ),
                      SizedBox(height: _getResponsiveSpacing(context, AppSpacing.md)),
                ElevatedButton(
                  onPressed: () {
                          // Default "featured" banner action: go to Products tab.
                          final tabController = Provider.of<TabControllerProvider>(
                            context,
                            listen: false,
                          );
                          tabController.setIndex(1);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(
                            horizontal: _getResponsiveSpacing(context, AppSpacing.lg),
                            vertical: _getResponsiveSpacing(context, AppSpacing.sm),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                    ),
                  ),
                        child: Text(
                    'Purchase Now',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                            fontSize: _getResponsiveFontSize(context, 14.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

        // Get the first active offer (already sorted by priority)
        final offers = offersList;
        final offer = offers.first;
        final title = offer['title'] ?? 'Special Offer';
        final subtitle = offer['subtitle'] ?? '';
        final buttonText = offer['buttonText'] ?? 'Purchase Now';
        final buttonLink = offer['buttonLink'] ?? '';
        final rawButtonEnabled = offer['isButtonEnabled'];
        final isButtonEnabled = rawButtonEnabled == null
            ? true
            : (rawButtonEnabled == true ||
                rawButtonEnabled == 1 ||
                (rawButtonEnabled is String &&
                    (rawButtonEnabled.toLowerCase() == 'true' || rawButtonEnabled == '1')));
        final rawBannerImage = offer['imageUrl']?.toString() ?? '';

        return ClipRRect(
          borderRadius: BorderRadius.circular(AppBorderRadius.large),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
            height: bannerHeight,
            decoration: const BoxDecoration(
              color: Color(0xFF2D5016),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: _buildHomeOfferBackgroundImage(rawBannerImage),
                ),
                Positioned.fill(
                  child: Container(
                    color: const Color(0xFF2D5016).withOpacity(0.58),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(bannerPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(context, 16.0),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle.isNotEmpty) ...[
                        SizedBox(height: _getResponsiveSpacing(context, AppSpacing.sm)),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(context, 12.0),
                            color: Colors.white70,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (isButtonEnabled) ...[
                        SizedBox(height: _getResponsiveSpacing(context, AppSpacing.md)),
                        ElevatedButton(
                          onPressed: () {
                            final tabController = Provider.of<TabControllerProvider>(
                              context,
                              listen: false,
                            );
                            tabController.setIndex(1);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(
                              horizontal: _getResponsiveSpacing(context, AppSpacing.lg),
                              vertical: _getResponsiveSpacing(context, AppSpacing.sm),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                            ),
                          ),
                          child: Text(
                            buttonText,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: _getResponsiveFontSize(context, 13.0),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Default grid when [app_config/home.featuredProductIds] is not set (or empty).
  List<Product> _defaultFeaturedProductsByCategory(ProductsProvider productsProvider) {
    return [
      productsProvider.getProductsByCategory('Milk').isNotEmpty
          ? productsProvider.getProductsByCategory('Milk').first
          : null,
      productsProvider.getProductsByCategory('Ghee').isNotEmpty
          ? productsProvider.getProductsByCategory('Ghee').first
          : null,
      productsProvider.getProductsByCategory('Dung Cakes').isNotEmpty
          ? productsProvider.getProductsByCategory('Dung Cakes').first
          : null,
      productsProvider.getProductsByCategory('Paneer').isNotEmpty
          ? productsProvider.getProductsByCategory('Paneer').first
          : null,
      productsProvider.getProductsByCategory('Pachagavya').isNotEmpty
          ? productsProvider.getProductsByCategory('Pachagavya').first
          : null,
      productsProvider.getProductsByCategory('Diyas').isNotEmpty
          ? productsProvider.getProductsByCategory('Diyas').first
          : null,
      productsProvider.getProductsByCategory('Dhoopa').isNotEmpty
          ? productsProvider.getProductsByCategory('Dhoopa').first
          : null,
      productsProvider.getProductsByCategory('Gomutra').isNotEmpty
          ? productsProvider.getProductsByCategory('Gomutra').first
          : null,
    ].whereType<Product>().toList();
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: FirestoreService.getHomeFeaturedConfigStream(),
      builder: (context, configSnap) {
        return Consumer<ProductsProvider>(
          builder: (context, productsProvider, child) {
            final screenWidth = MediaQuery.of(context).size.width;
            final horizontalPadding = _getResponsiveSpacing(context, AppSpacing.md);
            final ids = configSnap.data?['featuredProductIds'];
            final rawTitles = configSnap.data?['featuredProductTitles'];
            final slotTitles = rawTitles is List
                ? rawTitles.map((e) => e.toString()).toList()
                : <String>[];
            final List<Product> featuredProducts;
            List<Map<String, dynamic>> configuredEntries = const [];
            if (ids is List) {
              final idList = ids.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
              final byId = {for (final p in productsProvider.products) p.id: p};
              configuredEntries = _configuredFeaturedEntries(
                ids: ids,
                titles: slotTitles,
                byId: byId,
              );
              featuredProducts =
                  idList.map((id) => byId[id]).whereType<Product>().toList();
            } else {
              featuredProducts = _defaultFeaturedProductsByCategory(productsProvider);
            }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Text(
            'Our Featured Product',
            style: AppTextStyles.heading2.copyWith(
              color: const Color(0xFF0B510E),
              fontSize: _getResponsiveFontSize(context, 20.0),
            ),
          ),
        ),
        SizedBox(height: _getResponsiveSpacing(context, AppSpacing.md)),
        // Product grid: 4 items in first row, 4 items in second row
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              // First row with 4 items
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ...(configuredEntries.isNotEmpty
                          ? configuredEntries.take(4).toList().asMap().entries
                          : featuredProducts.take(4).toList().asMap().entries)
                      .map((entry) {
                    final idx = entry.key;
                    final data = entry.value as dynamic;
                    final product = configuredEntries.isNotEmpty
                        ? data['product'] as Product?
                        : data as Product;
                    final imagePath = (product?.image ?? '').trim();
                    final titleOverride = configuredEntries.isNotEmpty
                        ? (data['title']?.toString() ?? '')
                        : (idx >= 0 && idx < slotTitles.length ? slotTitles[idx] : '');
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: _getResponsiveSpacing(context, AppSpacing.xs) / 2),
                        child: _buildProductItem(
                          context,
                          product,
                          imagePath,
                          screenWidth,
                          displayName: titleOverride,
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
              SizedBox(height: _getResponsiveSpacing(context, AppSpacing.md)),
              // Second row with up to 4 items
              if ((configuredEntries.isNotEmpty ? configuredEntries.length : featuredProducts.length) > 4)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ...((configuredEntries.isNotEmpty
                                ? configuredEntries.skip(4).take(4).toList().asMap().entries
                                : featuredProducts.skip(4).take(4).toList().asMap().entries))
                        .map((entry) {
                      final idx = entry.key + 4;
                      final data = entry.value as dynamic;
                      final product = configuredEntries.isNotEmpty
                          ? data['product'] as Product?
                          : data as Product;
                      final imagePath = (product?.image ?? '').trim();
                      final titleOverride = configuredEntries.isNotEmpty
                          ? (data['title']?.toString() ?? '')
                          : (idx >= 0 && idx < slotTitles.length ? slotTitles[idx] : '');
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: _getResponsiveSpacing(context, AppSpacing.xs) / 2),
                          child: _buildProductItem(
                            context,
                            product,
                            imagePath,
                            screenWidth,
                            displayName: titleOverride,
                          ),
                        ),
                      );
                    }).toList(),
                    // Add empty space for the 4th column
                    if ((configuredEntries.isNotEmpty ? configuredEntries.length : featuredProducts.length) < 8)
                      Expanded(
                        child: SizedBox(),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
          },
        );
      },
    );
  }

  Widget _buildBlogsSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = _getResponsiveSpacing(context, AppSpacing.md);
    
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService.getActiveBlogs(),
      builder: (context, snapshot) {
        final hasBlogs = snapshot.hasData && snapshot.data!.isNotEmpty;
        final blogs = hasBlogs ? snapshot.data! : _defaultBlogs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                children: [
                  Text(
            'Blogs',
            style: AppTextStyles.heading2.copyWith(
              color: const Color(0xFF0B510E),
                      fontSize: _getResponsiveFontSize(context, 20.0),
                    ),
                  ),
                  if (!hasBlogs)
                    Padding(
                      padding: EdgeInsets.only(left: _getResponsiveSpacing(context, AppSpacing.sm)),
                      child: Text(
                        '(coming soon)',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textLight,
                          fontSize: _getResponsiveFontSize(context, 12.0),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: _getResponsiveSpacing(context, AppSpacing.md)),
            if (snapshot.hasError)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Text(
                  'Failed to load blogs. Showing featured content instead.',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.red,
                    fontSize: _getResponsiveFontSize(context, 11.0),
            ),
          ),
        ),
        ...List.generate(
              blogs.length,
              (index) => _buildBlogCard(context, blogs[index], index),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBlogCard(BuildContext context, Map<String, dynamic> blog, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final rawImage = blog['imageUrl'] ?? blog['image'] ?? 'singup/homebg.PNG';
    final imagePath = rawImage is String && rawImage.isNotEmpty ? rawImage : 'singup/homebg.PNG';
    final isNetworkImage = imagePath.startsWith('http') || imagePath.startsWith('https');
    final isDataUrl = imagePath.startsWith('data:image');
    final assetPath =
        (!isNetworkImage && !isDataUrl) ? normalizeBundledAssetPath(imagePath) : imagePath;
    final title = blog['title'] ?? 'Featured Story';
    final summary = blog['summary'] ?? blog['content'] ?? '';
    final cardHeight = screenHeight < 700 ? 200.0 : 250.0;
    final horizontalPadding = _getResponsiveSpacing(context, AppSpacing.md);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlogDetailScreen(blog: blog),
          ),
        );
      },
      child: Container(
      margin: EdgeInsets.only(
          left: horizontalPadding,
          right: horizontalPadding,
          bottom: _getResponsiveSpacing(context, AppSpacing.md),
      ),
        height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        color: const Color(0xFF0B510E), // Fallback color
      ),
      child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(AppBorderRadius.large)),
        child: Stack(
          children: [
            // Background image
              (isNetworkImage
                  ? Image.network(
                      imagePath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          normalizeBundledAssetPath('signup/homesign.PNG'),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: const Color(0xFF0B510E),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    )
                  : isDataUrl
                      ? Image.memory(
                          _decodeBase64Image(imagePath),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  normalizeBundledAssetPath('signup/homesign.PNG'),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            );
                          },
                        )
                      : Image.asset(
                          assetPath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF0B510E),
                      child: const Center(
                        child: Icon(
                          Icons.image,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                        )),
            // Overlay gradient
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppBorderRadius.large),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            // Title overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B510E).withOpacity(0.9),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppBorderRadius.large),
                    bottomRight: Radius.circular(AppBorderRadius.large),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                    color: Colors.white,
                        fontSize: _getResponsiveFontSize(context, 15.0),
                    fontWeight: FontWeight.bold,
                  ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (summary.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        summary,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: _getResponsiveFontSize(context, 12.0),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  /// Home offer `imageUrl` from Firestore: HTTPS (e.g. Firebase Storage), data URL, or app asset path.
  Widget _buildHomeOfferBackgroundImage(String raw) {
    final fallback = normalizeBundledAssetPath('signup/homesign.PNG');
    final path = raw.trim().isEmpty ? fallback : raw;
    final isNetwork = path.startsWith('http://') || path.startsWith('https://');
    final isDataUrl = path.startsWith('data:image');
    if (isNetwork) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(fallback, fit: BoxFit.cover);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: const Color(0xFF2D5016),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
          );
        },
      );
    }
    if (isDataUrl) {
      final bytes = _decodeBase64Image(path);
      if (bytes.isEmpty) {
        return Image.asset(fallback, fit: BoxFit.cover);
      }
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(fallback, fit: BoxFit.cover);
        },
      );
    }
    return Image.asset(
      normalizeBundledAssetPath(path),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(fallback, fit: BoxFit.cover);
      },
    );
  }

  Uint8List _decodeBase64Image(String dataUrl) {
    return DataUrlImageDecoder.decode(dataUrl);
  }

  Widget _buildFooter(BuildContext context) {
    final padding = _getResponsiveSpacing(context, AppSpacing.md);
    
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Center(
        child: Text(
          'GirGo. All rights reserved. Made with ❤️ for pure, happy living',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textLight,
            fontSize: _getResponsiveFontSize(context, 11.0),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // Blog items data
  final List<Map<String, dynamic>> _defaultBlogs = [
    {
      'title': 'Recipes from Girgo products',
      'imageUrl': 'Products/A2 Desi Paneer.jpg',
      'summary': 'Discover tasty meals crafted with our farm-fresh ingredients.',
    },
    {
      'title': 'Benefits of Pure A2 Milk',
      'imageUrl': 'Products/A2 DESI GIR COW MILK.jpg',
      'summary': 'Understand why A2 milk is easier to digest and full of nutrients.',
    },
    {
      'title': 'Traditional Ghee Making Process',
      'imageUrl': 'Products/A2 BILONA GHEE.jpg',
      'summary': 'A behind-the-scenes look at how we craft golden A2 Bilona ghee.',
    },
    {
      'title': 'Ayurvedic Uses of Panchagavya',
      'imageUrl': 'Products/PANCHGAVYA COW DUNG CAKE.jpg',
      'summary': 'Ancient remedies and daily rituals using our Panchagavya products.',
    },
    {
      'title': 'Organic Farming with Cow Products',
      'imageUrl': 'Products/GOMUTRA (COW URINE).jpg',
      'summary': 'How natural cow-based inputs enrich soil and boost yields.',
    },
    {
      'title': 'Healthy Recipes with A2 Paneer',
      'imageUrl': 'homeicon/paneerhome.PNG',
      'summary': 'High-protein delights you can cook with chemical-free paneer.',
    },
    {
      'title': 'Spiritual Significance of Diyas',
      'imageUrl': 'Products/COW DUNG DIYAS (LAMPS).jpg',
      'summary': 'Explore the cultural symbolism behind lighting cow-dung diyas.',
    },
    {
      'title': 'Natural Fragrance with Dhoop Sticks',
      'imageUrl': 'Products/HERBAL DHOOP STICKS.jpg',
      'summary': 'Why our herbal dhoop sticks elevate mood and cleanse spaces.',
    },
  ];

  Widget _buildProductItem(
    BuildContext context,
    Product? product,
    String imagePath,
    double screenWidth, {
    String? displayName,
  }) {
    final itemHeight = screenWidth < 360 ? 100.0 : 120.0;
    final imageSize = screenWidth < 360 ? 60.0 : 80.0;
    final fallbackName = product != null ? _compactName(product.name) : 'Product';
    final label = (displayName != null && displayName.trim().isNotEmpty)
        ? _compactName(displayName.trim())
        : fallbackName;
    
    return GestureDetector(
      onTap: () {
        if (product == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: SizedBox(
        height: itemHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: imageSize,
              height: imageSize,
              decoration: BoxDecoration(
                color: const Color(0xFFF5E6D3),
                shape: BoxShape.circle,
              ),
              child: ProductThumbnail(
                product: product,
                imageRaw: imagePath,
                size: imageSize,
                fit: BoxFit.cover,
                circular: true,
              ),
            ),
            SizedBox(height: _getResponsiveSpacing(context, AppSpacing.xs)),
            SizedBox(
              height: screenWidth < 360 ? 28 : 32,
              child: Center(
                child: Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: screenWidth < 360 ? 8 : 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
