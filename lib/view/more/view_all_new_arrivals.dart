import 'package:bookstore/const/consts.dart';
import 'package:bookstore/view/Category_Screen/item_details.dart';
import 'package:bookstore/widgets/bg_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewAllNewArrivals extends StatefulWidget {
  const ViewAllNewArrivals({super.key});

  @override
  _ViewAllNewArrivalsState createState() => _ViewAllNewArrivalsState();
}

class _ViewAllNewArrivalsState extends State<ViewAllNewArrivals> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> newArrivals = [];
  bool isLoading = true;

  // Filter Variables
  String selectedCategory = 'All';
  RangeValues selectedPriceRange = const RangeValues(0, 3000); // Default price range
  List<String> categories = [
    "All",
    "Fiction",
    "Classic",
    "Romance",
    "Mystery",
    "Fantasy",
    "History",
    "Comic",
    "Crime"
  ];

  late List<Map<String, dynamic>> priceRanges;

  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Key for the Scaffold

  @override
  void initState() {
    super.initState();
    _fetchNewArrivals();
    _generatePriceRanges();
  }

  Future<void> _fetchNewArrivals() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('books')
          .where('isNewArrival', isEqualTo: true)
          .get();

      setState(() {
        newArrivals = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching new arrivals: $e")),
      );
    }
  }

  void _generatePriceRanges() {
    // Find the minimum and maximum price
    double minPrice = double.infinity;
    double maxPrice = 0.0;

    for (var book in newArrivals) {
      double price = book['price']?.toDouble() ?? 0.0;
      if (price < minPrice) minPrice = price;
      if (price > maxPrice) maxPrice = price;
    }

    priceRanges = [
      {"label": "All Prices", "range": RangeValues(minPrice, maxPrice)},
      {"label": "0 - 1000", "range": const RangeValues(0, 1000)},
      {"label": "1000 - 2000", "range": const RangeValues(1000, 2000)},
      {"label": "2000 - 3000", "range": const RangeValues(2000, 3000)},
      {"label": "3000 - 5000", "range": const RangeValues(3000, 5000)}
    ];
  }

  // Function to filter books based on selected category and price range
  List<Map<String, dynamic>> _filterBooks() {
    return newArrivals.where((book) {
      bool matchesCategory =
          selectedCategory == 'All' || book['category'] == selectedCategory;
      bool matchesPrice = true;

      // If "All Prices" is selected, we don't apply any price filter
      if (selectedPriceRange != priceRanges[0]['range']) {
        matchesPrice = book['price'] >= selectedPriceRange.start &&
            book['price'] <= selectedPriceRange.end;
      }

      return matchesCategory && matchesPrice;
    }).toList();
  }

  // Function to build the filter drawer
  Widget _buildFilterDrawer() {
    return Drawer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Filter Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Category Filter
            const Text('Category'),
            Column(
              children: categories.map((category) {
                return RadioListTile<String>(
                  value: category,
                  groupValue: selectedCategory,
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                    Navigator.pop(
                        context); // Close the drawer after selecting a category
                  },
                  title: Text(category),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // Price Range Filter
            const Text('Price Range'),
            Column(
              children: priceRanges.map((priceRange) {
                return RadioListTile<RangeValues>(
                  value: priceRange['range']!,
                  groupValue: selectedPriceRange,
                  onChanged: (value) {
                    setState(() {
                      selectedPriceRange = value!;
                    });
                    Navigator.pop(
                        context); // Close the drawer after selecting a price range
                  },
                  title: Text(priceRange['label']!),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return bgWidget(
      child: Scaffold(
        key: _scaffoldKey, // Set the key for the Scaffold
        appBar: AppBar(
          title: const Text('All New Arrivals'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context); // This will take the user back
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_alt),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer(); // Open the drawer
              },
            ),
          ],
        ),
        drawer: _buildFilterDrawer(),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _filterBooks().isEmpty
                ? const Center(
                    child:
                        Text('No new arrivals available for selected filters'))
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filterBooks().length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 300,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      final book = _filterBooks()[index];
                      return _buildBookGridItem(book);
                    },
                  ),
      ),
    );
  }

  Widget _buildBookGridItem(Map<String, dynamic> book) {
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetails(
              title: title,
              imageUrl: imageUrl,
              description: description,
              price: price,
              isbn: isbn,
              authors: authors,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8), // Rounded corners
              child: SizedBox(
                height: 140, // Set a fixed height for the image
                width: double.infinity,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover, // Use BoxFit.cover to fill the space
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.image_not_supported, size: 100);
                  },
                ),
              ),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemDetails(
                    title: title,
                    imageUrl: imageUrl,
                    description: description,
                    price: price,
                    isbn: isbn,
                    authors: authors,
                  ),
                ),
              );
            },
            child: const Text('View Details'),
          ),
        ],
      )
          .box
          .white
          .roundedSM
          .outerShadowSm
          .margin(const EdgeInsets.symmetric(horizontal: 3))
          .padding(const EdgeInsets.all(8))
          .make(),
    );
  }
}
