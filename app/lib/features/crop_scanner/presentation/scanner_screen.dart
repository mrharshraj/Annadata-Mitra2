import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/errors/backend_failure.dart';
import '../../../core/providers/scanner_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/am_buttons.dart';
import '../../../core/widgets/am_cards.dart';
import '../../../core/widgets/am_scaffold.dart';
import '../../../core/widgets/backend_state_view.dart';
import '../../../data/repositories/scanner_repository.dart';
import '../../../l10n/app_localizations.dart';

/// 13 — Crop health scanner: camera/gallery → compressed capture →
/// private Storage upload → FastAPI vision analysis → result with
/// explicit uncertainty. Denied permissions and offline fail softly.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

enum _Stage { idle, capturing, uploading, analyzing, done }

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final _picker = ImagePicker();
  _Stage _stage = _Stage.idle;
  ScanOutcome? _outcome;
  BackendFailure? _error;

  bool get _busy =>
      _stage == _Stage.capturing ||
      _stage == _Stage.uploading ||
      _stage == _Stage.analyzing;

  Future<void> _capture(ImageSource source) async {
    if (_busy) return;
    setState(() {
      _stage = _Stage.capturing;
      _error = null;
      _outcome = null;
    });
    XFile? file;
    try {
      // maxWidth + imageQuality keep uploads small for rural networks.
      file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 70,
      );
    } on PlatformException {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.idle;
        _error = const BackendFailure(
          BackendFailureKind.permission,
          'Camera/gallery permission denied. Enable it in settings.',
        );
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.idle;
        _error = const BackendFailure(
          BackendFailureKind.unknown,
          'Could not open camera/gallery.',
        );
      });
      return;
    }
    if (file == null || !mounted) {
      setState(() => _stage = _Stage.idle);
      return; // user cancelled — not an error.
    }
    final repo = ref.read(scannerRepositoryProvider);
    setState(() => _stage = _Stage.uploading);
    final up = await repo.upload(
      localPath: file.path,
      fileName: '${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    if (!mounted) return;
    final String? path;
    switch (up) {
      case Ok(:final value):
        path = value;
      case Err(:final failure):
        setState(() {
          _stage = _Stage.idle;
          _error = failure;
        });
        return;
    }
    if (!mounted) return;
    setState(() => _stage = _Stage.analyzing);
    final res = await repo.analyze(imagePath: path);
    if (!mounted) return;
    setState(() => _stage = _Stage.done);
    switch (res) {
      case Ok(:final value):
        setState(() => _outcome = value);
      case Err(:final failure):
        setState(() => _error = failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AmScaffold(
      title: l.scannerTitle.toUpperCase(),
      subtitle: l.scannerSubtitle,
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.md),
          AspectRatio(
            aspectRatio: 4 / 5,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE9E8E7),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                border: Border.all(color: const Color(0xFFC4C7C7)),
              ),
              child: Center(
                child: switch (_stage) {
                  _Stage.idle => Text(
                    _outcome == null
                        ? 'VIEWFINDER'
                        : 'SCAN COMPLETE',
                    style: AppTextStyles.labelMd(context),
                  ),
                  _Stage.capturing => const Text('OPENING CAMERA…'),
                  _Stage.uploading => const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('UPLOADING…'),
                    ],
                  ),
                  _Stage.analyzing => const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('ANALYZING…'),
                    ],
                  ),
                  _Stage.done => const Icon(Icons.check_circle, size: 48),
                },
              ),
            ),
          ),
          if (_outcome != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AmCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CROP: ${_outcome!.detectedCrop ?? 'unknown'}',
                    style: AppTextStyles.labelMd(context),
                  ),
                  Text(
                    'ISSUE: ${_outcome!.detectedIssue ?? 'none visible'}',
                    style: AppTextStyles.bodyMd(context),
                  ),
                  Text(
                    'CONFIDENCE: ${(_outcome!.confidence * 100).toStringAsFixed(0)}%',
                    style: AppTextStyles.bodyMd(context),
                  ),
                  if (_outcome!.uncertain)
                    const Text(
                      'Low confidence — treat as a hint and verify locally.',
                    ),
                  if (_outcome!.notes.isNotEmpty)
                    Text('NEXT: ${_outcome!.notes}'),
                ],
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            BackendStateView.failure(failure: _error!),
          ],
          const SizedBox(height: AppSpacing.md),
          if (SupabaseConfig.isConfigured) ...[
            AmPrimaryButton(
              label: 'SCAN WITH CAMERA',
              icon: Icons.camera_alt,
              onPressed: _busy ? null : () => _capture(ImageSource.camera),
            ),
            const SizedBox(height: AppSpacing.sm),
            AmSecondaryButton(
              label: 'CHOOSE FROM GALLERY',
              icon: Icons.photo_library,
              onPressed: _busy ? null : () => _capture(ImageSource.gallery),
            ),
          ] else ...[
            AmPrimaryButton(
              label: l.scannerCta,
              icon: Icons.camera_alt,
              onPressed: null,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l.phase1Note, style: AppTextStyles.bodyMd(context)),
          ],
        ],
      ),
    );
  }
}
