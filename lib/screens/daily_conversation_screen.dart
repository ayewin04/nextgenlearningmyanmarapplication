import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/audio_service.dart';
import '../models/daily_conversation_model.dart';

class DailyConversationScreen extends StatefulWidget {
  final String language;
  final String exam;
  final String level;

  const DailyConversationScreen({
    super.key,
    required this.language,
    required this.exam,
    required this.level,
  });

  @override
  State<DailyConversationScreen> createState() =>
      _DailyConversationScreenState();
}

class _DailyConversationScreenState extends State<DailyConversationScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  List<ConversationCategory> _categories = [];
  List<ConversationSubCategory> _subCategories = [];
  List<DailyConversationModel> _conversations = [];
  List<DailyConversationModel> _searchResults = [];
  
  bool _isLoading = true;
  bool _isLoadingConversations = false;
  bool _isSearching = false;
  String _searchQuery = '';
  String? _selectedCategoryId;
  String? _selectedSubCategoryId;
  String? _error;

  // Pagination
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 20;
  bool _hasMoreData = true;
  int _currentPage = 0;
  int _totalConversations = 0;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔍 Loading categories for:');
      print('   Language: ${widget.language}');
      print('   Exam: ${widget.exam.toLowerCase()}');

      // Daily conversations are for ALL levels - no level filter
      final snapshot = await FirebaseFirestore.instance
          .collection('daily_conversation_categories')
          .where('language', isEqualTo: widget.language.toLowerCase())
          .where('exam', isEqualTo: widget.exam.toLowerCase())
          .get();

      print('📊 Found ${snapshot.docs.length} categories');

      final categories = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ConversationCategory.fromMap(doc.id, data);
      }).toList();

      setState(() {
        _categories = categories;
        _isLoading = false;
      });

      if (_categories.isNotEmpty) {
        print('✅ First category: ${_categories[0].name}');
        _selectCategory(_categories[0].id);
      } else {
        print('⚠️ No categories found for this language/exam');
        setState(() {
          _error = 'No categories found for ${widget.language}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading categories: $e');
      setState(() {
        _error = 'Failed to load categories: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectCategory(String categoryId) async {
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedSubCategoryId = null;
      _subCategories = [];
      _conversations = [];
      _isLoadingConversations = true;
      _currentPage = 0;
      _lastDocument = null;
      _hasMoreData = true;
    });

    try {
      // No level filter for subcategories
      final subSnapshot = await FirebaseFirestore.instance
          .collection('daily_conversation_subcategories')
          .where('language', isEqualTo: widget.language.toLowerCase())
          .where('exam', isEqualTo: widget.exam.toLowerCase())
          .where('categoryId', isEqualTo: categoryId)
          .get();

      final subCategories = subSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ConversationSubCategory.fromMap(doc.id, data);
      }).toList();

      setState(() {
        _subCategories = subCategories;
      });

      if (_subCategories.isNotEmpty) {
        await _selectSubCategory(_subCategories[0].id);
      } else {
        await _loadConversations(categoryId: categoryId);
      }
    } catch (e) {
      print('❌ Error loading subcategories: $e');
      setState(() {
        _isLoadingConversations = false;
        _error = 'Failed to load subcategories: $e';
      });
    }
  }

  Future<void> _selectSubCategory(String subCategoryId) async {
    setState(() {
      _selectedSubCategoryId = subCategoryId;
      _conversations = [];
      _isLoadingConversations = true;
      _currentPage = 0;
      _lastDocument = null;
      _hasMoreData = true;
    });

    await _loadConversations(subCategoryId: subCategoryId);
  }

  Future<void> _loadConversations({
    String? categoryId,
    String? subCategoryId,
    bool loadMore = false,
  }) async {
    if (loadMore && !_hasMoreData) return;

    setState(() {
      if (!loadMore) {
        _isLoadingConversations = true;
      }
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('daily_conversations')
          .where('language', isEqualTo: widget.language.toLowerCase())
          .where('exam', isEqualTo: widget.exam.toLowerCase());
      // No level filter for conversations

      if (categoryId != null) {
        query = query.where('category', isEqualTo: categoryId);
      }

      if (subCategoryId != null) {
        query = query.where('subCategory', isEqualTo: subCategoryId);
      }

      if (loadMore && _lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query
          .orderBy('createdAt', descending: true)
          .limit(_pageSize)
          .get();

      final conversations = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return DailyConversationModel.fromMap(doc.id, data);
      }).toList();

      final hasMore = snapshot.docs.length == _pageSize;
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      setState(() {
        if (loadMore) {
          _conversations.addAll(conversations);
        } else {
          _conversations = conversations;
        }
        _hasMoreData = hasMore;
        _currentPage++;
        _isLoadingConversations = false;
        _totalConversations = conversations.length;
      });
    } catch (e) {
      print('❌ Error loading conversations: $e');
      setState(() {
        _error = 'Failed to load conversations: $e';
        _isLoadingConversations = false;
      });
    }
  }

  Future<void> _searchConversations(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchQuery = '';
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query;
      _isLoading = true;
    });

    try {
      final results = await _firestoreService.searchDailyConversations(
        exam: widget.exam.toLowerCase(),
        query: query.toLowerCase(),
      );

      final filteredResults = results
          .where((conv) => conv.language == widget.language.toLowerCase())
          .toList();

      setState(() {
        _searchResults = filteredResults;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Search error: $e');
      setState(() {
        _error = 'Search failed: $e';
        _isLoading = false;
      });
    }
  }

  String _getTextToSpeak(String text) {
    if (widget.language.toLowerCase() == 'japanese') {
      return text;
    }
    return text;
  }

  void _playAudio(String text, {String? romanization}) async {
    final textToSpeak = widget.language.toLowerCase() == 'japanese' && romanization != null
        ? romanization
        : text;

    if (textToSpeak.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔊 No audio available'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    try {
      await AudioService.speak(textToSpeak, language: widget.language);
    } catch (e) {
      print('❌ Audio error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔊 Audio not available. Please try again.'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _isSearching && _searchQuery.isNotEmpty
        ? _searchResults
        : _conversations;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          '💬 Daily Conversations',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
              ),
            ),
            child: Text(
              'All Levels',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _searchConversations,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '🔍 Search conversations...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _searchConversations('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade800.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
      ),
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF42A5F5),
                ),
              )
            : _error != null
                ? _buildErrorWidget()
                : Column(
                    children: [
                      if (!_isSearching || _searchQuery.isEmpty)
                        _buildCategorySelector(),
                      if (!_isSearching || _searchQuery.isEmpty)
                        _buildSubCategorySelector(),
                      Expanded(
                        child: _isLoadingConversations
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF42A5F5),
                                ),
                              )
                            : displayList.isEmpty
                                ? _buildEmptyWidget()
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    controller: ScrollController(),
                                    itemCount: displayList.length + 1,
                                    itemBuilder: (context, index) {
                                      if (index == displayList.length) {
                                        if (_hasMoreData && !_isLoadingConversations) {
                                          WidgetsBinding.instance.addPostFrameCallback((_) {
                                            _loadConversations(
                                              subCategoryId: _selectedSubCategoryId,
                                              loadMore: true,
                                            );
                                          });
                                        }
                                        return _hasMoreData
                                            ? const Padding(
                                                padding: EdgeInsets.all(16),
                                                child: Center(
                                                  child: CircularProgressIndicator(
                                                    color: Color(0xFF42A5F5),
                                                  ),
                                                ),
                                              )
                                            : const SizedBox.shrink();
                                      }
                                      final conversation = displayList[index];
                                      return _buildConversationCard(conversation);
                                    },
                                  ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    if (_categories.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;

    return Container(
      height: isSmallScreen ? 70 : 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategoryId == category.id;

          return GestureDetector(
            onTap: () => _selectCategory(category.id),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF42A5F5),
                          Color(0xFF1A237E),
                        ],
                      )
                    : null,
                color: isSelected
                    ? null
                    : Colors.grey.shade800.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF42A5F5)
                      : Colors.grey.shade700.withOpacity(0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    category.icon,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 20,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade300,
                      fontSize: isSmallScreen ? 11 : 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubCategorySelector() {
    if (_subCategories.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;

    return Container(
      height: isSmallScreen ? 60 : 70,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _subCategories.length,
        itemBuilder: (context, index) {
          final subCategory = _subCategories[index];
          final isSelected = _selectedSubCategoryId == subCategory.id;

          return GestureDetector(
            onTap: () => _selectSubCategory(subCategory.id),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF42A5F5).withOpacity(0.2)
                    : Colors.grey.shade800.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF42A5F5)
                      : Colors.grey.shade700.withOpacity(0.2),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    subCategory.icon,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    subCategory.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade400,
                      fontSize: isSmallScreen ? 10 : 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversationCard(DailyConversationModel conversation) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade700.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (conversation.titleRomanization.isNotEmpty)
                      Text(
                        conversation.titleRomanization,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: isSmallScreen ? 11 : 13,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (conversation.burmeseTitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '🇲🇲 ${conversation.burmeseTitle}',
                          style: GoogleFonts.notoSansMyanmar(
                            color: Colors.white70,
                            fontSize: isSmallScreen ? 13 : 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF42A5F5).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${conversation.conversation.length} lines',
                  style: TextStyle(
                    color: const Color(0xFF42A5F5),
                    fontSize: isSmallScreen ? 8 : 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (conversation.description.isNotEmpty) ...[
            Text(
              conversation.description,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: isSmallScreen ? 12 : 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (conversation.burmeseDescription.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '🇲🇲 ${conversation.burmeseDescription}',
                  style: GoogleFonts.notoSansMyanmar(
                    color: Colors.grey.shade500,
                    fontSize: isSmallScreen ? 11 : 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 12),
          ],

          ...conversation.conversation.map((entry) {
            final isSpeakerA = entry.speaker.toLowerCase().contains('a') ||
                entry.speaker.toLowerCase().contains('person');
            final speakerColor = isSpeakerA
                ? Colors.blue.shade300
                : Colors.green.shade300;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade700.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: isSmallScreen ? 20 : 24,
                            height: isSmallScreen ? 20 : 24,
                            decoration: BoxDecoration(
                              color: speakerColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                entry.speaker,
                                style: TextStyle(
                                  color: speakerColor,
                                  fontSize: isSmallScreen ? 8 : 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.text,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 14 : 15,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (entry.romanization.isNotEmpty)
                                  Text(
                                    entry.romanization,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: isSmallScreen ? 10 : 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (entry.burmese.isNotEmpty)
                                  Text(
                                    '🇲🇲 ${entry.burmese}',
                                    style: GoogleFonts.notoSansMyanmar(
                                      color: Colors.grey.shade400,
                                      fontSize: isSmallScreen ? 12 : 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => _playAudio(
                          entry.text,
                          romanization: entry.romanization,
                        ),
                        icon: Icon(
                          Icons.volume_up,
                          color: const Color(0xFF42A5F5),
                          size: isSmallScreen ? 18 : 20,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 30,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.volume_up,
                color: Colors.grey.shade600,
                size: isSmallScreen ? 12 : 14,
              ),
              const SizedBox(width: 4),
              Text(
                'Tap speaker to hear pronunciation',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: isSmallScreen ? 9 : 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCategories,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF42A5F5),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isSearching && _searchQuery.isNotEmpty
                ? Icons.search_off
                : Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 16),
          Text(
            _isSearching && _searchQuery.isNotEmpty
                ? 'No conversations found for "$_searchQuery"'
                : 'No conversations available',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _isSearching && _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Select a category to start learning',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}