import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../constants/theme.dart';
import '../providers/products_provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';
import '../services/firestore_service.dart';
import 'product_detail_screen.dart';
import 'blog_detail_screen.dart';
import '../widgets/cart_icon_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? 'User Name';

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
              // Features of our Products Section
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
          Container(
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
              child: Image.asset(
                'signup/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.person, size: logoSize * 0.5);
                },
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
                  userName ?? 'User Name',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: _getResponsiveFontSize(context, 14.0),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Cart Icon
          const CartIconButton(),
        ],
      ),
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
        // Show default banner if no offers or error
        if (!snapshot.hasData || snapshot.hasError || snapshot.data!.isEmpty) {
    return Container(
            margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
            height: bannerHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF2D5016), // Dark green
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        image: DecorationImage(
          image: AssetImage('signup/homesign.PNG'),
          fit: BoxFit.cover,
          opacity: 0.3,
        ),
      ),
      child: Stack(
        children: [
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
                    // Navigate to products or checkout
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
        final offers = snapshot.data!;
        final offer = offers.first;
        final title = offer['title'] ?? 'Special Offer';
        final subtitle = offer['subtitle'] ?? '';
        final buttonText = offer['buttonText'] ?? 'Purchase Now';
        final buttonLink = offer['buttonLink'] ?? '';

        return Container(
          margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
          height: bannerHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF2D5016), // Dark green
            borderRadius: BorderRadius.circular(AppBorderRadius.large),
            image: DecorationImage(
              image: AssetImage('signup/homesign.PNG'),
              fit: BoxFit.cover,
              opacity: 0.3,
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(bannerPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
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
                    ),
                    if (subtitle.isNotEmpty) ...[
                      SizedBox(height: _getResponsiveSpacing(context, AppSpacing.sm)),
                      Flexible(
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(context, 12.0),
                            color: Colors.white70,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    SizedBox(height: _getResponsiveSpacing(context, AppSpacing.md)),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate based on buttonLink or default action
                        if (buttonLink.isNotEmpty) {
                          // Handle navigation based on buttonLink
                          // For now, just navigate to shop/products
                        }
                        // Default action - could navigate to products screen
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Consumer<ProductsProvider>(
      builder: (context, productsProvider, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final horizontalPadding = _getResponsiveSpacing(context, AppSpacing.md);
        // Get featured products by category
        final featuredProducts = [
          productsProvider.getProductsByCategory('Milk').isNotEmpty 
              ? productsProvider.getProductsByCategory('Milk').first 
              : null,
          productsProvider.getProductsByCategory('Ghee').isNotEmpty 
              ? productsProvider.getProductsByCategory('Ghee').first 
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

    // Map product categories to their homeicon images
    final Map<String, String> productImageMap = {
      'milk': 'homeicon/milkhome.PNG',
      'ghee': 'homeicon/gheehom.PNG',
      'paneer': 'homeicon/paneerhome.PNG',
      'pachagavya': 'homeicon/cakehome.PNG',
      'diyas': 'homeicon/dungdiya.PNG',
      'dhoopa': 'homeicon/dhoopstikchome.PNG',
      'gomutra': 'homeicon/gomurahome.PNG',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Text(
            'Features of our Products',
            style: AppTextStyles.heading2.copyWith(
              color: const Color(0xFF0B510E),
              fontSize: _getResponsiveFontSize(context, 20.0),
            ),
          ),
        ),
        SizedBox(height: _getResponsiveSpacing(context, AppSpacing.md)),
        // Product grid: 4 items in first row, 3 items in second row
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              // First row with 4 items
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ...featuredProducts.take(4).map((product) {
                    final imagePath = productImageMap[product.category.toLowerCase()] ?? 'homeicon/milkhome.PNG';
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: _getResponsiveSpacing(context, AppSpacing.xs) / 2),
                        child: _buildProductItem(context, product, imagePath, screenWidth),
                      ),
                    );
                  }).toList(),
                ],
              ),
              SizedBox(height: _getResponsiveSpacing(context, AppSpacing.md)),
              // Second row with 3 items
              if (featuredProducts.length > 4)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ...featuredProducts.skip(4).take(3).map((product) {
                      final imagePath = productImageMap[product.category.toLowerCase()] ?? 'homeicon/milkhome.PNG';
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: _getResponsiveSpacing(context, AppSpacing.xs) / 2),
                          child: _buildProductItem(context, product, imagePath, screenWidth),
                        ),
                      );
                    }).toList(),
                    // Add empty space for the 4th column
                    if (featuredProducts.length < 7)
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
    final rawImage = blog['imageUrl'] ?? blog['image'] ?? 'signup/homesign.PNG';
    final imagePath = rawImage is String && rawImage.isNotEmpty ? rawImage : 'signup/homesign.PNG';
    final isNetworkImage = imagePath.startsWith('http') || imagePath.startsWith('https');
    final isDataUrl = imagePath.startsWith('data:image');
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
                          'signup/homesign.PNG',
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
                  'signup/homesign.PNG',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            );
                          },
                        )
                      : Image.asset(
                          imagePath,
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

  Uint8List _decodeBase64Image(String dataUrl) {
    try {
      final base64String = dataUrl.split(',')[1];
      return Uint8List.fromList(base64Decode(base64String));
    } catch (e) {
      return Uint8List(0);
    }
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
      'imageUrl': 'signup/homesign.PNG',
      'summary': 'Discover tasty meals crafted with our farm-fresh ingredients.',
    },
    {
      'title': 'Benefits of Pure A2 Milk',
      'imageUrl': 'signup/homesign.PNG',
      'summary': 'Understand why A2 milk is easier to digest and full of nutrients.',
    },
    {
      'title': 'Traditional Ghee Making Process',
      'imageUrl': 'signup/homesign.PNG',
      'summary': 'A behind-the-scenes look at how we craft golden A2 Bilona ghee.',
    },
    {
      'title': 'Ayurvedic Uses of Panchagavya',
      'imageUrl': 'signup/homesign.PNG',
      'summary': 'Ancient remedies and daily rituals using our Panchagavya products.',
    },
    {
      'title': 'Organic Farming with Cow Products',
      'imageUrl': 'signup/homesign.PNG',
      'summary': 'How natural cow-based inputs enrich soil and boost yields.',
    },
    {
      'title': 'Healthy Recipes with A2 Paneer',
      'imageUrl': 'signup/homesign.PNG',
      'summary': 'High-protein delights you can cook with chemical-free paneer.',
    },
    {
      'title': 'Spiritual Significance of Diyas',
      'imageUrl': 'signup/homesign.PNG',
      'summary': 'Explore the cultural symbolism behind lighting cow-dung diyas.',
    },
    {
      'title': 'Natural Fragrance with Dhoop Sticks',
      'imageUrl': 'signup/homesign.PNG',
      'summary': 'Why our herbal dhoop sticks elevate mood and cleanse spaces.',
    },
  ];

  Widget _buildProductItem(BuildContext context, Product product, String imagePath, double screenWidth) {
    final itemHeight = screenWidth < 360 ? 100.0 : 120.0;
    final imageSize = screenWidth < 360 ? 60.0 : 80.0;
    
    return GestureDetector(
      onTap: () {
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
              child: ClipOval(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFF5E6D3),
                      child: Icon(
                        Icons.image,
                        size: screenWidth < 360 ? 30 : 40,
                        color: const Color(0xFF0B510E),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: _getResponsiveSpacing(context, AppSpacing.xs)),
            Flexible(
              child: Center(
                child: Text(
                  product.name,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: screenWidth < 360 ? 9 : 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
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
