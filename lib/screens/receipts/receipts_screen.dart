import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/models.dart';
import 'package:track_me/providers/app_state.dart';

class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  late Future<List<Receipt>> _future;
  int _lastVersion = -1;
  bool _picking = false;

  Future<List<Receipt>> _load() => AppRepository.instance.getReceipts();

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _addReceipt() async {
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      final sourcePath = file.path;
      if (sourcePath == null) return;

      final dir = await getApplicationDocumentsDirectory();
      final destDir = Directory('${dir.path}/receipts');
      if (!await destDir.exists()) await destDir.create(recursive: true);
      final safeName = file.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final destPath = '${destDir.path}/$safeName';
      await File(sourcePath).copy(destPath);

      final size = await File(destPath).length();
      final mimeType = _isImage(file.name) ? 'image/jpeg' : 'application/pdf';
      await AppRepository.instance.addReceipt(
        filePath: destPath,
        fileName: file.name,
        fileSize: size,
        mimeType: mimeType,
      );
      context.read<AppState>().bumpData();
      if (mounted) _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not add receipt: $e')));
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  bool _isImage(String fileName) {
    return fileName.toLowerCase().endsWith('.png') ||
        fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg') ||
        fileName.toLowerCase().endsWith('.webp') ||
        fileName.toLowerCase().endsWith('.heic');
  }

  Future<void> _view(Receipt receipt) async {
    final path = receipt.filePath;
    if (!await File(path).exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receipt file is missing.')));
      }
      return;
    }
    if (mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => _ReceiptViewer(path: path, isImage: _isImage(receipt.fileName))));
    }
  }

  Future<void> _delete(Receipt receipt) async {
    final ok = await _confirmDelete(receipt.fileName);
    if (ok == true) {
      await AppRepository.instance.deleteReceipt(receipt.id!);
      context.read<AppState>().bumpData();
      if (mounted) _reload();
    }
  }

  Future<bool?> _confirmDelete(String name) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete receipt'),
        content: Text('Delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final version = context.watch<AppState>().dataVersion;
    if (_lastVersion != version) {
      _lastVersion = version;
      _future = _load();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipts'),
        actions: [
          IconButton(
            tooltip: 'Add receipt',
            onPressed: _picking ? null : _addReceipt,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _picking
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Receipt>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final receipts = snapshot.data ?? [];
                if (receipts.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No receipts yet',
                    message: 'Store images or PDFs of your receipts so you never lose them.',
                    action: ElevatedButton.icon(
                      onPressed: _addReceipt,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Receipt'),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  itemCount: receipts.length,
                  itemBuilder: (context, i) {
                    final r = receipts[i];
                    final isImage = _isImage(r.fileName);
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      onTap: () => _view(r),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: isImage ? AppColors.primary.withValues(alpha: 0.1) : AppColors.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              isImage ? Icons.image_outlined : Icons.picture_as_pdf_outlined,
                              color: isImage ? AppColors.primary : AppColors.danger,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.fileName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 3),
                                Text(
                                  r.expenseDescription != null
                                      ? 'Linked to "${r.expenseDescription}"'
                                      : '${_sizeLabel(r.fileSize)} · ${_dateLabel(r.createdAt)}',
                                  style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall!.color),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                            onPressed: () => _delete(r),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  String _sizeLabel(int bytes) {
    if (bytes <= 0) return 'Unknown size';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _dateLabel(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return formatDateShort(iso);
  }
}

class _ReceiptViewer extends StatefulWidget {
  final String path;
  final bool isImage;
  const _ReceiptViewer({required this.path, required this.isImage});

  @override
  State<_ReceiptViewer> createState() => _ReceiptViewerState();
}

class _ReceiptViewerState extends State<_ReceiptViewer> {
  bool _exists = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final exists = await File(widget.path).exists();
    if (mounted) setState(() => _exists = exists);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      body: Center(
        child: !_exists
            ? const Text('File not found.')
            : widget.isImage
                ? InteractiveViewer(
                    maxScale: 6,
                    child: Image.file(File(widget.path), fit: BoxFit.contain),
                  )
                : InteractiveViewer(
                    maxScale: 6,
                    child: Image.file(File(widget.path), fit: BoxFit.contain, errorBuilder: (ctx, e, st) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.picture_as_pdf_outlined, size: 56, color: AppColors.danger),
                            const SizedBox(height: 12),
                            Text('PDF preview not available', style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color)),
                          ],
                        ),
                      );
                    }),
                  ),
      ),
    );
  }
}