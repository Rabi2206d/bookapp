import 'package:bookstore/const/consts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:bookstore/widgets/bg_widget.dart';
import 'item_details.dart';

class CategoryDetailScreen extends StatelessWidget {
  final String title;
  final String categoryName;

  const CategoryDetailScreen({
    super.key,
    required this.title,
    required this.categoryName,
  });

  // Fetch books from Firestore based on category
  Future<List<Map<String, dynamic>>> fetchFirestoreBooks(String category) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('books')
        .where('category', isEqualTo: category)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Store the original document ID
      return data;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return bgWidget(
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>( 
          future: fetchFirestoreBooks(categoryName),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No books found.'));
            }

            final books = snapshot.data!;

            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              itemCount: books.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 300,
                mainAxisSpacing: 16,
                crossAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final book = books[index];
                final title = book['title'] ?? 'No Title';
                final imageUrl = book['thumbnail'] ?? '';
                final description = book['description'] ?? 'No Description';
                final isbn = book['isbn'] ?? 'No ISBN';
                final authors = (book['authors'] is List && book['authors'].isNotEmpty)
                    ? book['authors'].join(', ')
                    : 'Unknown Author';
                final price = book['price'].toString(); // Keep price as int

                return GestureDetector(
                  onTap: () {
                    Get.to(() => ItemDetails(
                          title: title,
                          imageUrl: imageUrl,
                          description: description,
                          price: price,
                          isbn: isbn,
                          authors: authors,
                        ));
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl.isNotEmpty)
                        Image.network(
                          imageUrl,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.image_not_supported, size: 100);
                          },
                        ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Author: $authors',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Price: PKR $price',
                        style: const TextStyle(fontSize: 13, color: Colors.green),
                      ),
                      const SizedBox(height: 4),
                      ElevatedButton(
                        onPressed: () {
                          Get.to(() => ItemDetails(
                                title: title,
                                imageUrl: imageUrl,
                                description: description,
                                price: price,
                                isbn: isbn,
                                authors: authors,
                              ));
                        },
                        child: const Text('View Details'),
                      ),
                    ],
                  ).box
                      .white
                      .roundedSM
                      .outerShadowSm
                      .margin(const EdgeInsets.symmetric(horizontal: 3))
                      .padding(const EdgeInsets.all(8))
                      .make(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
