import 'dart:html' as html;
import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';

class BlogsAdminView extends StatefulWidget {
  const BlogsAdminView({super.key});

  @override
  State<BlogsAdminView> createState() => _BlogsAdminViewState();
}

class _BlogsAdminViewState extends State<BlogsAdminView> {
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  bool _isSeedingDefaults = false;
  // Firestore validates the UTF-8 size of string fields (so for data URLs,
  // it mostly equals the base64 string length). Keep it safely under 1 MiB.
  static const int _maxInlineImageStringBytes = 900 * 1024;

  // Available font families for blogs (used only from admin)
  final List<String> _fontFamilies = [
    'Poppins',
    'Roboto',
    'OpenSans',
    'Lato',
    'Montserrat',
    'Merriweather',
    'Nunito',
    'Raleway',
    'SourceSansPro',
    'Oswald',
  ];

  final List<Map<String, dynamic>> _defaultBlogs = [
    {
      'title': 'Recipes from Girgo products',
      'summary': 'Discover tasty meals crafted with our farm-fresh ingredients.',
      'content':
          'Explore a collection of breakfast, lunch, and dinner recipes prepared with Girgo milk, paneer, ghee, and more. Each recipe focuses on wholesome ingredients and traditional flavors.',
      'imageUrl': 'Products/A2 Desi Paneer.jpg',
      'author': 'Girgo Kitchen',
    },
    {
      'title': 'Benefits of Pure A2 Milk',
      'summary': 'Understand why A2 milk is easier to digest and full of nutrients.',
      'content':
          'A2 beta-casein protein supports better digestion, reduces inflammation, and is ideal for families seeking natural nutrition. Learn how Girgo ensures purity from farm to bottle.',
      'imageUrl': 'Products/A2 DESI GIR COW MILK.jpg',
      'author': 'Girgo Wellness',
    },
    {
      'title': 'Traditional Ghee Making Process',
      'summary': 'A behind-the-scenes look at how we craft golden A2 Bilona ghee.',
      'content':
          'We follow the age-old bilona method—culturing curd, churning butter, and slow-heating on wood fire. This preserves nutrients and aroma, delivering authentic taste.',
      'imageUrl': 'Products/A2 BILONA GHEE.jpg',
      'author': 'Girgo Farms',
    },
    {
      'title': 'Ayurvedic Uses of Panchagavya',
      'summary': 'Ancient remedies and daily rituals using our Panchagavya products.',
      'content':
          'From immunity boosting tonics to natural fertilizers, Panchagavya has multiple uses. Discover simple routines and benefits backed by Ayurveda.',
      'imageUrl': 'Products/PANCHGAVYA COW DUNG CAKE.jpg',
      'author': 'Girgo Ayurveda',
    },
  ];

  @override
  void initState() {
    super.initState();
    _seedDefaultBlogsIfNeeded();
  }

  Future<void> _seedDefaultBlogsIfNeeded() async {
    if (_isSeedingDefaults) return;
    _isSeedingDefaults = true;
    try {
      final existing = await FirestoreService.blogsCollection.limit(1).get();
      if (existing.docs.isEmpty) {
        for (final blog in _defaultBlogs) {
          await FirestoreService.addBlog({
            ...blog,
            'publishedAt': DateTime.now(),
            'isActive': true,
          });
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Default blogs imported.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to seed blogs: $e')),
        );
      }
    } finally {
      _isSeedingDefaults = false;
    }
  }

