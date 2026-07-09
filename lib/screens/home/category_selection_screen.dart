import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vocabulary_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import 'flashcard_screen.dart';

class CategorySelectionScreen extends StatefulWidget {
  final String selectedLanguage;
  final String languageFlag;

  const CategorySelectionScreen({
    super.key,
    required this.selectedLanguage,
    required this.languageFlag,
  });

  @override
  State<CategorySelectionScreen> createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _selectedCategory;
  String _searchQuery = '';
  String _selectedGroup = 'All';
  List<CategoryModel> _filteredCategories = [];
  List<String> _groups = [];
  int _lastIndex = 0;
  bool _isLoadingIndex = false;
  
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _filteredCategories = List.from(CategoryModel.allCategories);
    _groups = ['All', ...CategoryModel.allGroups];
    
    _scrollController.addListener(() {
      setState(() {
        _showScrollToTop = _scrollController.offset > 200;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ✅ Load the last index for a category
  Future<int> _getLastIndex(String categoryId) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.user;
      
      if (user == null) return 0;

      final lastIndex = await _firestoreService.getLastWordIndex(
        userId: user.uid,
        language: widget.selectedLanguage,
        category: categoryId,
      );
      
      return lastIndex ?? 0;
    } catch (e) {
      print('Error loading last index: $e');
      return 0;
    }
  }

  // ✅ Navigate to flashcards with the saved index
  void _navigateToFlashcards(String categoryId) async {
    // Show loading indicator
    setState(() {
      _isLoadingIndex = true;
    });

    try {
      final lastIndex = await _getLastIndex(categoryId);
      
      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FlashcardsScreen(
            language: widget.selectedLanguage,
            category: categoryId,
            startIndex: lastIndex,  // ✅ Pass the saved index
          ),
        ),
      );
    } catch (e) {
      print('Error navigating: $e');
      // Fallback - start from beginning
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FlashcardsScreen(
            language: widget.selectedLanguage,
            category: categoryId,
            startIndex: 0,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingIndex = false;
        });
      }
    }
  }

  void _filterCategories(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _filterByGroup(String group) {
    setState(() {
      _selectedGroup = group;
      _applyFilters();
    });
  }

  void _applyFilters() {
    var filtered = CategoryModel.allCategories;
    
    if (_selectedGroup != 'All') {
      filtered = filtered.where((c) => c.group == _selectedGroup).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((c) =>
        c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        c.id.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    _filteredCategories = filtered;
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0E27),
              Color(0xFF0D47A1),
              Color(0xFF1A237E),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Back Button
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.languageFlag} ${widget.selectedLanguage.toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_filteredCategories.length} categories',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose a category to study',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade700),
                      ),
                      child: TextField(
                        onChanged: _filterCategories,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '🔍 Search categories...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Group Filter
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _groups.length,
                        itemBuilder: (context, index) {
                          final group = _groups[index];
                          final isSelected = _selectedGroup == group;
                          return GestureDetector(
                            onTap: () => _filterByGroup(group),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF42A5F5).withOpacity(0.2)
                                    : Colors.grey.shade800.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF42A5F5)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                group,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey.shade400,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category Grid
                    Expanded(
                      child: _filteredCategories.isEmpty
                          ? Center(
                              child: Text(
                                'No categories found',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            )
                          : GridView.builder(
                              controller: _scrollController,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.9,
                              ),
                              itemCount: _filteredCategories.length,
                              itemBuilder: (context, index) {
                                final category = _filteredCategories[index];
                                final isSelected = _selectedCategory == category.id;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = category.id;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? LinearGradient(
                                              colors: [
                                                category.color.withOpacity(0.4),
                                                category.color.withOpacity(0.1),
                                              ],
                                            )
                                          : null,
                                      color: isSelected
                                          ? category.color.withOpacity(0.15)
                                          : Colors.grey.shade800.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? category.color
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          category.icon,
                                          style: const TextStyle(fontSize: 32),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          category.name,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.grey.shade300,
                                            fontSize: 13,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (isSelected)
                                          Container(
                                            margin: const EdgeInsets.only(top: 4),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: category.color,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'Selected',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    // Continue Button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _selectedCategory != null
                              ? () => _navigateToFlashcards(_selectedCategory!)  // ✅ Use the new method
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF42A5F5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            disabledBackgroundColor: Colors.grey.shade700,
                          ),
                          child: _isLoadingIndex
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scroll to Top Button
              if (_showScrollToTop)
                Positioned(
                  bottom: 100,
                  right: 20,
                  child: GestureDetector(
                    onTap: _scrollToTop,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF42A5F5), Color(0xFF1A237E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF42A5F5).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_upward,
                        color: Colors.white,
                        size: 28,
                      ),
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