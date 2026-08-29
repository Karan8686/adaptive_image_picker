import 'package:flutter/material.dart';
import 'package:adaptive_image_picker/adaptive_image_picker.dart';
import 'screens/playground_screen.dart';
import 'screens/recipes_screen.dart';
import 'screens/gallery_screen.dart';

void main() {
  runApp(const AdaptiveImagePickerShowcaseApp());
}

class AdaptiveImagePickerShowcaseApp extends StatefulWidget {
  const AdaptiveImagePickerShowcaseApp({super.key});

  @override
  State<AdaptiveImagePickerShowcaseApp> createState() => _AdaptiveImagePickerShowcaseAppState();
}

class _AdaptiveImagePickerShowcaseAppState extends State<AdaptiveImagePickerShowcaseApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    const brandSeed = Color(0xFF3F51B5); // Indigo 500

    return MaterialApp(
      title: 'Adaptive Media Picker Studio',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: brandSeed,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8F9FE),
        cardTheme: const CardThemeData(color: Colors.white),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: brandSeed,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF111318),
      ),
      home: MainShowcaseScreen(
        onToggleTheme: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

class MainShowcaseScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const MainShowcaseScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<MainShowcaseScreen> createState() => _MainShowcaseScreenState();
}

class _MainShowcaseScreenState extends State<MainShowcaseScreen> {
  int _currentTabIndex = 0;
  final List<AdaptiveFile> _collectedMedia = [];

  void _addMediaItem(AdaptiveFile file) {
    setState(() {
      _collectedMedia.insert(0, file);
    });
  }

  void _addMultipleMedia(List<AdaptiveFile> files) {
    setState(() {
      _collectedMedia.insertAll(0, files);
    });
  }

  void _updateMediaItem(int index, AdaptiveFile updated) {
    setState(() {
      if (index >= 0 && index < _collectedMedia.length) {
        _collectedMedia[index] = updated;
      }
    });
  }

  void _deleteMediaItem(int index) {
    setState(() {
      if (index >= 0 && index < _collectedMedia.length) {
        _collectedMedia.removeAt(index);
      }
    });
  }

  void _clearAllMedia() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Gallery'),
        content: const Text('Are you sure you want to remove all collected media items?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _collectedMedia.clear());
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.perm_media_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Adaptive Picker',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            tooltip: 'Toggle Theme',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          PlaygroundScreen(onMediaAdded: _addMediaItem),
          RecipesScreen(
            onMediaAdded: _addMediaItem,
            onMultipleMediaAdded: _addMultipleMedia,
          ),
          GalleryScreen(
            files: _collectedMedia,
            onFileUpdated: _updateMediaItem,
            onFileDeleted: _deleteMediaItem,
            onClearAll: _clearAllMedia,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (index) => setState(() => _currentTabIndex = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Studio',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bolt_outlined),
            selectedIcon: Icon(Icons.bolt_rounded),
            label: 'Recipes',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _collectedMedia.isNotEmpty,
              label: Text('${_collectedMedia.length}'),
              child: const Icon(Icons.photo_library_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: _collectedMedia.isNotEmpty,
              label: Text('${_collectedMedia.length}'),
              child: const Icon(Icons.photo_library_rounded),
            ),
            label: 'Gallery',
          ),
        ],
      ),
    );
  }
}
