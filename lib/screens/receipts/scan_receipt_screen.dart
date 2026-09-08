import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:track_me/core/app_strings.dart';
import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/receipt_parser.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/screens/transactions/expense_form_screen.dart';
import 'package:track_me/services/receipt_ocr.dart';

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();
  final _parser = ReceiptParser();

  String? _imagePath;
  bool _ocrAvailable = ReceiptOcr.isAvailable;
  bool _scanning = false;
  bool _extracting = false;
  ReceiptParseResult? _parsed;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
          source: source, maxWidth: 2000, imageQuality: 85);
      if (file == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(p.join(dir.path, 'receipts'));
      if (!await receiptsDir.exists())
        await receiptsDir.create(recursive: true);
      final dest = p.join(receiptsDir.path,
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}');
      await File(file.path).copy(dest);
      if (!mounted) return;
      setState(() {
        _imagePath = dest;
        _parsed = null;
      });
      await _scan(dest);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not capture image: $e')));
    }
  }

  Future<void> _scan(String path) async {
    if (!_ocrAvailable) return;
    setState(() => _scanning = true);
    final text = await ReceiptOcr.recognize(path);
    if (!mounted) return;
    setState(() {
      _scanning = false;
      _textController.text = text.trim();
    });
    if (text.trim().isNotEmpty) _extract();
  }

  Future<void> _extract() async {
    setState(() {
      _extracting = true;
      _parsed = null;
    });
    final result = _parser.parse(_textController.text);
    if (!mounted) return;
    setState(() {
      _extracting = false;
      _parsed = result;
    });
  }

  Future<void> _addAsExpense() async {
    final parsed = _parsed;
    if (parsed?.total == null) return;
    final description = (parsed!.merchant ?? 'Receipt purchase').trim();
    final notes = parsed.items.isEmpty ? '' : parsed.items.join(' · ');
    int? categoryId;
    if (description.isNotEmpty) {
      categoryId = await AppRepository.instance.autoCategorize(description);
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExpenseFormScreen(
          initialCategoryId: categoryId,
          initialAmount: parsed.total,
          initialDescription: description,
          initialDate: parsed.date,
          initialPaymentMethod: parsed.paymentMethodCode,
          initialNotes: notes,
          initialReceiptPath: _imagePath,
          receiptOcrText: _textController.text.trim().isEmpty
              ? null
              : _textController.text.trim(),
        ),
      ),
    );
  }

  Future<void> _saveReceiptOnly() async {
    final path = _imagePath;
    if (path == null) return;
    try {
      final file = File(path);
      final size = await file.length();
      await AppRepository.instance.addReceipt(
        filePath: path,
        fileName: p.basename(path),
        fileSize: size,
        mimeType: 'image/jpeg',
        ocrText: _textController.text.trim().isEmpty
            ? null
            : _textController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Receipt saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save receipt: $e')));
    }
  }

  String _formatDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Receipt')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (!_ocrAvailable) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.accent),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'On-device OCR is not available here. Pick a photo, then paste its text below and tap "Extract details".',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Take photo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose image'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_imagePath != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF262C38)
                      : const Color(0xFFE8EAF1),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(File(_imagePath!),
                        width: 72, height: 72, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.basename(_imagePath!),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        if (_scanning)
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                                SizedBox(width: 8),
                                Text('Reading text…',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() {
                      _imagePath = null;
                      _parsed = null;
                    }),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Text('Recognized text', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _textController,
            minLines: 5,
            maxLines: 10,
            onChanged: (_) => _parsed = null,
            decoration: const InputDecoration(
              hintText:
                  'Receipt text appears here. You can edit it or paste the receipt text manually.\n\nTip: copy from "TOTAL 125.00" down.',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: (_extracting || _scanning) ? null : _extract,
            icon: _extracting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2, color: Colors.white))
                : const Icon(Icons.auto_fix_high_outlined),
            label: const Text('Extract details'),
          ),
          const SizedBox(height: 16),
          if (_parsed != null) _buildResultCard(context),
        ],
      ),
    );
  }

  Widget _buildResultCard(BuildContext context) {
    final r = _parsed!;
    final canAdd = r.total != null;
    return BrandHeroCard(
      padding: const EdgeInsets.all(16),
      radius: AppTheme.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Extracted details',
              style: TextStyle(
                  color: AppColors.onHeroMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  r.total == null
                      ? '—'
                      : '${currencySymbol('PHP')}${r.total!.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: AppColors.onHero,
                      fontSize: 30,
                      fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    r.merchant ?? 'Merchant not found',
                    style: TextStyle(
                        color: AppColors.onHeroMuted,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (r.date != null)
                _InfoChip(
                    icon: Icons.calendar_today_outlined,
                    text: formatDateShort(_formatDate(r.date!))),
              if (r.paymentMethodCode != null)
                Chip(
                  avatar:
                      PaymentMethodBadge(code: r.paymentMethodCode!, size: 18),
                  label: Text(paymentMethodLabel(r.paymentMethodCode!)),
                  labelStyle: const TextStyle(fontSize: 12),
                  side: BorderSide.none,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                ),
              if (r.items.isNotEmpty)
                _InfoChip(
                    icon: Icons.list_alt, text: '${r.items.length} line items'),
            ],
          ),
          if (r.items.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final item in r.items.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '• $item',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12.5),
                ),
              ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (_imagePath != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saveReceiptOnly,
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.5))),
                    child: const Text('Save receipt only'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: canAdd ? _addAsExpense : null,
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary),
                  icon: const Icon(Icons.add_card),
                  label: Text(canAdd ? 'Add as expense' : 'No total found'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
