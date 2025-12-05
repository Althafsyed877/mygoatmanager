import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> showCenteredSuccess(BuildContext context, String message) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF4CAF50),
                radius: 28,
                child: Icon(Icons.check, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 12),
              Text(message, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    ),
  );

  await Future.delayed(const Duration(milliseconds: 1200));
  if (Navigator.of(context).canPop()) Navigator.of(context).pop();
}

class FarmSetupPage extends StatelessWidget {
  const FarmSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calculate responsive sizes
    final cardSize = screenWidth * 0.4;
    final paddingValue = screenWidth * 0.04;
    final spacingValue = screenWidth * 0.04;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Green Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Back arrow and title
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: paddingValue, vertical: 12.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Farm Setup',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Orange line
                  Container(
                    height: 3,
                    width: double.infinity,
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
          ),
          
          // White Body with Menu Cards
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(paddingValue),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: spacingValue,
                mainAxisSpacing: spacingValue,
                childAspectRatio: 1.0,
                children: [
                  _buildMenuCard(
                    'Income\nCategories',
                    'assets/images/income.png', // PNG icon
                    cardSize,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (ctx) => const IncomeCategoriesPage()),
                      );
                    },
                  ),
                  _buildMenuCard(
                    'Expense\nCategories',
                    'assets/images/expense.png', // PNG icon
                    cardSize,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (ctx) => const ExpenseCategoriesPage()),
                      );
                    },
                  ),
                  _buildMenuCard(
                    'Goat Breeds',
                    'assets/images/goat_breed.png', // PNG icon
                    cardSize,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (ctx) => const GoatBreedsPage()),
                      );
                    },
                  ),
                  _buildMenuCard(
                    'Goat Groups',
                    'assets/images/goat_group.png', // PNG icon
                    cardSize,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (ctx) => const GoatGroupsPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(String title, String iconPath, double cardSize, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: cardSize,
          height: cardSize,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // PNG Icon
              Container(
                width: cardSize * 0.4,
                height: cardSize * 0.4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Image.asset(
                  iconPath,
                  width: cardSize * 0.3,
                  height: cardSize * 0.3,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: cardSize * 0.05),
              // Title
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: cardSize * 0.08, // Responsive font size
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual setup pages (Income/Expense/Goat Breeds/Groups)
// Search activates inline in the AppBar when the icon is tapped.
// ---------------------------------------------------------------------------

class IncomeCategoriesPage extends StatefulWidget {
  const IncomeCategoriesPage({super.key});

  @override
  State<IncomeCategoriesPage> createState() => _IncomeCategoriesPageState();
}

class _IncomeCategoriesPageState extends State<IncomeCategoriesPage> {
  List<String> _categories = [];
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('incomeCategories') ?? [];
    setState(() => _categories = data);
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('incomeCategories', _categories);
  }

  void _showAddDialog() {
    _categoryController.clear();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('New Category', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    hintText: 'Enter name ...',
                    border: UnderlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFA726)),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (_categoryController.text.isNotEmpty) {
                          setState(() => _categories.add(_categoryController.text));
                          _saveCategories();
                          Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
                      child: const Text('Add', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search categories...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : const Text('Income Categories', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
            icon: const Icon(Icons.search, color: Colors.white),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(height: 4, color: const Color(0xFFFFB300)),
        ),
      ),
      body: _searchQuery.isEmpty && _categories.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'No income categories have been added as of yet!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFFFB300), fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              )
            : Builder(
                builder: (ctx) {
                  final filtered = _categories
                      .where((cat) => cat.toLowerCase().contains(_searchQuery))
                      .toList();
                  
                  if (filtered.isEmpty && _searchQuery.isNotEmpty) {
                    return Center(
                      child: Text(
                        'No results found',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final cat = filtered[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          title: Text(cat, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          trailing: PopupMenuButton<String>(
                            onSelected: (val) {
                              final originalIndex = _categories.indexOf(cat);
                              if (val == 'delete') {
                                setState(() => _categories.removeAt(originalIndex));
                                _saveCategories();
                              } else if (val == 'edit') {
                                _categoryController.text = cat;
                                showDialog(
                                  context: context,
                                  builder: (ctx) => Dialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    backgroundColor: Colors.white,
                                    child: Container(
                                      width: MediaQuery.of(context).size.width * 0.8,
                                      child: Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Edit Category', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 20),
                                            TextField(
                                              controller: _categoryController,
                                              decoration: const InputDecoration(
                                                hintText: 'Enter name ...',
                                                border: UnderlineInputBorder(),
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                ElevatedButton(
                                                  onPressed: () => Navigator.pop(ctx),
                                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFA726)),
                                                  child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                                                ),
                                                const SizedBox(width: 12),
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    if (_categoryController.text.isNotEmpty) {
                                                      setState(() => _categories[originalIndex] = _categoryController.text);
                                                      await _saveCategories();
                                                      Navigator.pop(ctx);
                                                      showCenteredSuccess(context, 'Record successfully updated');
                                                    }
                                                  },
                                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
                                                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                            color: Colors.white,
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit/View Record')),
                              PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        label: const Text('Add', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color(0xFFFFA726),
      ),
    );
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

class ExpenseCategoriesPage extends StatefulWidget {
  const ExpenseCategoriesPage({super.key});

  @override
  State<ExpenseCategoriesPage> createState() => _ExpenseCategoriesPageState();
}

class _ExpenseCategoriesPageState extends State<ExpenseCategoriesPage> {
  List<String> _categories = [];
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('expenseCategories') ?? [];
    setState(() => _categories = data);
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('expenseCategories', _categories);
  }

  void _showAddDialog() {
    _categoryController.clear();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('New Category', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    hintText: 'Enter name ...',
                    border: UnderlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFA726)),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (_categoryController.text.isNotEmpty) {
                          setState(() => _categories.add(_categoryController.text));
                          _saveCategories();
                          Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
                      child: const Text('Add', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search categories...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : const Text('Expense Categories', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
            icon: const Icon(Icons.search, color: Colors.white),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(height: 4, color: const Color(0xFFFFB300)),
        ),
      ),
      body: _searchQuery.isEmpty && _categories.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'No expense categories have been added as of yet!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFFFB300), fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              )
            : Builder(
                builder: (ctx) {
                  final filtered = _categories
                      .where((cat) => cat.toLowerCase().contains(_searchQuery))
                      .toList();
                  
                  if (filtered.isEmpty && _searchQuery.isNotEmpty) {
                    return Center(
                      child: Text(
                        'No results found',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final cat = filtered[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          title: Text(cat, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          trailing: PopupMenuButton<String>(
                            onSelected: (val) {
                              final originalIndex = _categories.indexOf(cat);
                              if (val == 'delete') {
                                setState(() => _categories.removeAt(originalIndex));
                                _saveCategories();
                              } else if (val == 'edit') {
                                _categoryController.text = cat;
                                showDialog(
                                  context: context,
                                  builder: (ctx) => Dialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    backgroundColor: Colors.white,
                                    child: Container(
                                      width: MediaQuery.of(context).size.width * 0.8,
                                      child: Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Edit Category', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 20),
                                            TextField(
                                              controller: _categoryController,
                                              decoration: const InputDecoration(
                                                hintText: 'Enter name ...',
                                                border: UnderlineInputBorder(),
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                ElevatedButton(
                                                  onPressed: () => Navigator.pop(ctx),
                                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFA726)),
                                                  child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                                                ),
                                                const SizedBox(width: 12),
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    if (_categoryController.text.isNotEmpty) {
                                                      setState(() => _categories[originalIndex] = _categoryController.text);
                                                      await _saveCategories();
                                                      Navigator.pop(ctx);
                                                      showCenteredSuccess(context, 'Record successfully updated');
                                                    }
                                                  },
                                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
                                                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                            color: Colors.white,
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit/View Record')),
                              PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        label: const Text('Add', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color(0xFFFFA726),
      ),
    );
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

class GoatBreedsPage extends StatefulWidget {
  const GoatBreedsPage({super.key});

  @override
  State<GoatBreedsPage> createState() => _GoatBreedsPageState();
}

class _GoatBreedsPageState extends State<GoatBreedsPage> {
  static const List<String> _defaultBreeds = ['Alpine', 'Boer', 'Kiko', 'Nubian'];
  List<String> _breeds = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadBreeds();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  Future<void> _loadBreeds() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('goatBreeds');
    setState(() => _breeds = (data == null || data.isEmpty) ? List.from(_defaultBreeds) : data);
  }

  Future<void> _saveBreeds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('goatBreeds', _breeds);
  }

  void _showAddDialog() {
    _breedController.clear();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('New Breed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: _breedController,
                  decoration: const InputDecoration(
                    hintText: 'Enter breed name...',
                    border: UnderlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFA726)),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (_breedController.text.isNotEmpty) {
                          setState(() => _breeds.add(_breedController.text));
                          _saveBreeds();
                          Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
                      child: const Text('Add', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search breeds...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : const Text('Goat Breeds', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
            icon: const Icon(Icons.search, color: Colors.white),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(height: 4, color: const Color(0xFFFFB300)),
        ),
      ),
      body: _breeds.isEmpty && _searchQuery.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'No goat breeds have been added yet!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFFFB300), fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            )
          : Builder(
              builder: (ctx) {
                final filtered = _breeds.where((b) => b.toLowerCase().contains(_searchQuery)).toList();

                if (filtered.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Text(
                      'No results found',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final b = filtered[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        title: Text(b, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        subtitle: const Text('(0) Goats', style: TextStyle(color: Colors.grey)),
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) {
                            final originalIndex = _breeds.indexOf(b);
                            if (val == 'delete') {
                              setState(() => _breeds.removeAt(originalIndex));
                              _saveBreeds();
                            } else if (val == 'edit') {
                              _breedController.text = b;
                              showDialog(
                                context: context,
                                builder: (ctx) => Dialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  backgroundColor: Colors.white,
                                  child: Container(
                                    width: MediaQuery.of(context).size.width * 0.8,
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Edit Breed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 20),
                                          TextField(
                                            controller: _breedController,
                                            decoration: const InputDecoration(
                                              hintText: 'Enter breed name...',
                                              border: UnderlineInputBorder(),
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(ctx),
                                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFA726)),
                                                child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                                              ),
                                              const SizedBox(width: 12),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  if (_breedController.text.isNotEmpty) {
                                                    setState(() => _breeds[originalIndex] = _breedController.text);
                                                    await _saveBreeds();
                                                    Navigator.pop(ctx);
                                                    showCenteredSuccess(context, 'Record successfully updated');
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
                                                child: const Text('Save', style: TextStyle(color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                          color: Colors.white,
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit/View Record')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        label: const Text('Add', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color(0xFFFFA726),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _breedController.dispose();
    super.dispose();
  }
}

class GoatGroupsPage extends StatefulWidget {
  const GoatGroupsPage({super.key});

  @override
  State<GoatGroupsPage> createState() => _GoatGroupsPageState();
}

class _GoatGroupsPageState extends State<GoatGroupsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _groups = [];
  final TextEditingController _groupController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('goatGroups') ?? [];
    setState(() => _groups = data);
  }

  Future<void> _saveGroups() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('goatGroups', _groups);
  }

  void _showAddGroupDialog() {
    _groupController.clear();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('New Group', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: _groupController,
                  decoration: const InputDecoration(
                    hintText: 'Enter group name...',
                    border: UnderlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFA726)),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (_groupController.text.isNotEmpty) {
                          setState(() => _groups.add(_groupController.text));
                          _saveGroups();
                          Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
                      child: const Text('Add', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search groups...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : const Text('Goat Groups', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
            icon: const Icon(Icons.search, color: Colors.white),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(height: 4, color: const Color(0xFFFFB300)),
        ),
      ),
      body: _groups.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'No goat groups currently registered as of yet!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFFFB300), fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            )
          : Builder(
              builder: (ctx) {
                final filtered = _groups
                    .where((g) => g.toLowerCase().contains(_searchQuery))
                    .toList();

                if (filtered.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Text(
                      'No results found',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final g = filtered[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        title: Text(g, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) {
                            final originalIndex = _groups.indexOf(g);
                            if (val == 'delete') {
                              setState(() => _groups.removeAt(originalIndex));
                              _saveGroups();
                            } else if (val == 'edit') {
                              _groupController.text = g;
                              showDialog(
                                context: context,
                                builder: (ctx) => Dialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  backgroundColor: Colors.white,
                                  child: Container(
                                    width: MediaQuery.of(context).size.width * 0.8,
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Edit Group', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 20),
                                          TextField(
                                            controller: _groupController,
                                            decoration: const InputDecoration(
                                              hintText: 'Enter group name...',
                                              border: UnderlineInputBorder(),
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(ctx),
                                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFA726)),
                                                child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                                              ),
                                              const SizedBox(width: 12),
                                              ElevatedButton(
                                                  onPressed: () async {
                                                    if (_groupController.text.isNotEmpty) {
                                                      setState(() => _groups[originalIndex] = _groupController.text);
                                                      await _saveGroups();
                                                      Navigator.pop(ctx);
                                                      showCenteredSuccess(context, 'Record successfully updated');
                                                    }
                                                  },
                                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
                                                child: const Text('Save', style: TextStyle(color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                          color: Colors.white,
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit/View Record')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGroupDialog,
        label: const Text('Add', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color(0xFFFFA726),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _groupController.dispose();
    super.dispose();
  }
}