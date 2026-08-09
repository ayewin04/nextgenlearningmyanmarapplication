import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../services/audio_service.dart';

class GrammarScreen extends StatefulWidget {
  final String language;
  final String exam;
  final String level;

  const GrammarScreen({
    super.key,
    required this.language,
    required this.exam,
    required this.level,
  });

  @override
  State<GrammarScreen> createState() => _GrammarScreenState();
}

class _GrammarScreenState extends State<GrammarScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _grammar = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = true;
  bool _isLoadingPage = false;
  bool _hasMoreData = true;
  String? _error;
  String _searchQuery = '';
  bool _isSearching = false;
  
  // Pagination variables
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 10;
  
  // Pagination navigation
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalItems = 0;
  late ScrollController _scrollController;
  
  // Cache for page data
  final Map<int, List<Map<String, dynamic>>> _pageCache = {};
  final Map<int, DocumentSnapshot> _pageSnapshots = {};
  bool _isLoadingTotalCount = false;
  int _estimatedTotal = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadGrammar(refresh: true);
    _estimateTotalCount();
    
    // Add listener to search controller
    _searchController.addListener(() {
      if (_searchController.text.isEmpty && _searchQuery.isNotEmpty) {
        _clearSearch();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _estimateTotalCount() async {
    if (_isLoadingTotalCount) return;
    
    setState(() {
      _isLoadingTotalCount = true;
    });
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('grammar')
          .where('exam', isEqualTo: widget.exam.toLowerCase())
          .where('level', isEqualTo: widget.level)
          .count()
          .get();
      
      _estimatedTotal = snapshot.count ?? 0;
      _totalPages = _estimatedTotal > 0 ? (_estimatedTotal / _pageSize).ceil() : 0;
      
      print('📊 Estimated total grammar: $_estimatedTotal lessons, $_totalPages pages');
    } catch (e) {
      print('❌ Error estimating total: $e');
      _estimatedTotal = 50;
      _totalPages = 5;
    }
    
    setState(() {
      _isLoadingTotalCount = false;
    });
  }

  // ✅ Clear search
  void _clearSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchResults = [];
      _searchController.clear();
      _isLoading = false;
    });
    // Reload the current page
    _loadGrammar(refresh: true);
  }

  // ✅ Search across all data
  Future<void> _searchGrammar(String query) async {
    if (query.isEmpty) {
      _clearSearch();
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
      _searchQuery = query;
    });

    try {
      final results = await _firestoreService.searchGrammar(
        exam: widget.exam.toLowerCase(),
        level: widget.level,
        query: query.toLowerCase(),
      );
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
        _isSearching = true;
      });
      
      print('🔍 Found ${results.length} results for "$query"');
    } catch (e) {
      print('❌ Search error: $e');
      setState(() {
        _error = 'Failed to search: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadGrammar({bool refresh = false, int? targetPage}) async {
    // If searching, don't load paginated data
    if (_isSearching && _searchQuery.isNotEmpty) {
      return;
    }

    if (refresh || targetPage == null || targetPage == 0) {
      setState(() {
        _isLoading = true;
        _error = null;
        _grammar = [];
        _lastDocument = null;
        _hasMoreData = true;
        _currentPage = 0;
        _pageCache.clear();
        _pageSnapshots.clear();
      });
    }

    if (targetPage != null && targetPage > 0) {
      setState(() {
        _isLoadingPage = true;
      });
    }

    try {
      // Check cache first
      if (targetPage != null && _pageCache.containsKey(targetPage)) {
        print('📌 Loading page $targetPage from cache');
        _grammar = _pageCache[targetPage]!;
        _currentPage = targetPage;
        
        setState(() {
          _isLoading = false;
          _isLoadingPage = false;
        });
        
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        return;
      }

      DocumentSnapshot? startAfter;
      
      // Get startAfter from cache
      if (targetPage != null && targetPage > 0 && _pageSnapshots.containsKey(targetPage - 1)) {
        startAfter = _pageSnapshots[targetPage - 1];
        print('📌 Using cached snapshot for page ${targetPage - 1}');
      }
      
      // If no snapshot, load sequentially
      if (targetPage != null && targetPage > 0 && startAfter == null) {
        print('📌 Loading sequentially to reach page $targetPage');
        _pageCache.clear();
        _pageSnapshots.clear();
        _lastDocument = null;
        
        for (int i = 0; i <= targetPage; i++) {
          final docToUse = i > 0 ? _pageSnapshots[i - 1] : null;
          
          final result = await _firestoreService.getGrammarByLevelWithPagination(
            exam: widget.exam.toLowerCase(),
            level: widget.level,
            limit: _pageSize,
            startAfter: docToUse,
          );
          
          final lastDoc = _firestoreService.getLastGrammarDoc();
          _hasMoreData = result.length == _pageSize;
          
          if (lastDoc != null) {
            _pageSnapshots[i] = lastDoc;
            _lastDocument = lastDoc;
          }
          
          _pageCache[i] = result;
          
          if (i == targetPage) {
            _grammar = result;
            _currentPage = i;
            print('✅ Loaded page $i with ${result.length} items');
          }
          
          if (!_hasMoreData) break;
        }
        
        setState(() {
          _isLoading = false;
          _isLoadingPage = false;
        });
        
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        return;
      }
      
      // Normal load
      final result = await _firestoreService.getGrammarByLevelWithPagination(
        exam: widget.exam.toLowerCase(),
        level: widget.level,
        limit: _pageSize,
        startAfter: refresh ? null : _lastDocument,
      );
      
      final lastDoc = _firestoreService.getLastGrammarDoc();
      _hasMoreData = result.length == _pageSize;
      
      if (lastDoc != null) {
        _lastDocument = lastDoc;
        final pageToStore = targetPage ?? _currentPage;
        _pageSnapshots[pageToStore] = lastDoc;
      }
      
      if (refresh) {
        _grammar = result;
        _currentPage = 0;
        _pageCache[0] = result;
      } else if (targetPage != null && targetPage > 0) {
        _grammar = result;
        _currentPage = targetPage;
        _pageCache[targetPage] = result;
      } else {
        _grammar = result;
        _currentPage++;
        _pageCache[_currentPage] = result;
      }
      
      // Update total pages
      if (_estimatedTotal > 0) {
        _totalPages = (_estimatedTotal / _pageSize).ceil();
      } else {
        _totalItems = _grammar.length + (_hasMoreData ? _pageSize : 0);
        _totalPages = (_totalItems / _pageSize).ceil();
      }
      
      print('✅ Loaded ${_grammar.length} lessons (Page ${_currentPage + 1}/$_totalPages)');
      
      setState(() {
        _isLoading = false;
        _isLoadingPage = false;
      });
      
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      print('❌ Error loading grammar: $e');
      setState(() {
        _error = 'Failed to load grammar: $e';
        _isLoading = false;
        _isLoadingPage = false;
      });
    }
  }

  Future<void> _loadPage(int page) async {
    if (page == _currentPage) return;
    if (page < 0) return;
    
    if (_totalPages > 0 && page >= _totalPages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📖 No more pages available'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    
    print('🔄 Loading page $page');
    await _loadGrammar(refresh: true, targetPage: page);
  }

  Future<void> _goToNextPage() async {
    if (_isSearching && _searchQuery.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔍 Search results are not paginated'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    
    if (_currentPage < _totalPages - 1) {
      await _loadPage(_currentPage + 1);
    } else if (_hasMoreData) {
      await _loadGrammar(refresh: false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📖 You have reached the last page'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _filterGrammar(String query) {
    if (query.isEmpty) {
      _clearSearch();
      return;
    }
    _searchGrammar(query);
  }

  List<Map<String, dynamic>> get _displayList {
    if (_isSearching && _searchQuery.isNotEmpty) {
      return _searchResults;
    }
    return _grammar;
  }

  String _getExamDisplayName() {
    switch (widget.exam.toLowerCase()) {
      case 'ielts': return 'IELTS';
      case 'hsk': return 'HSK';
      case 'jlpt': return 'JLPT';
      case 'topik': return 'TOPIK';
      default: return widget.exam.toUpperCase();
    }
  }

  Widget _buildPaginationControls() {
    // Hide pagination when searching
    if (_isSearching && _searchQuery.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade800.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade700.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '🔍 ${_searchResults.length} results found',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
            TextButton(
              onPressed: _clearSearch,
              child: const Text(
                'Clear',
                style: TextStyle(
                  color: Color(0xFF42A5F5),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final displayList = _displayList;
    final startIndex = _currentPage * _pageSize + 1;
    final endIndex = startIndex + displayList.length - 1;
    final hasItems = displayList.isNotEmpty;
    
    final totalDisplay = _estimatedTotal > 0 ? _estimatedTotal : _totalItems;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmall = screenWidth < 320;
    final isSmall = screenWidth < 380;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: isVerySmall ? 4 : (isSmall ? 8 : 12)),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade700.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          if (isVerySmall)
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  hasItems 
                      ? '📖 $startIndex-$endIndex of $totalDisplay'
                      : '📖 No lessons',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!_isLoadingPage && _totalPages > 0)
                  Text(
                    'Page ${_currentPage + 1}/$_totalPages',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 9,
                    ),
                  ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    hasItems 
                        ? '📖 $startIndex-$endIndex of $totalDisplay'
                        : '📖 No lessons',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: isSmall ? 10 : 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!_isLoadingPage && _totalPages > 0)
                  Text(
                    'Page ${_currentPage + 1}/$_totalPages',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: isSmall ? 10 : 12,
                    ),
                  ),
              ],
            ),
          
          const SizedBox(height: 4),
          
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 2,
            runSpacing: 4,
            children: [
              if (!isVerySmall)
                _buildPageButton(
                  icon: Icons.first_page,
                  onPressed: _currentPage > 0 && !_isLoadingPage
                      ? () => _loadPage(0)
                      : null,
                ),
              
              _buildPageButton(
                icon: Icons.chevron_left,
                onPressed: _currentPage > 0 && !_isLoadingPage
                    ? () => _loadPage(_currentPage - 1)
                    : null,
              ),
              
              if (_totalPages > 1)
                Container(
                  constraints: BoxConstraints(
                    maxWidth: isVerySmall ? 50 : (isSmall ? 60 : 80),
                    minWidth: isVerySmall ? 30 : 40,
                  ),
                  child: DropdownButton<int>(
                    value: _currentPage < _totalPages ? _currentPage : 0,
                    dropdownColor: const Color(0xFF1A237E),
                    underline: Container(
                      height: 1,
                      color: Colors.grey.shade700,
                    ),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isVerySmall ? 8 : (isSmall ? 9 : 10),
                    ),
                    isDense: true,
                    iconSize: 14,
                    items: _getPageItems(),
                    onChanged: _isLoadingPage
                        ? null
                        : (int? newPage) {
                            if (newPage != null && newPage != _currentPage && newPage < _totalPages) {
                              _loadPage(newPage);
                            }
                          },
                  ),
                ),
              
              _buildPageButton(
                icon: Icons.chevron_right,
                onPressed: _hasMoreData && !_isLoadingPage && _currentPage < _totalPages - 1
                    ? () => _loadPage(_currentPage + 1)
                    : null,
              ),
              
              if (!isVerySmall)
                _buildPageButton(
                  icon: Icons.last_page,
                  onPressed: _totalPages > 0 && _currentPage < _totalPages - 1 && !_isLoadingPage
                      ? () => _loadPage(_totalPages - 1)
                      : null,
                ),
            ],
          ),
          
          if (!_isLoadingPage && _totalPages > 1 && !isSmall && !isVerySmall) ...[
            const SizedBox(height: 4),
            SizedBox(
              height: 24,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _totalPages > 10 ? 10 : _totalPages,
                itemBuilder: (context, index) {
                  final pageIndex = index * 5;
                  if (pageIndex >= _totalPages) return const SizedBox.shrink();
                  
                  final pageStart = pageIndex * _pageSize + 1;
                  final pageEnd = (pageIndex + 5) * _pageSize;
                  final isSelected = pageIndex <= _currentPage && _currentPage < pageIndex + 5;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: GestureDetector(
                      onTap: () => _loadPage(pageIndex),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF42A5F5).withOpacity(0.3)
                              : Colors.grey.shade700.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF42A5F5)
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '$pageStart-${pageEnd > totalDisplay ? totalDisplay : pageEnd}',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade400,
                            fontSize: 8,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          
          if (_isLoadingPage)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF42A5F5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: onPressed != null ? Colors.white : Colors.grey.shade600,
        size: 16,
      ),
      padding: const EdgeInsets.all(2),
      constraints: const BoxConstraints(
        minWidth: 24,
        minHeight: 24,
      ),
      splashRadius: 16,
    );
  }

  List<DropdownMenuItem<int>> _getPageItems() {
    final items = <DropdownMenuItem<int>>[];
    
    if (_totalPages <= 0) {
      return items;
    }
    
    final seenValues = <int>{};
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmall = screenWidth < 320;
    final isSmall = screenWidth < 380;
    
    int step = 1;
    if (isVerySmall) {
      step = _totalPages > 20 ? 5 : 2;
    } else if (isSmall) {
      step = _totalPages > 20 ? 3 : 1;
    } else {
      step = _totalPages > 20 ? 2 : 1;
    }
    
    for (int i = 0; i < _totalPages; i += step) {
      if (seenValues.contains(i)) continue;
      seenValues.add(i);
      
      final pageStart = i * _pageSize + 1;
      final pageEnd = ((i + step) * _pageSize) > _estimatedTotal 
          ? _estimatedTotal 
          : (i + step) * _pageSize;
      
      String label;
      if (isVerySmall) {
        label = '$pageStart-${pageEnd > 0 ? pageEnd : pageStart + _pageSize}';
      } else if (isSmall) {
        label = '$pageStart-${pageEnd > 0 ? pageEnd : pageStart + _pageSize}';
      } else {
        label = '📄 $pageStart-${pageEnd > 0 ? pageEnd : pageStart + _pageSize}';
      }
      
      items.add(
        DropdownMenuItem<int>(
          value: i,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isVerySmall ? 8 : (isSmall ? 9 : 10),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
    
    final lastPageIndex = _totalPages - 1;
    if (!seenValues.contains(lastPageIndex)) {
      final lastPageStart = lastPageIndex * _pageSize + 1;
      final lastPageEnd = _estimatedTotal > 0 ? _estimatedTotal : _totalItems;
      
      String label;
      if (isVerySmall) {
        label = '$lastPageStart-$lastPageEnd';
      } else if (isSmall) {
        label = '$lastPageStart-$lastPageEnd';
      } else {
        label = '📄 $lastPageStart-$lastPageEnd';
      }
      
      items.add(
        DropdownMenuItem<int>(
          value: lastPageIndex,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isVerySmall ? 8 : (isSmall ? 9 : 10),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
    
    return items;
  }

  Widget _buildNextPageButton() {
    // Hide next page button when searching
    if (_isSearching && _searchQuery.isNotEmpty) {
      return const SizedBox.shrink();
    }
    
    final isLastPage = _currentPage >= _totalPages - 1 && !_hasMoreData;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.8),
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade700.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_currentPage + 1}/${_totalPages > 0 ? _totalPages : "..."}',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 11,
            ),
          ),
          SizedBox(
            height: 26,
            child: ElevatedButton.icon(
              onPressed: _isLoadingPage ? null : _goToNextPage,
              icon: _isLoadingPage
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.arrow_forward, size: 12),
              label: Text(
                isLastPage ? '✓' : '→',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastPage 
                    ? Colors.green 
                    : const Color(0xFF42A5F5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                disabledBackgroundColor: Colors.grey.shade700,
                minimumSize: const Size(40, 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _displayList;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          '📝 ${_getExamDisplayName()} Grammar',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isSearching && _searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF42A5F5).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_searchResults.length} found',
                style: const TextStyle(
                  color: Color(0xFF42A5F5),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_estimatedTotal > 0 ? _estimatedTotal : _grammar.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
              widget.level,
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
              onChanged: _filterGrammar,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '🔍 Search all grammar...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: _clearSearch,
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
                : displayList.isEmpty
                    ? _buildEmptyWidget()
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: _buildPaginationControls(),
                          ),
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: displayList.length,
                              itemBuilder: (context, index) {
                                final lesson = displayList[index];
                                return _buildGrammarCard(lesson);
                              },
                            ),
                          ),
                          _buildNextPageButton(),
                        ],
                      ),
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
              onPressed: () => _loadGrammar(refresh: true),
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
                : Icons.school_outlined,
            size: 64,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 16),
          Text(
            _isSearching && _searchQuery.isNotEmpty
                ? 'No results found for "$_searchQuery"'
                : 'No grammar lessons available for ${widget.exam.toUpperCase()} - ${widget.level}',
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
                : 'Add grammar to the grammar collection',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          if (!_isSearching || _searchQuery.isEmpty)
            ElevatedButton(
              onPressed: () => _loadGrammar(refresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF42A5F5),
              ),
              child: const Text('Refresh'),
            ),
        ],
      ),
    );
  }

  Widget _buildGrammarCard(Map<String, dynamic> lesson) {
    final title = lesson['title'] ?? '';
    final titleRomanization = lesson['titleRomanization'] ?? '';
    final description = lesson['description'] ?? '';
    final rule = lesson['rule'] ?? '';
    final ruleRomanization = lesson['ruleRomanization'] ?? '';
    final examples = lesson['examples'] as List? ?? [];
    final burmeseTitle = lesson['burmeseTitle'] ?? '';
    final burmeseDescription = lesson['burmeseDescription'] ?? '';
    final burmeseRule = lesson['burmeseRule'] ?? '';
    final burmeseExamples = lesson['burmeseExamples'] as List? ?? [];
    final exampleRomanizations = lesson['exampleRomanizations'] as List? ?? [];

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isSmallScreen ? 10 : 16),
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
          // Title with Audio Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (titleRomanization.isNotEmpty)
                      Text(
                        titleRomanization,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: isSmallScreen ? 11 : 13,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (burmeseTitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '🇲🇲 $burmeseTitle',
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF42A5F5).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.level,
                      style: TextStyle(
                        color: const Color(0xFF42A5F5),
                        fontSize: isSmallScreen ? 8 : 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  IconButton(
                    onPressed: () => _playAudio(title),
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
          const SizedBox(height: 8),
          
          // Description
          Text(
            description,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: isSmallScreen ? 12 : 13,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (burmeseDescription.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '🇲🇲 $burmeseDescription',
                style: GoogleFonts.notoSansMyanmar(
                  color: Colors.grey.shade500,
                  fontSize: isSmallScreen ? 11 : 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: 8),
          
          // Rule
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade900.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule,
                  style: TextStyle(
                    color: const Color(0xFF42A5F5),
                    fontSize: isSmallScreen ? 13 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (ruleRomanization.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      ruleRomanization,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: isSmallScreen ? 10 : 12,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (burmeseRule.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '🇲🇲 $burmeseRule',
                      style: GoogleFonts.notoSansMyanmar(
                        color: Colors.grey.shade400,
                        fontSize: isSmallScreen ? 12 : 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          
          // Examples
          if (examples.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '📖 Examples',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: isSmallScreen ? 12 : 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...examples.asMap().entries.map((entry) {
              final index = entry.key;
              final example = entry.value;
              final burmeseExample = burmeseExamples.length > index 
                  ? burmeseExamples[index] 
                  : '';
              final romanization = exampleRomanizations.length > index 
                  ? exampleRomanizations[index] 
                  : '';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.shade700.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Example text with audio
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: isSmallScreen ? 20 : 24,
                          height: isSmallScreen ? 20 : 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF42A5F5).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: const Color(0xFF42A5F5),
                                fontSize: isSmallScreen ? 8 : 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            example,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: isSmallScreen ? 13 : 14,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _playAudio(example),
                          icon: Icon(
                            Icons.volume_up,
                            color: const Color(0xFF42A5F5),
                            size: isSmallScreen ? 14 : 16,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    
                    // Example Romanization
                    if (romanization.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: EdgeInsets.only(left: isSmallScreen ? 28 : 32),
                        child: Text(
                          romanization,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: isSmallScreen ? 10 : 12,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    
                    // Burmese Example Translation
                    if (burmeseExample.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: EdgeInsets.only(left: isSmallScreen ? 28 : 32),
                        child: Text(
                          '🇲🇲 $burmeseExample',
                          style: GoogleFonts.notoSansMyanmar(
                            color: Colors.grey.shade400,
                            fontSize: isSmallScreen ? 12 : 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
          
          // Audio hint
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

  void _playAudio(String text) async {
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔊 No audio available for this text'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    try {
      await AudioService.speak(text, language: widget.language);
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
}