  Future<void> _toggleBlog(String blogId, bool isActive) async {
    try {
      await FirestoreService.updateBlog(blogId, {'isActive': isActive});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isActive ? 'Blog published' : 'Blog hidden')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  Future<void> _deleteBlog(String blogId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete blog'),
        content: const Text('Are you sure you want to delete this blog post?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirestoreService.deleteBlog(blogId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Blog deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  Future<void> _showAddEditBlogDialog([Map<String, dynamic>? blog]) async {
    final isEditing = blog != null;
    final titleController = TextEditingController(text: blog?['title'] ?? '');
    final summaryController = TextEditingController(text: blog?['summary'] ?? '');
    final contentController = TextEditingController(text: blog?['content'] ?? '');
    final imageUrlController = TextEditingController(text: blog?['imageUrl'] ?? '');
    final authorController = TextEditingController(text: blog?['author'] ?? '');
    DateTime? publishedAt;
    if (blog?['publishedAt'] is Timestamp) {
      publishedAt = (blog!['publishedAt'] as Timestamp).toDate();
    } else if (blog?['publishedAt'] is DateTime) {
      publishedAt = blog!['publishedAt'] as DateTime;
    } else {
      publishedAt = DateTime.now();
    }
    bool isActive = blog?['isActive'] ?? true;
    String selectedFontFamily = blog?['fontFamily'] ?? 'Poppins';

    final formKey = GlobalKey<FormState>();
    Future<void>? pendingImageUpload;

    void _applyFormatting(TextEditingController controller, String left, [String? right]) {
      right ??= left;
      final selection = controller.selection;
      final text = controller.text;

      if (!selection.isValid) {
        controller.text = '$left$right';
        controller.selection = TextSelection.collapsed(offset: left.length);
        return;
      }

      final start = selection.start;
      final end = selection.end;
      final selectedText = text.substring(start, end);
      final newText = text.replaceRange(start, end, '$left$selectedText$right');

      controller.value = controller.value.copyWith(
        text: newText,
        selection: TextSelection(
          baseOffset: start + left.length,
          extentOffset: start + left.length + selectedText.length,
        ),
      );
    }

    // For Firestore size checks we compare against `dataUrl.length`,
    // because base64 data URLs are ASCII and Firestore counts string bytes.
    int estimateDataUrlBytes(String dataUrl) => dataUrl.length;

    Future<String> compressForFirestore(html.File file) async {
      final reader = html.FileReader()..readAsDataUrl(file);
      await reader.onLoadEnd.first;
      final rawDataUrl = reader.result as String?;
      if (rawDataUrl == null || rawDataUrl.isEmpty) {
        throw Exception('Unable to read image file');
      }

      final image = html.ImageElement(src: rawDataUrl);
      await image.onLoad.first;

      var sourceWidth = image.naturalWidth ?? image.width ?? 0;
      var sourceHeight = image.naturalHeight ?? image.height ?? 0;
      if (sourceWidth <= 0 || sourceHeight <= 0) return rawDataUrl;

      // Resize large images to keep Firestore payload under document limits.
      const maxDimension = 1200;
      final scale = math.min(1.0, maxDimension / math.max(sourceWidth, sourceHeight));
      final targetWidth = math.max(1, (sourceWidth * scale).round());
      final targetHeight = math.max(1, (sourceHeight * scale).round());

      final canvas = html.CanvasElement(width: targetWidth, height: targetHeight);
      final ctx = canvas.context2D;
      ctx.drawImageScaled(image, 0, 0, targetWidth, targetHeight);

      var quality = 0.82;
      var compressed = canvas.toDataUrl('image/jpeg', quality);
      while (estimateDataUrlBytes(compressed) > _maxInlineImageStringBytes && quality > 0.42) {
        quality -= 0.08;
        compressed = canvas.toDataUrl('image/jpeg', quality);
      }
      return compressed;
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Blog' : 'Add Blog'),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    // Font family selector (applies in app only, not in admin preview)
                    DropdownButtonFormField<String>(
                      value: selectedFontFamily,
                      decoration: const InputDecoration(
                        labelText: 'Font family for app',
                        border: OutlineInputBorder(),
                        helperText: 'How this blog text appears in the customer app',
                      ),
                      items: _fontFamilies
                          .map(
                            (f) => DropdownMenuItem(
                              value: f,
                              child: Text(f),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          selectedFontFamily = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Summary formatting:',
                            style: TextStyle(fontSize: 12),
                          ),
                          TextButton(
                            onPressed: () => _applyFormatting(summaryController, '**'),
                            child: const Text(
                              'B',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _applyFormatting(summaryController, '_'),
                            child: const Text(
                              'I',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: summaryController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Summary',
                        hintText: 'Short intro. Supports **bold** and _italic_.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Content formatting:',
                            style: TextStyle(fontSize: 12),
                          ),
                          TextButton(
                            onPressed: () => _applyFormatting(contentController, '**'),
                            child: const Text(
                              'B',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _applyFormatting(contentController, '_'),
                            child: const Text(
                              'I',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: contentController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Content *',
                        hintText: 'Full blog content. Supports **bold** and _italic_.',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Content is required' : null,
                    ),
                    const SizedBox(height: 16),
                    // Upload button and URL field row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: imageUrlController,
                            decoration: const InputDecoration(
                              labelText: 'Cover image for this post *',
                              hintText: 'Upload or paste image link / asset path',
                              border: OutlineInputBorder(),
                              helperText: 'Each blog has its own image; uploads go live after save',
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Image is required' : null,
                            onChanged: (value) => setDialogState(() {}), // Refresh preview
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (kIsWeb)
                          ElevatedButton.icon(
                            onPressed: () async {
                              // Create file input element
                              final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
                              uploadInput.accept = 'image/*';
                              uploadInput.click();
                              
                              uploadInput.onChange.listen((e) async {
                                final files = uploadInput.files;
                                if (files == null || files.isEmpty) return;
                                
                                final file = files[0];
                                if (file.size > 10 * 1024 * 1024) {
                                  // 10MB limit
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Image size must be less than 10MB')),
                                    );
                                  }
                                  return;
                                }
                                
                                final uploadCompleter = Completer<void>();
                                pendingImageUpload = uploadCompleter.future;
                                try {
                                  final compressedDataUrl = await compressForFirestore(file);
                                  imageUrlController.text = compressedDataUrl;
                                  setDialogState(() {});
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Image ready — saved inline in Firestore when you tap Add/Update'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.red.shade700,
                                        content: Text('Upload failed: $e'),
                                      ),
                                    );
                                  }
                                } finally {
                                  uploadCompleter.complete();
                                }
                              });
                            },
                            icon: const Icon(Icons.upload_file, size: 20),
                            label: const Text('Upload'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('File upload available on web only')),
                              );
                            },
                            icon: const Icon(Icons.upload_file, size: 20),
                            label: const Text('Upload'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Image preview
                    if (imageUrlController.text.isNotEmpty)
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                          color: Colors.grey.shade100,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: (imageUrlController.text.startsWith('http') || imageUrlController.text.startsWith('data:'))
                              ? Image.network(
                                  imageUrlController.text,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.error_outline, color: Colors.red),
                                          SizedBox(height: 8),
                                          Text(
                                            'Failed to load image',
                                            style: TextStyle(color: Colors.red, fontSize: 12),
                                          ),
                                          Text(
                                            'Check if URL is correct',
                                            style: TextStyle(color: Colors.grey, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey.shade200,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image, size: 48, color: Colors.grey.shade600),
                                      SizedBox(height: 8),
                                      Text(
                                        'Asset Path Preview',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      ),
                                      Text(
                                        imageUrlController.text,
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: authorController,
                      decoration: const InputDecoration(
                        labelText: 'Author',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Publish Date'),
                      subtitle: Text(_dateFormat.format(publishedAt ?? DateTime.now())),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: publishedAt ?? DateTime.now(),
                            firstDate: DateTime(2023),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setDialogState(() => publishedAt = picked);
                          }
                        },
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active'),
                      value: isActive,
                      onChanged: (value) => setDialogState(() => isActive = value),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (pendingImageUpload != null) {
                  await pendingImageUpload;
                }
                if (!formKey.currentState!.validate()) return;

                final imageUrl = imageUrlController.text.trim();
                if (imageUrl.startsWith('data:image') &&
                    estimateDataUrlBytes(imageUrl) > _maxInlineImageStringBytes) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.red.shade700,
                        content: const Text('Image is too large for Firestore. Choose a smaller image.'),
                      ),
                    );
                  }
                  return;
                }

                final data = {
                  'title': titleController.text.trim(),
                  'summary': summaryController.text.trim(),
                  'content': contentController.text.trim(),
                  'imageUrl': imageUrl,
                  'author': authorController.text.trim(),
                  'publishedAt': Timestamp.fromDate(publishedAt ?? DateTime.now()),
                  'isActive': isActive,
                  'fontFamily': selectedFontFamily,
                };

                try {
                  if (isEditing) {
                    await FirestoreService.updateBlog(blog!['id'] as String, data);
                  } else {
                    await FirestoreService.addBlog(data);
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEditing ? 'Blog updated' : 'Blog added')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to save: $e')),
                    );
                  }
                }
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService.getAllBlogs(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final blogs = snapshot.data!;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Blogs',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => _showAddEditBlogDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Blog'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: blogs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.article_outlined, size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No blogs found. Add your first blog post!'),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: blogs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final blog = blogs[index];
                        final isActive = blog['isActive'] == true;
                        DateTime publishedDate = DateTime.now();
                        if (blog['publishedAt'] is Timestamp) {
                          publishedDate = (blog['publishedAt'] as Timestamp).toDate();
                        } else if (blog['publishedAt'] is DateTime) {
                          publishedDate = blog['publishedAt'] as DateTime;
                        }

                        return Card(
                          elevation: 2,
                          child: InkWell(
                            onTap: () => _showAddEditBlogDialog(blog),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 96,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey.shade200,
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: blog['imageUrl'] != null && blog['imageUrl'].toString().isNotEmpty
                                        ? ((blog['imageUrl'].toString().startsWith('http') || blog['imageUrl'].toString().startsWith('data:'))
                                            ? Image.network(
                                                blog['imageUrl'],
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    color: Colors.grey.shade200,
                                                    child: Center(
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(Icons.broken_image, size: 24, color: Colors.grey.shade600),
                                                          SizedBox(height: 4),
                                                          Text(
                                                            'Image',
                                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  return Center(
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  );
                                                },
                                              )
                                            : Container(
                                                color: Colors.grey.shade200,
                                                child: Center(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.image, size: 24, color: Colors.grey.shade600),
                                                      SizedBox(height: 4),
                                                      Text(
                                                        'Asset',
                                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                                                      ),
                                                      Text(
                                                        blog['imageUrl'].toString().split('/').last,
                                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 8),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ))
                                        : Container(
                                            color: Colors.grey.shade200,
                                            child: Center(
                                              child: Icon(Icons.image, size: 32, color: Colors.grey.shade400),
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          blog['title'] ?? 'Untitled',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          blog['summary'] ?? blog['content'] ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: Colors.grey.shade700),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 12,
                                          children: [
                                            Chip(
                                              label: Text(isActive ? 'Active' : 'Hidden'),
                                              backgroundColor: isActive
                                                  ? Colors.green.withOpacity(0.1)
                                                  : Colors.grey.withOpacity(0.2),
                                            ),
                                            Text('Published ${_dateFormat.format(publishedDate)}'),
                                            if ((blog['author'] as String?)?.isNotEmpty ?? false)
                                              Text('• ${(blog['author'] as String)}'),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Switch(
                                        value: isActive,
                                        onChanged: (value) => _toggleBlog(blog['id'] as String, value),
                                      ),
                                      const SizedBox(height: 8),
                                      IconButton(
                                        tooltip: 'Edit',
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () => _showAddEditBlogDialog(blog),
                                      ),
                                      IconButton(
                                        tooltip: 'Delete',
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () => _deleteBlog(blog['id'] as String),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

