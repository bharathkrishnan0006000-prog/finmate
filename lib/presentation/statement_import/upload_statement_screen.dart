import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routes/route_names.dart';
import '../../core/widgets/app_card.dart';
import '../../core/di/providers.dart';

class UploadStatementScreen extends ConsumerStatefulWidget {
  const UploadStatementScreen({super.key});

  @override
  ConsumerState<UploadStatementScreen> createState() => _UploadStatementScreenState();
}

class _UploadStatementScreenState extends ConsumerState<UploadStatementScreen> {
  bool _isParsing = false;
  String? _errorMessage;

  Future<void> _pickAndParse() async {
    setState(() => _errorMessage = null);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'csv', 'xlsx', 'xls', 'txt'],
    );
    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;
    final parser = ref.read(statementParserServiceProvider);
    final fileType = parser.typeFromExtension(path);
    if (fileType == null) {
      setState(() => _errorMessage = 'Unsupported file type.');
      return;
    }

    setState(() => _isParsing = true);
    try {
      final parsed = await parser.parseFile(File(path), fileType);
      if (!mounted) return;
      setState(() => _isParsing = false);
      if (parsed.isEmpty) {
        setState(() => _errorMessage = 'No transactions could be found in this file.');
        return;
      }
      context.push(RouteNames.categorizeTransactions, extra: parsed);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isParsing = false;
        _errorMessage = e.toString().replaceFirst('ImportFailure: ', '');
      });
    }
  }

  Future<void> _scanWithCamera() async {
    setState(() => _errorMessage = null);
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (image == null) return;

    setState(() => _isParsing = true);
    try {
      final ocr = ref.read(ocrServiceProvider);
      final text = await ocr.extractText(File(image.path));
      final parser = ref.read(statementParserServiceProvider);
      final parsed = parser.parseTextLines(text);
      if (!mounted) return;
      setState(() => _isParsing = false);
      if (parsed.isEmpty) {
        setState(() => _errorMessage =
            'Could not read any transactions from the photo. Try better lighting, a flatter angle, or import the file directly instead.');
        return;
      }
      context.push(RouteNames.categorizeTransactions, extra: parsed);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isParsing = false;
        _errorMessage = 'Could not process the photo: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Upload Statement')),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.lg),
        children: [
          InkWell(
            onTap: _isParsing ? null : _pickAndParse,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            child: DottedBorderBox(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.xxxl),
                child: Column(
                  children: [
                    if (_isParsing)
                      const CircularProgressIndicator()
                    else
                      const Icon(Icons.cloud_upload_outlined, size: 44, color: AppColors.primary),
                    const SizedBox(height: AppSizes.md),
                    Text(
                      _isParsing ? 'Reading your statement…' : 'Tap to Browse',
                      style: AppTextStyles.titleMd,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upload your bank statement\n(PDF, CSV, XLSX)',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySm,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          OutlinedButton.icon(
            onPressed: _isParsing ? null : _scanWithCamera,
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: const Text('Scan Paper Statement with Camera'),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSizes.md),
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(child: Text(_errorMessage!, style: AppTextStyles.bodySm.copyWith(color: AppColors.error))),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSizes.xxl),
          Text('How it works', style: AppTextStyles.headingSm),
          const SizedBox(height: AppSizes.md),
          const _HowItWorksStep(number: '1', text: 'Choose a PDF, CSV, or Excel bank statement file.'),
          const _HowItWorksStep(number: '2', text: 'FinMate reads each transaction using the exact dates from your statement.'),
          const _HowItWorksStep(number: '3', text: 'Review suggested categories and confirm duplicates before importing.'),
          const SizedBox(height: AppSizes.xxl),
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    'Everything is processed on your device. Your statement never leaves your phone.',
                    style: AppTextStyles.bodySm,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DottedBorderBox extends StatelessWidget {
  final Widget child;
  const DottedBorderBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.scaffoldGrey,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border, width: 1.4),
      ),
      child: child,
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  final String number;
  final String text;
  const _HowItWorksStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.accentSoft,
            child: Text(number, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(child: Text(text, style: AppTextStyles.bodyMd)),
        ],
      ),
    );
  }
}
