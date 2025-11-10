import 'package:flutter/material.dart';

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
}

// --- Admin Carousel Management Screen ---
class AdminCarouselScreen extends StatefulWidget {
  const AdminCarouselScreen({super.key});

  @override
  State<AdminCarouselScreen> createState() => _AdminCarouselScreenState();
}

class _AdminCarouselScreenState extends State<AdminCarouselScreen> {
  // ignore: prefer_final_fields
  List<CarouselImage> _images = [
    CarouselImage(id: 'img-1', name: 'Lapangan-img 1', url: 'https://firebase.storage.example.com/...', altText: 'Gambar Lapangan Tenis 1', order: 1),
    CarouselImage(id: 'img-2', name: 'Lapangan img 2', url: 'https://firebase.storage.example.com/...', altText: 'Gambar Lapangan Tenis 2', order: 2),
    CarouselImage(id: 'img-3', name: 'Lapangan img 3', url: 'https://firebase.storage.example.com/...', altText: 'Gambar Lapangan Tenis 3', order: 3),
    CarouselImage(id: 'img-4', name: 'Lapangan img 4', url: 'https://firebase.storage.example.com/...', altText: 'Gambar Lapangan Tenis 4', order: 4),
    CarouselImage(id: 'img-5', name: 'Lapangan img 5', url: 'https://firebase.storage.example.com/...', altText: 'Gambar Lapangan Tenis 5', order: 5),
    CarouselImage(id: 'img-6', name: 'Lapngan img 6', url: 'https://firebase.storage.example.com/...', altText: 'Gambar Lapangan Tenis 6', order: 6),
  ];

  String? _fileName;
  final TextEditingController _descriptionController = TextEditingController();

  void _pickFile() {
    setState(() {
      _fileName = 'new_image_${_images.length + 1}.jpg';
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('File dipilih: $_fileName')));
  }

  void _uploadAndAdd() {
    if (_fileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih file gambar terlebih dahulu!')),
      );
      return;
    }

    final newImage = CarouselImage(
      id: 'img-${_images.length + 1}',
      name: 'Gambar Baru ${_images.length + 1}',
      url: 'https://firebase.storage.example.com/new_upload.jpg',
      altText: _descriptionController.text.isEmpty
          ? 'Gambar Lapangan'
          : _descriptionController.text,
      order: _images.length + 1,
    );

    setState(() {
      _images.add(newImage);
      _fileName = null;
      _descriptionController.clear();

      _images.sort((a, b) => a.order.compareTo(b.order));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gambar berhasil diunggah dan ditambahkan!')),
    );
  }

  void _deleteImage(String id) {
    setState(() {
      _images.removeWhere((img) => img.id == id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gambar ID $id berhasil dihapus.')),
    );
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;

      final item = _images.removeAt(oldIndex);
      _images.insert(newIndex, item);

      // Update order
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrasi'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  const Text(
                    'Manajemen Gambar Carousel',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Kelola gambar yang ditampilkan di halaman utama (carousel).',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  _buildUploadSection(),
                  const SizedBox(height: 30),

                  Text(
                    'Daftar Gambar (${_images.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 20),
                ],
              ),
            ),
          ),

          SliverReorderableList(
            itemCount: _images.length,
            onReorder: _reorder,
            itemBuilder: (context, index) {
              final image = _images[index];
              return CarouselImageCard(
                key: ValueKey(image.id),
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
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Unggah Gambar Baru', style: TextStyle(fontWeight: FontWeight.bold)),
          const Divider(),

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
                    _fileName ?? 'Choose File • No file chosen',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              ElevatedButton(
                onPressed: _pickFile,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(50, 50),
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black87,
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
              hintText: 'Deskripsi / Alt Text',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _uploadAndAdd,
            icon: const Icon(Icons.upload),
            label: const Text('Unggah & Tambahkan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Widget Card Gambar ---
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
      key: ValueKey(image.id),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          leading: ReorderableDragStartListener(
            index: image.order - 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.menu, color: Colors.grey),
                const SizedBox(width: 5),
                Container(
                  width: 40,
                  height: 40,
                  color: Colors.grey.shade200,
                  child: Center(child: Text('${image.order}')),
                ),
              ],
            ),
          ),
          title: Text(image.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            image.url,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
          ),
        ),
      ),
    );
  }
}
