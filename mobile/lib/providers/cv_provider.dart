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
      );

      state = state.copyWith(
        step: ScanStep.completed,
        scanToken: analyzed.scanToken,
        encryptedToken: analyzed.encryptedToken,
        analysisResult: analyzed.result,
      );

      // Award +75 XP & unlock "ATS Challenger" badge in Career Companion
      _ref.read(careerProvider.notifier).recordAtsMilestone(
            atsScore: analyzed.result.overallScore,
            questIdToComplete: 'q_scan_cv',
            badgeIdToUnlock: 'b_ats_scanned',
            bonusXp: 75,
          );
    } catch (e) {
      state = state.copyWith(
        step: ScanStep.idle,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// 1-Tap Instant Demo Scan using sample Indonesian CV
  Future<void> runSampleDemoScan() async {
    const demoFile = 'Resume_Budi_Santoso.pdf';
    state = state.copyWith(
      step: ScanStep.analyzingAts,
      fileName: demoFile,
      extractedText: ApiConstants.sampleCvText,
      clearError: true,
    );

    try {
      await Future.delayed(const Duration(milliseconds: 900));
      final analyzed = await _apiClient.analyzeCvText(
        text: ApiConstants.sampleCvText,
        fileName: demoFile,
      );

      state = state.copyWith(
        step: ScanStep.completed,
        scanToken: analyzed.scanToken,
        encryptedToken: analyzed.encryptedToken,
        analysisResult: analyzed.result,
      );

      _ref.read(careerProvider.notifier).recordAtsMilestone(
            atsScore: analyzed.result.overallScore,
            questIdToComplete: 'q_scan_cv',
            badgeIdToUnlock: 'b_ats_scanned',
            bonusXp: 75,
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

      // Award +120 XP & unlock "Zero-Bias Architect" badge
      _ref.read(careerProvider.notifier).recordAtsMilestone(
            badgeIdToUnlock: 'b_vip_unlocked',
            bonusXp: 120,
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

      // Award +150 XP & complete STAR Rewrite quest
      _ref.read(careerProvider.notifier).recordAtsMilestone(
            questIdToComplete: 'q_star_rewrite',
            badgeIdToUnlock: 'b_cv_rewritten',
            bonusXp: 150,
          );
    } catch (e) {
      state = state.copyWith(
        step: ScanStep.completed,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
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

