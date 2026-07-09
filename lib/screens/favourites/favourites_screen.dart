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
  String? _error;
  String _selectedLanguage = 'english';

  @override
  void initState() {
    super.initState();
    _loadFavourites();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFavourites();
  }

  Future<void> _loadFavourites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

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

      final favourites = await _firestoreService.getFavouriteVocabulary(
        userId: user.uid,
        language: _selectedLanguage,
      );
      
      setState(() {
        _favourites = favourites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load favourites: $e';
        _isLoading = false;
      });
    }
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

      setState(() {
        _favourites.removeWhere((vocab) => vocab.id == wordId);
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
        const SnackBar(
          content: Text('❌ Failed to remove from favourites'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

              // ✅ Language filter - Responsive with Wrap
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

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF42A5F5),
                        ),
                      )
                    : _error != null
                        ? Center(
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
                                  onPressed: _loadFavourites,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF42A5F5),
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : _favourites.isEmpty
                            ? Center(
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
                              )
                            : RefreshIndicator(
                                onRefresh: _loadFavourites,
                                child: ListView.builder(
                                  itemCount: _favourites.length,
                                  itemBuilder: (context, index) {
                                    final vocab = _favourites[index];
                                    return _buildFavouriteCard(vocab);
                                  },
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
      onTap: () {
        setState(() {
          _selectedLanguage = language;
        });
        _loadFavourites();
      },
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
          // Burmese word - Expanded to take available space
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
          // Remove button - Fixed size, not flex
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
}