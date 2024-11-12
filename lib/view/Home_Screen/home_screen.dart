import 'package:bookstore/view/more/view_all_new_arrivals.dart';
import 'package:bookstore/view/more/view_all_books.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bookstore/const/consts.dart';
import 'package:bookstore/const/list.dart';
import 'package:bookstore/view/Category_Screen/item_details.dart';
import 'dart:async';
// Import VxSwiper for image slider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const BookStoreApp());
}

class BookStoreApp extends StatelessWidget {
  const BookStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Store',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> books = [];
  List<Map<String, dynamic>> newArrivals = [];
  List<Map<String, dynamic>> allBooks = [];
  List<Map<String, dynamic>> filteredBooks = [];
  bool isLoading = true;
  bool isLoadingNewArrivals = true;
  bool isLoadingAllBooks = true;
  final FocusNode _searchFocusNode = FocusNode();
  bool isSearching = false;
  Timer? _debounce;

  // Pagination variables
  int currentPage = 0;
  final int itemsPerPage = 2; // Display 2 items per page for New Arrivals
  final PageController _pageController = PageController();

  int currentPageAllBooks = 0;
  final int itemsPerPageAllBooks = 2; // Display 2 items per page for All Books

  // Timer for auto pagination
  Timer? _paginationTimer;

  @override
  void initState() {
    super.initState();
    _fetchBooks();
    _fetchNewArrivals();
    _fetchAllBooks();
    _searchFocusNode.addListener(_onSearchFocusChange);
    _startPaginationTimer(); // Start the pagination timer
  }

  void _onSearchFocusChange() {
    setState(() {});
  }

  Future<void> _fetchBooks() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('books').get();
      setState(() {
        books = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        filteredBooks = [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching books: $e")),
      );
    }
  }

  Future<void> _fetchNewArrivals() async {
    setState(() {
      isLoadingNewArrivals = true;
    });

    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('books')
          .where('isNewArrival', isEqualTo: true)
          .limit(12)
          .get();

      setState(() {
        newArrivals = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching new arrivals: $e")),
      );
    } finally {
      setState(() {
        isLoadingNewArrivals = false;
      });
    }
  }

