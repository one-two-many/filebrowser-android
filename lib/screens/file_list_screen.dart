import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/auth_provider.dart';
import '../models/file_entry.dart';
import '../theme/nocturne_colors.dart';
import '../theme/theme_controller.dart';
import '../utils/format.dart';
import '../widgets/new_folder_sheet.dart';
import '../widgets/nocturne_toast.dart';
import '../widgets/upload_sheet.dart';

class FileListScreen extends StatefulWidget {
  const FileListScreen({super.key});

  @override
  State<FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen> {
  final List<FileEntry> _pathStack = [];
  late Future<List<FileEntry>> _entriesFuture;
  bool _searchVisible = false;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  String get _currentPath => _pathStack.isEmpty ? '/' : _pathStack.last.path;
  String get _currentTitle => _pathStack.isEmpty ? 'Home' : _pathStack.last.name;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<FileEntry>> _load() {
    return context.read<AuthProvider>().client.listDirectory(_currentPath);
  }

  void _open(FileEntry entry) {
    if (!entry.isDir) return;
    setState(() {
      _pathStack.add(entry);
      _searchVisible = false;
      _query = '';
      _searchController.clear();
      _entriesFuture = _load();
    });
  }

  void _goBack() {
    if (_pathStack.isEmpty) return;
    setState(() {
      _pathStack.removeLast();
      _searchVisible = false;
      _query = '';
      _searchController.clear();
      _entriesFuture = _load();
    });
  }

  void _goToBreadcrumb(int keepCount) {
    if (keepCount >= _pathStack.length) return;
    setState(() {
      _pathStack.removeRange(keepCount, _pathStack.length);
      _searchVisible = false;
      _query = '';
      _searchController.clear();
      _entriesFuture = _load();
    });
  }

  void _toggleSearch() {
    setState(() {
      _searchVisible = !_searchVisible;
      _query = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.nocturne;
    final themeController = context.watch<ThemeController>();

    return PopScope(
      canPop: _pathStack.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        backgroundColor: colors.bg,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(colors, themeController),
              _buildBreadcrumbs(colors),
              if (_searchVisible) _buildSearchField(colors),
              Expanded(child: _buildBody(colors)),
              _buildBottomBar(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(NocturneColors colors, ThemeController themeController) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      child: Row(
        children: [
          if (_pathStack.isNotEmpty)
            IconButton(
              icon: Icon(Icons.arrow_back, color: colors.text),
              onPressed: _goBack,
            ),
          Expanded(
            child: Text(
              _currentTitle,
              style: TextStyle(
                fontSize: 24,
                letterSpacing: -0.02,
                fontWeight: FontWeight.w500,
                color: colors.text,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.search, color: colors.text),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: Icon(
              themeController.isDark ? Icons.dark_mode : Icons.light_mode,
              color: colors.accent,
            ),
            onPressed: themeController.toggle,
          ),
          IconButton(
            icon: Icon(Icons.logout, color: colors.mutedText(0.6)),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs(NocturneColors colors) {
    final crumbs = <MapEntry<String, int>>[
      const MapEntry('Home', 0),
      for (var i = 0; i < _pathStack.length; i++)
        MapEntry(_pathStack[i].name, i + 1),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < crumbs.length; i++) ...[
              GestureDetector(
                onTap: () => _goToBreadcrumb(crumbs[i].value),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                  child: Text(
                    crumbs[i].key,
                    style: TextStyle(
                      fontSize: 13,
                      color: i == crumbs.length - 1
                          ? colors.text
                          : colors.mutedText(0.55),
                    ),
                  ),
                ),
              ),
              if (i != crumbs.length - 1)
                Icon(Icons.chevron_right, size: 14, color: colors.mutedText(0.4)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(NocturneColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value),
        decoration: const InputDecoration(hintText: 'Search this folder'),
      ),
    );
  }

  Widget _buildBody(NocturneColors colors) {
    return FutureBuilder<List<FileEntry>>(
      future: _entriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Failed to load: ${snapshot.error}',
                style: TextStyle(color: colors.text),
              ),
            ),
          );
        }

        final entries = snapshot.data ?? [];
        final query = _query.trim().toLowerCase();
        bool matches(FileEntry e) =>
            query.isEmpty || e.name.toLowerCase().contains(query);

        final folders = entries.where((e) => e.isDir && matches(e)).toList();
        final files = entries.where((e) => !e.isDir && matches(e)).toList()
          ..sort((a, b) => b.modified.compareTo(a.modified));

        if (folders.isEmpty && files.isEmpty) {
          return _buildEmptyState(colors, query);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 18),
          children: [
            if (folders.isNotEmpty) ...[
              _sectionLabel(colors, 'Folders'),
              for (final folder in folders) _FolderRow(folder: folder, onOpen: _open),
              const SizedBox(height: 14),
            ],
            if (files.isNotEmpty) ...[
              _sectionLabel(colors, 'Files'),
              for (final file in files) _FileRow(file: file),
            ],
          ],
        );
      },
    );
  }

  Widget _sectionLabel(NocturneColors colors, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 0.08,
          color: colors.mutedText(0.55),
        ),
      ),
    );
  }

  Widget _buildEmptyState(NocturneColors colors, String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 70),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 52, color: colors.mutedText(0.45)),
            const SizedBox(height: 10),
            Text(
              query.isNotEmpty ? 'No matches for "$_query"' : 'This folder is empty',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colors.mutedText(0.70),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(NocturneColors colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      decoration: BoxDecoration(
        color: colors.bg,
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => showNewFolderSheet(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New folder'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: () =>
                  showUploadSheet(context, targetFolderName: _currentTitle),
              icon: const Icon(Icons.upload, size: 18),
              label: const Text('Upload'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderRow extends StatelessWidget {
  final FileEntry folder;
  final void Function(FileEntry) onOpen;

  const _FolderRow({required this.folder, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final colors = context.nocturne;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onOpen(folder),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(Icons.folder, color: colors.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    folder.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: colors.text,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'Upload here',
                  icon: Icon(Icons.upload_outlined, size: 19, color: colors.mutedText(0.6)),
                  onPressed: () => showNocturneToast(context, 'Not implemented yet'),
                ),
                IconButton(
                  tooltip: 'Download folder',
                  icon: Icon(Icons.download_outlined, size: 19, color: colors.mutedText(0.6)),
                  onPressed: () => showNocturneToast(context, 'Not implemented yet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  final FileEntry file;

  const _FileRow({required this.file});

  String get _extension {
    final dot = file.name.lastIndexOf('.');
    if (dot == -1 || dot == file.name.length - 1) return '';
    return file.name.substring(dot + 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.nocturne;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.accent800,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              _extension,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.accent100,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: colors.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  formatBytes(file.size),
                  style: TextStyle(fontSize: 12, color: colors.mutedText(0.52)),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Download',
            icon: Icon(Icons.download_outlined, size: 19, color: colors.mutedText(0.6)),
            onPressed: () => showNocturneToast(context, 'Not implemented yet'),
          ),
        ],
      ),
    );
  }
}
