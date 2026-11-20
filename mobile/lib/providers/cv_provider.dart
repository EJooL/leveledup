import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/cv_analysis_model.dart';
import 'career_provider.dart';

enum ScanStep {
  idle,
  parsingPdf,
  analyzingAts,
  completed,
  rewriting,
}

class CvScanState {
  final ScanStep step;
  final String? fileName;
  final String? extractedText;
  final String? scanToken;
  final String? encryptedToken;
  final String? unlockedCodeUsed;
  final AnalysisResult? analysisResult;
  final ImprovedCV? rewrittenCv;
  final String? errorMessage;

  const CvScanState({
    this.step = ScanStep.idle,
    this.fileName,
    this.extractedText,
    this.scanToken,
    this.encryptedToken,
    this.unlockedCodeUsed,
    this.analysisResult,
    this.rewrittenCv,
    this.errorMessage,
  });

  bool get isBusy =>
      step == ScanStep.parsingPdf ||
      step == ScanStep.analyzingAts ||
      step == ScanStep.rewriting;

  CvScanState copyWith({
    ScanStep? step,
    String? fileName,
    String? extractedText,
    String? scanToken,
    String? encryptedToken,
    String? unlockedCodeUsed,
    AnalysisResult? analysisResult,
    ImprovedCV? rewrittenCv,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CvScanState(
      step: step ?? this.step,
      fileName: fileName ?? this.fileName,
      extractedText: extractedText ?? this.extractedText,
      scanToken: scanToken ?? this.scanToken,
      encryptedToken: encryptedToken ?? this.encryptedToken,
      unlockedCodeUsed: unlockedCodeUsed ?? this.unlockedCodeUsed,
      analysisResult: analysisResult ?? this.analysisResult,
      rewrittenCv: rewrittenCv ?? this.rewrittenCv,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CvScanNotifier extends StateNotifier<CvScanState> {
  final ApiClient _apiClient;
  final Ref _ref;

  CvScanNotifier(this._apiClient, this._ref) : super(const CvScanState());

  /// Upload and scan a real PDF file
  Future<void> scanPdfFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    state = state.copyWith(
      step: ScanStep.parsingPdf,
      fileName: fileName,
      clearError: true,
    );

    try {
      final parsed = await _apiClient.parsePdfBytes(
        bytes: bytes,
        fileName: fileName,
      );

      state = state.copyWith(
        step: ScanStep.analyzingAts,
        extractedText: parsed.text,
      );

      final analyzed = await _apiClient.analyzeCvText(
        text: parsed.text,
        fileName: parsed.fileName,
        hasPhoto: parsed.hasPhoto,
      );

      state = state.copyWith(
        step: ScanStep.completed,
        scanToken: analyzed.scanToken,
        encryptedToken: analyzed.encryptedToken,
        analysisResult: analyzed.result,
      );

      // Sync scan result with Score History, scan-verified quests & Skill Gap
      await _ref.read(careerProvider.notifier).recordScanResult(
            analyzed.result,
            scanToken: analyzed.scanToken,
          );
    } catch (e) {
      state = state.copyWith(
        step: ScanStep.idle,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// 1-Tap Instant Demo Scan (Supports both 'id' Bahasa Indonesia and 'en' English sample CVs)
  Future<void> runSampleDemoScan({String language = 'id'}) async {
    final isId = language == 'id';
    final demoFile = isId ? 'CV_Budi_Santoso_ID.pdf' : 'Resume_Budi_Santoso_EN.pdf';
    final sampleText = isId ? ApiConstants.sampleCvTextId : ApiConstants.sampleCvTextEn;

    state = state.copyWith(
      step: ScanStep.analyzingAts,
      fileName: demoFile,
      extractedText: sampleText,
      clearError: true,
    );

    try {
      await Future.delayed(const Duration(milliseconds: 900));
      final analyzed = await _apiClient.analyzeCvText(
        text: sampleText,
        fileName: demoFile,
      );

      state = state.copyWith(
        step: ScanStep.completed,
        scanToken: analyzed.scanToken,
        encryptedToken: analyzed.encryptedToken,
        analysisResult: analyzed.result,
      );

      await _ref.read(careerProvider.notifier).recordScanResult(
            analyzed.result,
            scanToken: analyzed.scanToken,
          );
    } catch (e) {
      state = state.copyWith(
        step: ScanStep.idle,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Unlock full paid solutions & Before/After examples using VIP Access Code
  Future<bool> unlockFullReport(String accessCode) async {
    if (state.analysisResult == null) return false;
    state = state.copyWith(clearError: true);

    try {
      final unlockedResult = await _apiClient.unlockAnalysis(
        scanToken: state.scanToken ?? 'scn_local',
        encryptedToken: state.encryptedToken ?? '',
        accessCode: accessCode,
        currentText: state.extractedText ?? ApiConstants.sampleCvText,
        fileName: state.fileName ?? 'Resume.pdf',
      );

      state = state.copyWith(
        analysisResult: unlockedResult,
        unlockedCodeUsed: accessCode.trim().toUpperCase(),
      );

      // Sync unlocked missing keywords with Skill Gap & unlock badge
      await _ref.read(careerProvider.notifier).recordScanResult(
            unlockedResult,
            scanToken: state.scanToken,
            isUnlockAction: true,
          );
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Generate Zero-Hallucination AI Resume Rewrite
  Future<void> generateAiRewrite({String? codeOverride}) async {
    final codeToUse =
        codeOverride ?? state.unlockedCodeUsed ?? ApiConstants.defaultVipCode;

    state = state.copyWith(step: ScanStep.rewriting, clearError: true);

    try {
      final rewritten = await _apiClient.rewriteCv(
        scanToken: state.scanToken ?? 'scn_local',
        text: state.extractedText ?? ApiConstants.sampleCvText,
        accessCode: codeToUse,
        fileName: state.fileName ?? 'Resume.pdf',
      );

      state = state.copyWith(
        step: ScanStep.completed,
        rewrittenCv: rewritten,
      );

      // Save rewritten CV as base living CV & unlock STAR Storyteller toast badge
      _ref.read(careerProvider.notifier).setLatestRewrittenCv(rewritten);
    } catch (e) {
      state = state.copyWith(
        step: ScanStep.completed,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void updateRewrittenCvFromWins(ImprovedCV updatedCv) {
    state = state.copyWith(rewrittenCv: updatedCv);
  }

  void resetScanner() {
    state = const CvScanState();
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final cvScanProvider = StateNotifierProvider<CvScanNotifier, CvScanState>((ref) {
  final client = ref.watch(apiClientProvider);
  return CvScanNotifier(client, ref);
});

