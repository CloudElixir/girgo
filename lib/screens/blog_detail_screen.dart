import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/theme.dart';
import '../widgets/cart_icon_button.dart';
import '../utils/data_url_image_decoder.dart';

class BlogDetailScreen extends StatelessWidget {
  final Map<String, dynamic> blog;

  const BlogDetailScreen({
    super.key,
    required this.blog,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final rawImage = blog['imageUrl'] ?? blog['image'] ?? 'signup/homesign.PNG';
    final imagePath = rawImage is String && rawImage.isNotEmpty ? rawImage : 'signup/homesign.PNG';
    final isNetworkImage = imagePath.startsWith('http') || imagePath.startsWith('https');
    final isDataUrl = imagePath.startsWith('data:image');
    
    final title = blog['title'] ?? 'Blog Post';
    final summary = blog['summary'] ?? '';
    final content = blog['content'] ?? '';
    final author = blog['author'] ?? '';
    final publishedAt = blog['publishedAt'];
    final fontFamily = (blog['fontFamily'] as String?) ?? 'Poppins';
    
    // Helper method to get responsive font size
    double getResponsiveFontSize(double baseSize) {
      if (screenWidth < 360) {
        return baseSize * 0.85;
      } else if (screenWidth < 400) {
        return baseSize * 0.9;
      }
      return baseSize;
    }
    
    // Helper method to get responsive spacing
    double getResponsiveSpacing(double baseSpacing) {
      if (screenWidth < 360) {
        return baseSpacing * 0.75;
      } else if (screenWidth < 400) {
        return baseSpacing * 0.85;
      }
      return baseSpacing;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B510E),
        foregroundColor: Colors.white,
        title: Text(
          'Blog',
          style: TextStyle(
            fontSize: getResponsiveFontSize(18.0),
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        actions: const [
          CartIconButton(),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(getResponsiveSpacing(AppSpacing.md)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: getResponsiveFontSize(24.0),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0B510E),
                  height: 1.3,
                ),
              ),
              
              SizedBox(height: getResponsiveSpacing(AppSpacing.sm)),
              
              // Author and Date
              if (author.isNotEmpty || publishedAt != null)
                Row(
                  children: [
                    if (author.isNotEmpty) ...[
                      Icon(
                        Icons.person_outline,
                        size: getResponsiveFontSize(16.0),
                        color: AppColors.textLight,
                      ),
                      SizedBox(width: getResponsiveSpacing(AppSpacing.xs)),
                      Flexible(
                        child: Text(
                          author,
                          style: TextStyle(
                            fontSize: getResponsiveFontSize(14.0),
                            color: AppColors.textLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (author.isNotEmpty && publishedAt != null)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: getResponsiveSpacing(AppSpacing.sm),
                        ),
                        child: Text(
                          '•',
                          style: TextStyle(
                            fontSize: getResponsiveFontSize(14.0),
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                    if (publishedAt != null) ...[
                      Icon(
                        Icons.calendar_today,
                        size: getResponsiveFontSize(16.0),
                        color: AppColors.textLight,
                      ),
                      SizedBox(width: getResponsiveSpacing(AppSpacing.xs)),
                      Text(
                        _formatDate(publishedAt),
                        style: TextStyle(
                          fontSize: getResponsiveFontSize(14.0),
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ],
                ),
              
              SizedBox(height: getResponsiveSpacing(AppSpacing.md)),
              
              // Featured image
              ClipRRect(
                borderRadius: BorderRadius.circular(AppBorderRadius.large),
                child: AspectRatio(
                  aspectRatio: screenWidth > 500 ? 16 / 7 : 16 / 9,
                  child: isNetworkImage
                      ? Image.network(
                          imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'signup/homesign.PNG',
                              fit: BoxFit.cover,
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
                              DataUrlImageDecoder.decode(imagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'signup/homesign.PNG',
                                  fit: BoxFit.cover,
                                );
                              },
                            )
                          : Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
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
                            ),
                ),
              ),
              
              SizedBox(height: getResponsiveSpacing(AppSpacing.lg)),
              
              // Summary (markdown)
              if (summary.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(getResponsiveSpacing(AppSpacing.md)),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B510E).withOpacity(0.07),
                    borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                  ),
                  child: MarkdownBody(
                    data: summary,
                    styleSheet: _buildMarkdownStyleSheet(
                      context: context,
                      baseFontSize: getResponsiveFontSize(16.0),
                      fontFamily: fontFamily,
                      color: const Color(0xFF0B510E),
                      lineHeight: 1.5,
                    ),
                  ),
                ),
              
              if (summary.isNotEmpty)
                SizedBox(height: getResponsiveSpacing(AppSpacing.lg)),
              
              // Content (markdown)
              MarkdownBody(
                data: content.isNotEmpty ? content : summary,
                styleSheet: _buildMarkdownStyleSheet(
                  context: context,
                  baseFontSize: getResponsiveFontSize(15.0),
                  fontFamily: fontFamily,
                  color: AppColors.text,
                  lineHeight: 1.6,
                ),
              ),
              
              SizedBox(height: getResponsiveSpacing(AppSpacing.xl)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    
    try {
      DateTime dateTime;
      if (date is DateTime) {
        dateTime = date;
      } else if (date is String) {
        dateTime = DateTime.parse(date);
      } else {
        // Assume it's a Firestore Timestamp
        dateTime = date.toDate();
      }
      
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      
      return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
    } catch (e) {
      return '';
    }
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet({
    required BuildContext context,
    required double baseFontSize,
    required String fontFamily,
    required Color color,
    required double lineHeight,
  }) {
    TextStyle baseStyle;
    switch (fontFamily) {
      case 'Roboto':
        baseStyle = GoogleFonts.roboto(
          fontSize: baseFontSize,
          color: color,
          height: lineHeight,
        );
        break;
      case 'OpenSans':
        baseStyle = GoogleFonts.openSans(
          fontSize: baseFontSize,
          color: color,
          height: lineHeight,
        );
        break;
      case 'Lato':
        baseStyle = GoogleFonts.lato(
          fontSize: baseFontSize,
          color: color,
          height: lineHeight,
        );
        break;
      case 'Montserrat':
        baseStyle = GoogleFonts.montserrat(
          fontSize: baseFontSize,
          color: color,
          height: lineHeight,
        );
        break;
      case 'Merriweather':
        baseStyle = GoogleFonts.merriweather(
          fontSize: baseFontSize,
          color: color,
          height: lineHeight,
        );
        break;
      case 'Nunito':
        baseStyle = GoogleFonts.nunito(
          fontSize: baseFontSize,
          color: color,
          height: lineHeight,
        );
        break;
      case 'Raleway':
        baseStyle = GoogleFonts.raleway(
          fontSize: baseFontSize,
          color: color,
          height: lineHeight,
        );
        break;
      case 'SourceSansPro':
        baseStyle = GoogleFonts.sourceSans3(
          fontSize: baseFontSize,
          color: color,
          height: lineHeight,
        );
        break;
      case 'Oswald':
        baseStyle = GoogleFonts.oswald(
          fontSize: baseFontSize,
          color: color,
          height: lineHeight,
        );
        break;
      case 'Poppins':
      default:
        baseStyle = GoogleFonts.poppins(
          fontSize: baseFontSize,
          color: color,
          height: lineHeight,
        );
        break;
    }

    return MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: baseStyle,
      strong: baseStyle.copyWith(fontWeight: FontWeight.bold),
      em: baseStyle.copyWith(fontStyle: FontStyle.italic),
    );
  }
}

