import 'package:flutter/material.dart';
import '../constants/products.dart';
import '../utils/data_url_image_decoder.dart';

/// Normalizes a bundled path the way Firestore/admin often stores it.
String normalizeBundledImagePath(String path) {
  var p = path.trim();
  if (p.startsWith('assets/')) {
    p = p.substring(7);
  }
  return p;
}

String? _categoryHomeAsset(String category) {
  switch (category.toLowerCase()) {
    case 'milk':
      return 'homeicon/milkhome.PNG';
    case 'ghee':
      return 'homeicon/gheehom.PNG';
    case 'paneer':
      return 'homeicon/paneerhome.PNG';
    case 'dung cakes':
    case 'pachagavya':
    case 'panchagavya':
      return 'homeicon/cakehome.PNG';
    case 'diyas':
      return 'homeicon/dungdiya.PNG';
    case 'dhoopa':
      return 'homeicon/dhoopstikchome.PNG';
    case 'gomutra':
      return 'homeicon/gomurahome.PNG';
    default:
      return null;
  }
}

/// Ordered list of local asset paths to try for a product image.
List<String> assetCandidatesForProduct(Product? product, String rawPath) {
  final out = <String>[];
  void add(String? s) {
    if (s == null || s.isEmpty) return;
    final t = s.trim();
    if (t.startsWith('http://') ||
        t.startsWith('https://') ||
        t.startsWith('data:')) {
      return;
    }
    final p = normalizeBundledImagePath(t);
    if (!out.contains(p)) out.add(p);
  }

  add(rawPath);
  if (product != null) {
    for (final p in Products.allProducts) {
      if (p.id == product.id) {
        add(p.image);
        break;
      }
    }
    add(_categoryHomeAsset(product.category));
  }
  add('singup/logo.png');
  return out;
}

Widget _roundPlaceholder(double size, {IconData icon = Icons.image}) {
  return Container(
    width: size,
    height: size,
    color: const Color(0xFFF5E6D3),
    child: Icon(
      icon,
      size: size * 0.45,
      color: const Color(0xFF0B510E),
    ),
  );
}

Widget _assetFallbackChain(List<String> paths, int index, double size, BoxFit fit) {
  if (index >= paths.length) {
    return _roundPlaceholder(size);
  }
  return Image.asset(
    paths[index],
    width: size,
    height: size,
    fit: fit,
    errorBuilder: (context, error, stackTrace) {
      return _assetFallbackChain(paths, index + 1, size, fit);
    },
  );
}

/// Rounds image for featured grid, product cards: network / data URL / assets with fallbacks.
class ProductThumbnail extends StatelessWidget {
  final Product? product;
  final String imageRaw;
  final double size;
  final BoxFit fit;
  final bool circular;

  const ProductThumbnail({
    super.key,
    required this.product,
    required this.imageRaw,
    required this.size,
    this.fit = BoxFit.cover,
    this.circular = false,
  });

  @override
  Widget build(BuildContext context) {
    final raw = imageRaw.trim();
    final candidates = assetCandidatesForProduct(product, raw);

    Widget inner;
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      inner = Image.network(
        raw,
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _assetFallbackChain(candidates, 0, size, fit);
        },
      );
    } else if (raw.startsWith('data:image')) {
      inner = Image.memory(
        DataUrlImageDecoder.decode(raw),
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _assetFallbackChain(candidates, 0, size, fit);
        },
      );
    } else {
      inner = _assetFallbackChain(candidates, 0, size, fit);
    }

    if (!circular) return inner;
    return ClipOval(child: inner);
  }
}
