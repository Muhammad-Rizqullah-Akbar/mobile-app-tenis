import 'dart:io'; // Untuk menampilkan preview gambar di HP
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // [WAJIB] Import Image Picker
import '../services/firestore_service.dart';

// --- Model Data Gambar Carousel ---
class CarouselImage {
  final String id;
  final String name;
  final String url;
  final String altText;
  final int order;

  CarouselImage({
    required this.id,
    required this.name,
    required this.url,
    required this.altText,
    required this.order,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'altText': altText,
    'order': order,
  };
}

// --- Admin Carousel Management Screen ---
class AdminCarouselScreen extends StatefulWidget {
  const AdminCarouselScreen({super.key});

  @override
  State<AdminCarouselScreen> createState() => _AdminCarouselScreenState();
}

class _AdminCarouselScreenState extends State<AdminCarouselScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker(); // Instance Image Picker

  List<CarouselImage> _images = [];
  XFile? _pickedFile; // File yang dipilih user
  String? _fileName;

  bool _isLoading = false;
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      final stream = _firestoreService.getCarouselStream();
      final snapshot = await stream.first; // Ambil sekali saja
      if (mounted && snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>?;
        final imagesData = data?['images'] as List? ?? [];

        setState(() {
          _images = imagesData
              .map(
                (img) => CarouselImage(
                  id: img['id'] ?? '',
                  name: img['name'] ?? '',
                  url: img['url'] ?? '',
                  altText: img['altText'] ?? '',
                  order: img['order'] ?? 0,
                ),
              )
              .toList();

          // Sortir berdasarkan urutan agar tampilan sesuai
          _images.sort((a, b) => a.order.compareTo(b.order));
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading carousel images: $e');
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // 1. FUNGSI PILIH GAMBAR (REAL)
  Future<void> _pickFile() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Kompres sedikit biar cepat upload
      );

      if (image != null) {
        setState(() {
          _pickedFile = image;
          _fileName = image.name;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gambar berhasil dipilih!')),
        );
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // 2. FUNGSI UPLOAD KE FIREBASE STORAGE & SIMPAN DATA
  Future<void> _uploadAndAdd() async {
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih file gambar terlebih dahulu!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // A. Upload Gambar ke Storage
      String uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$_fileName';
      String downloadUrl = await _firestoreService.uploadCarouselImage(
        _pickedFile!,
        uniqueName,
      );

      // B. Buat Object CarouselImage Baru
      final newImage = CarouselImage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _fileName!,
        url: downloadUrl, // Gunakan URL asli dari Firebase
        altText: _descriptionController.text.isEmpty
            ? 'Gambar Lapangan'
            : _descriptionController.text,
        order: _images.length + 1, // Taruh di urutan terakhir
      );

      // C. Update State Lokal & Kirim ke Firestore
      setState(() {
        _images.add(newImage);
      });

      await _firestoreService.updateCarouselImages(
        _images.map((i) => i.toJson()).toList(),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _pickedFile = null;
          _fileName = null;
          _descriptionController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Gambar berhasil diunggah!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    }
  }

  // 3. FUNGSI HAPUS GAMBAR
  Future<void> _deleteImage(String id) async {
    // Konfirmasi hapus
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Gambar?'),
            content: const Text('Gambar akan dihapus dari carousel.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      setState(() {
        _images.removeWhere((img) => img.id == id);
        // Reset urutan (1, 2, 3...) setelah hapus
        for (int i = 0; i < _images.length; i++) {
          _images[i] = CarouselImage(
            id: _images[i].id,
            name: _images[i].name,
            url: _images[i].url,
            altText: _images[i].altText,
            order: i + 1,
          );
        }
      });

      await _firestoreService.updateCarouselImages(
        _images.map((i) => i.toJson()).toList(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Gambar berhasil dihapus!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    }
  }

  // 4. FUNGSI REORDER (GESER URUTAN)
  Future<void> _reorder(int oldIndex, int newIndex) async {
    setState(() => _isLoading = true);
    try {
      setState(() {
        if (newIndex > oldIndex) newIndex -= 1;
        final item = _images.removeAt(oldIndex);
        _images.insert(newIndex, item);

        // Update field 'order' untuk semua item sesuai posisi baru
        for (int i = 0; i < _images.length; i++) {
          _images[i] = CarouselImage(
            id: _images[i].id,
            name: _images[i].name,
            url: _images[i].url,
            altText: _images[i].altText,
            order: i + 1,
          );
        }
      });

      // Simpan urutan baru ke Firestore
      await _firestoreService.updateCarouselImages(
        _images.map((i) => i.toJson()).toList(),
      );

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Carousel'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading &&
              _images
                  .isEmpty // Loading awal saja
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const Text(
                        'Kelola Banner Aplikasi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Urutkan gambar dengan menekan tahan dan geser.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),

                      _buildUploadSection(),
                      const SizedBox(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Daftar Gambar (${_images.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_isLoading && _images.isNotEmpty)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const Divider(height: 20),
                    ]),
                  ),
                ),

                SliverReorderableList(
                  itemCount: _images.length,
                  onReorder: _reorder,
                  itemBuilder: (context, index) {
                    final image = _images[index];
                    return CarouselImageCard(
                      key: ValueKey(
                        image.id,
                      ), // Key unik wajib untuk ReorderableList
                      image: image,
                      onDelete: () => _deleteImage(image.id),
                    );
                  },
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Unggah Gambar Baru',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Area Preview Gambar
          if (_pickedFile != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: kIsWeb
                      ? Image.network(_pickedFile!.path, fit: BoxFit.cover)
                      : Image.file(File(_pickedFile!.path), fit: BoxFit.cover),
                ),
              ),
            ),

          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _fileName ?? 'Belum ada file dipilih',
                    style: TextStyle(
                      color: _fileName == null ? Colors.grey : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _pickFile,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(50, 50),
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Icon(Icons.image),
              ),
            ],
          ),

          const SizedBox(height: 15),

          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Deskripsi / Alt Text (Opsional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              isDense: true,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _uploadAndAdd,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.cloud_upload),
              label: Text(_isLoading ? 'Mengunggah...' : 'Unggah & Tambahkan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Widget Card Gambar (Draggable) ---
class CarouselImageCard extends StatelessWidget {
  final CarouselImage image;
  final VoidCallback onDelete;

  const CarouselImageCard({
    super.key,
    required this.image,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          // Handle untuk Drag
          leading: ReorderableDragStartListener(
            index: image.order - 1,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.drag_handle, color: Colors.grey),
            ),
          ),
          // Preview Kecil
          title: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  image.url,
                  width: 60,
                  height: 45,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    width: 60,
                    height: 45,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.broken_image, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama File (Bold)
                    Text(
                      image.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Alt Text (Subtitle) - FIX: Tampilkan altText, bukan URL
                    Text(
                      image.altText.isNotEmpty
                          ? image.altText
                          : "Tidak ada deskripsi",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: image.altText.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
            tooltip: "Hapus Gambar",
          ),
        ),
      ),
    );
  }
}
