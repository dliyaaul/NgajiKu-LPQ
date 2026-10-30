import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ptl_mobile/models/hadits/hadits_book_model.dart';

import '../../state_management/hadits_provider.dart';

class HaditsPage extends StatefulWidget {
  const HaditsPage({super.key});

  @override
  State<HaditsPage> createState() => _HaditsPageState();
}

class _HaditsPageState extends State<HaditsPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HaditsProvider>().fetchBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF263238),
        elevation: 0,
        title: const Text(
          'Hadits',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<HaditsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingBooks && !provider.hasBooksData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D8B8B)),
            );
          }

          if (provider.errorMessage != null && !provider.hasBooksData) {
            return _buildErrorState(provider);
          }

          return RefreshIndicator(
            color: const Color(0xFF0D8B8B),
            onRefresh: provider.refreshBooks,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: provider.books.length,
              itemBuilder: (context, index) {
                final book = provider.books[index];

                return _buildBookCard(book);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookCard(HaditsBookModel book) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF0D8B8B).withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.menu_book_rounded, color: Color(0xFF0D8B8B)),
        ),
        title: Text(
          book.name,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF263238),
          ),
        ),
        subtitle: Text(
          '${book.total} Hadits',
          style: const TextStyle(fontSize: 12, color: Color(0xFF78909C)),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF90A4AE),
        ),
        onTap: () {
          // Kita isi setelah daftar kitab berhasil tampil.
        },
      ),
    );
  }

  Widget _buildErrorState(HaditsProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 60,
              color: Color(0xFF90A4AE),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat kitab hadits',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage ?? 'Terjadi kesalahan.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF78909C)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: provider.fetchBooks,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D8B8B),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