  Future<void> _fetchAllBooks() async {
    setState(() {
      isLoadingAllBooks = true;
    });

    try {
      final QuerySnapshot snapshot = await _firestore.collection('books').get();
      setState(() {
        allBooks = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching all books: $e")),
      );
    } finally {
      setState(() {
        isLoadingAllBooks = false;
      });
    }
  }

  void _searchBooks(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        isSearching = query.isNotEmpty;
        filteredBooks = query.isEmpty
            ? [] // Return empty list if search query is cleared
            : books.where((book) {
                final titleLower = book['title']?.toLowerCase() ?? '';

                // Check if 'authors' is a List or a String
                final authorsLower = (book['authors'] is List<dynamic>)
                    ? (book['authors'] as List<dynamic>)
                        .map((a) => a.toString().toLowerCase())
                        .join(' ')
                    : (book['authors'] as String).toLowerCase();

                return titleLower.contains(query.toLowerCase()) ||
                    authorsLower.contains(query.toLowerCase());
              }).toList();
      });
    });
  }

  void _clearSearch() {
    setState(() {
      isSearching = false;
      filteredBooks = [];
    });
  }

  void _startPaginationTimer() {
    _paginationTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      // Ensure currentPage does not exceed total pages
      setState(() {
        currentPage =
            (currentPage + 1) % totalPages(); // Cycle through new arrivals
        currentPageAllBooks = (currentPageAllBooks + 1) %
            totalPagesAllBooks(); // Cycle through all books
      });

      // Animate the page view to the next page automatically
      if (_pageController.hasClients) {
        _pageController.animateToPage(currentPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _debounce?.cancel();
    _pageController.dispose();
    _paginationTimer?.cancel(); // Cancel the timer
    super.dispose();
  }

  List<Map<String, dynamic>> get paginatedNewArrivals {
    final start = currentPage * itemsPerPage;
    final end = start + itemsPerPage;
    return newArrivals.sublist(
        start, end > newArrivals.length ? newArrivals.length : end);
  }

  List<Map<String, dynamic>> get paginatedAllBooks {
    final start = currentPageAllBooks * itemsPerPageAllBooks;
    final end = start + itemsPerPageAllBooks;
    return allBooks.sublist(
        start, end > allBooks.length ? allBooks.length : end);
  }

  int totalPagesAllBooks() {
    return (allBooks.length / itemsPerPageAllBooks).ceil();
  }

  int totalPages() {
    return (newArrivals.length / itemsPerPage).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldLogout = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Logout'),
              content: const Text('Do you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(false), // Dismisses dialog
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(true), // Confirms logout
                  child: const Text('Logout'),
                ),
              ],
            );
          },
        );
        return shouldLogout ?? false; // Proceed only if logout is confirmed
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        color: lightGrey,
        child: SafeArea(
          child: Column(
            children: [
              // Search Bar
              Container(
                alignment: Alignment.center,
                height: 60,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        focusNode: _searchFocusNode,
                        decoration: const InputDecoration(
                          suffixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                          filled: true,
                          fillColor: whiteColor,
                          hintText: searchanything,
                          hintStyle: TextStyle(color: textfieldGrey),
                        ),
                        onChanged: _searchBooks,
                      ),
                    ),
                    if (isSearching)
                      IconButton(
                        icon: const Icon(Icons.cancel),
                        onPressed: _clearSearch,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Show loading indicator while fetching books
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (filteredBooks.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = filteredBooks[index];
                      return _buildBookListItem(book);
                    },
                  ),
                )
              else if (_searchFocusNode.hasFocus)
                const Expanded(
                  child: Center(
                    child: Text("No results found",
                        style: TextStyle(color: textfieldGrey)),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // First Slider
                        VxSwiper.builder(
                          aspectRatio: 16 / 9,
                          autoPlay: true,
                          height: 130,
                          enlargeCenterPage: true,
                          itemCount: sliderlist.length,
                          itemBuilder: (context, index) {
                            return Image.asset(
                              sliderlist[index],
                              fit: BoxFit.fill,
                            ).box.rounded.clip(Clip.antiAlias).make();
                          },
                        ),

                        const SizedBox(height: 10),

                        // New Arrivals Section
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title Row with View All Button
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'New Arrivals',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const ViewAllNewArrivals()),
                                      );
                                    },
                                    child: const Text("View All"),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              isLoadingNewArrivals
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : newArrivals.isEmpty
                                      ? const Text('No new arrivals available',
                                          style:
                                              TextStyle(color: textfieldGrey))
                                      : SizedBox(
                                          height: 430,
                                          child: PageView.builder(
                                            controller: _pageController,
                                            physics:
                                                const BouncingScrollPhysics(),
                                            itemCount: totalPages(),
                                            onPageChanged: (index) {
                                              setState(() {
                                                currentPage = index;
                                              });
                                            },
                                            itemBuilder: (context, pageIndex) {
                                              final paginatedBooks =
                                                  paginatedNewArrivals;
                                              return Row(
                                                children: List.generate(
                                                    paginatedBooks.length,
                                                    (index) {
                                                  final book =
                                                      paginatedBooks[index];
                                                  return Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.4,
                                                    margin: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10),
                                                    child: _buildNewArrivalItem(
                                                        book),
                                                  );
                                                }),
                                              );
                                            },
                                          ),
                                        ),
                            ],
                          ),
                        ),

                        // All Books Section (similar design to New Arrivals)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title Row with View All Button
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'All Books',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => ViewAllBooks(
                                                allBooks: allBooks)),
                                      );
                                    },
                                    child: const Text("View All"),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              isLoadingAllBooks
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : allBooks.isEmpty
                                      ? const Text('No books available',
                                          style:
                                              TextStyle(color: textfieldGrey))
                                      : SizedBox(
                                          height: 425,
                                          child: PageView.builder(
                                            controller: _pageController,
                                            physics:
                                                const BouncingScrollPhysics(),
                                            itemCount: totalPagesAllBooks(),
                                            onPageChanged: (index) {
                                              setState(() {
                                                currentPageAllBooks = index;
                                              });
                                            },
                                            itemBuilder: (context, pageIndex) {
                                              final paginatedBooks =
                                                  paginatedAllBooks;
                                              return Row(
                                                children: List.generate(
                                                    paginatedBooks.length,
                                                    (index) {
                                                  final book =
                                                      paginatedBooks[index];
                                                  return Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.4,
                                                    margin: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10),
                                                    child: _buildNewArrivalItem(
                                                        book), // Same widget for both
                                                  );
                                                }),
                                              );
                                            },
                                          ),
                                        ),
                            ],
                          ),
                        ),
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

  Widget _buildNewArrivalItem(Map<String, dynamic> book) {
    return Card(
      elevation: 4,
      child: Column(
        children: [
          Image.network(book['thumbnail'] ?? '', fit: BoxFit.cover),
          const SizedBox(height: 8),
          Text(
            book['title'] ?? 'No Title',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text("PKR. ${book['price']?.toString() ?? 'N/A'}"),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemDetails(
                    title: book['title'],
                    imageUrl: book['thumbnail'],
                    description: book['description'],
                    price: book['price'].toString(),
                    isbn: book['isbn'],
                    authors:
                        (book['authors'] as List<dynamic>?)?.join(', ') ?? '',
                  ),
                ),
              );
            },
            child: const Text("View Details"),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

Widget _buildBookListItem(Map<String, dynamic> book) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    child: ListTile(
      contentPadding: const EdgeInsets.all(8),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetails(
              title: book['title'],
              imageUrl: book['thumbnail'],
              description: book['description'],
              price: book['price'].toString(),
              isbn: book['isbn'],
              authors: (book['authors'] as List<dynamic>?)?.join(', ') ?? '',
            ),
          ),
        );
      },
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          book['thumbnail'] ?? '',
          width: 50,
          height: 75,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.image_not_supported,
            size: 50,
            color: Colors.grey,
          ),
        ),
      ),
      title: Text(
        book['title'] ?? 'No Title',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "PKR. ${book['price']?.toString() ?? 'N/A'}",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.blueAccent,
              ),
            ),
            Text(
              (book['authors'] is List
                      ? (book['authors'] as List<dynamic>).join(', ')
                      : book['authors'] ?? 'No Author')
                  .toString(),
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

}
