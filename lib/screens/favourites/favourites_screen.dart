import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/vocabulary_model.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<VocabularyModel> _favourites = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  String _selectedLanguage = 'english';
  List<String> _allFavouriteIds = [];
  int _currentPage = 0;
  static const int _pageSize = 30;

  @override
  void initState() {
    super.initState();
    _loadFavourites(reset: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only reload if user changed
    final authService = Provider.of<AuthService>(context);
    if (authService.user != null) {
      // User is logged in, we're good
    }
  }

  Future<void> _loadFavourites({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _error = null;
        _favourites = [];
        _allFavouriteIds = [];
        _currentPage = 0;
        _hasMore = true;
        _isLoadingMore = false;
      });
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.user;
      
      if (user == null) {
        setState(() {
          _isLoading = false;
          _error = 'Please sign in to see favourites';
        });
        return;
      }

      // ✅ CORRECTED: Pass both required arguments
      final favouriteIds = await _firestoreService.getFavouriteIds(
        user.uid,  // First positional argument: userId
        _selectedLanguage,  // Second positional argument: language
      );
      
      if (favouriteIds.isEmpty) {
        setState(() {
          _favourites = [];
          _isLoading = false;
          _hasMore = false;
          _allFavouriteIds = [];
        });
        return;
      }

      // Store all IDs for pagination
      if (reset) {
        _allFavouriteIds = favouriteIds;
      }

      // Calculate pagination
      final startIndex = _currentPage * _pageSize;
      final endIndex = (startIndex + _pageSize) > _allFavouriteIds.length 
          ? _allFavouriteIds.length 
          : startIndex + _pageSize;
      
      if (startIndex >= _allFavouriteIds.length) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
          _isLoadingMore = false;
        });
        return;
      }

      final batchIds = _allFavouriteIds.sublist(startIndex, endIndex);
      
      // Query for vocabulary items
      final vocabularyItems = await _firestoreService.getVocabularyByIds(
        wordIds: batchIds,
        language: _selectedLanguage,
      );
      
      setState(() {
        if (reset) {
          _favourites = vocabularyItems;
        } else {
          _favourites.addAll(vocabularyItems);
        }
        _currentPage++;
        _hasMore = endIndex < _allFavouriteIds.length;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load favourites: $e';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreFavourites() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    await _loadFavourites(reset: false);
  }

  Future<void> _removeFavourite(String wordId) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.user;
      
      if (user == null) return;

      await _firestoreService.toggleFavourite(
        userId: user.uid,
        wordId: wordId,
        language: _selectedLanguage,
        isFavourite: false,
      );

      // Remove from local lists
      setState(() {
        _favourites.removeWhere((vocab) => vocab.id == wordId);
        _allFavouriteIds.remove(wordId);
        // If no more items, set hasMore to false
        if (_favourites.isEmpty && _allFavouriteIds.isEmpty) {
          _hasMore = false;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⭐ Removed from favourites'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to remove from favourites: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _changeLanguage(String language) {
    if (_selectedLanguage == language) return;
    
    setState(() {
      _selectedLanguage = language;
    });
    _loadFavourites(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '⭐ Your Favourites',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Words you have saved for later',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),

              // Language filter chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildLanguageChip('english', '🇬🇧'),
                  _buildLanguageChip('korean', '🇰🇷'),
                  _buildLanguageChip('japanese', '🇯🇵'),
                  _buildLanguageChip('chinese', '🇨🇳'),
                ],
              ),
              const SizedBox(height: 16),

              // Content with pagination
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF42A5F5),
                        ),
                      )
                    : _error != null
                        ? _buildErrorWidget()
                        : _favourites.isEmpty
                            ? _buildEmptyWidget()
                            : RefreshIndicator(
                                onRefresh: () => _loadFavourites(reset: true),
                                child: NotificationListener<ScrollNotification>(
                                  onNotification: (ScrollNotification scrollInfo) {
                                    if (scrollInfo.metrics.pixels == 
                                        scrollInfo.metrics.maxScrollExtent &&
                                        !_isLoadingMore &&
                                        _hasMore) {
                                      _loadMoreFavourites();
                                    }
                                    return false;
                                  },
                                  child: ListView.builder(
                                    itemCount: _favourites.length + (_hasMore ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index == _favourites.length) {
                                        return _buildLoadingMoreIndicator();
                                      }
                                      final vocab = _favourites[index];
                                      return _buildFavouriteCard(vocab);
                                    },
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

  Widget _buildLanguageChip(String language, String flag) {
    final isSelected = _selectedLanguage == language;
    return GestureDetector(
      onTap: () => _changeLanguage(language),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 3),
            Text(
              language.toUpperCase(),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade400,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavouriteCard(VocabularyModel vocab) {
    final translation = vocab.getTranslation(_selectedLanguage);
    final romanization = vocab.getRomanization(_selectedLanguage);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade700.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Word details - Expanded
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  vocab.burmeseWord,
                  style: GoogleFonts.notoSansMyanmar(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  vocab.romanization,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (translation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    translation,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (romanization.isNotEmpty)
                    Text(
                      romanization,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ],
            ),
          ),
          // Remove button
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(
                Icons.favorite,
                color: Colors.red,
                size: 22,
              ),
              onPressed: () => _removeFavourite(vocab.id),
              tooltip: 'Remove from favourites',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF42A5F5),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadFavourites(reset: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF42A5F5),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 16),
          Text(
            'No favourites yet',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the heart icon on any word to save it here',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}