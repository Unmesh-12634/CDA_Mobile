import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AppUpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String releaseTitle;
  final String releaseNotes;
  final String downloadUrl;

  const AppUpdateInfo({
    this.hasUpdate = false,
    this.currentVersion = '1.0.0',
    this.latestVersion = '1.0.0',
    this.releaseTitle = '',
    this.releaseNotes = '',
    this.downloadUrl = '',
  });
}

enum UpdateStatus { idle, checking, updateAvailable, downloading, readyToInstall, upToDate, error }

class UpdateState {
  final UpdateStatus status;
  final AppUpdateInfo? updateInfo;
  final double downloadProgress; // 0.0 to 1.0
  final String? errorMessage;

  const UpdateState({
    this.status = UpdateStatus.idle,
    this.updateInfo,
    this.downloadProgress = 0.0,
    this.errorMessage,
  });

  UpdateState copyWith({
    UpdateStatus? status,
    AppUpdateInfo? updateInfo,
    double? downloadProgress,
    String? errorMessage,
  }) {
    return UpdateState(
      status: status ?? this.status,
      updateInfo: updateInfo ?? this.updateInfo,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      errorMessage: errorMessage,
    );
  }
}

class AppUpdateNotifier extends StateNotifier<UpdateState> {
  final Dio _dio = Dio();

  AppUpdateNotifier() : super(const UpdateState());

  /// Checks GitHub Releases for the latest APK version
  Future<AppUpdateInfo> checkForUpdate({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(status: UpdateStatus.checking, errorMessage: null);
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVer = packageInfo.version;

      // Query GitHub latest release for CDA_Mobile
      final response = await _dio.get(
        'https://api.github.com/repos/Unmesh-12634/CDA_Mobile/releases/latest',
        options: Options(
          headers: {'Accept': 'application/vnd.github.v3+json'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final tagName = data['tag_name']?.toString().replaceAll('v', '').trim() ?? '1.0.0';
        final releaseTitle = data['name']?.toString() ?? 'New CDA Update';
        final releaseNotes = data['body']?.toString() ?? 'Performance improvements and bug fixes.';

        // Find APK asset URL
        String apkUrl = '';
        final assets = data['assets'] as List<dynamic>? ?? [];
        for (final asset in assets) {
          final name = asset['name']?.toString().toLowerCase() ?? '';
          if (name.endsWith('.apk')) {
            apkUrl = asset['browser_download_url']?.toString() ?? '';
            break;
          }
        }

        // Fallback to direct raw release APK link if not in assets
        if (apkUrl.isEmpty) {
          apkUrl = 'https://github.com/Unmesh-12634/CDA_Mobile/releases/latest/download/app-release.apk';
        }

        final isNewer = _isVersionNewer(latest: tagName, current: currentVer);

        final updateInfo = AppUpdateInfo(
          hasUpdate: isNewer,
          currentVersion: currentVer,
          latestVersion: tagName,
          releaseTitle: releaseTitle,
          releaseNotes: releaseNotes,
          downloadUrl: apkUrl,
        );

        state = state.copyWith(
          status: isNewer ? UpdateStatus.updateAvailable : UpdateStatus.upToDate,
          updateInfo: updateInfo,
        );

        return updateInfo;
      } else {
        // Up to date fallback
        final info = AppUpdateInfo(
          hasUpdate: false,
          currentVersion: currentVer,
          latestVersion: currentVer,
        );
        state = state.copyWith(status: UpdateStatus.upToDate, updateInfo: info);
        return info;
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Check update notice: $e');
      const info = AppUpdateInfo(hasUpdate: false);

      state = state.copyWith(
        status: silent ? UpdateStatus.idle : UpdateStatus.error,
        errorMessage: 'Unable to check for updates: $e',
      );
      return info;
    }
  }

  /// Downloads the latest APK with live percentage and triggers native installation
  Future<bool> downloadAndInstall({String? customUrl}) async {
    final primaryUrl = customUrl ?? state.updateInfo?.downloadUrl;
    final List<String> candidateUrls = [
      if (primaryUrl != null && primaryUrl.isNotEmpty) primaryUrl,
      'https://github.com/Unmesh-12634/CDA_Mobile/releases/latest/download/app-release.apk',
    ];

    try {
      state = state.copyWith(status: UpdateStatus.downloading, downloadProgress: 0.01);

      // Check Android install packages permission
      if (Platform.isAndroid) {
        final installPermission = await Permission.requestInstallPackages.status;
        if (!installPermission.isGranted) {
          await Permission.requestInstallPackages.request();
        }
      }

      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/cda_update.apk';

      // Delete existing stale update file if present
      final existing = File(savePath);
      if (await existing.exists()) {
        await existing.delete();
      }

      bool downloadSucceeded = false;
      dynamic lastError;

      // Try candidate download mirrors sequentially
      for (final downloadUrl in candidateUrls) {
        try {
          debugPrint('[AppUpdateService] Attempting download from: $downloadUrl');
          await _dio.download(
            downloadUrl,
            savePath,
            options: Options(
              followRedirects: true,
              maxRedirects: 5,
              receiveTimeout: const Duration(minutes: 3),
            ),
            onReceiveProgress: (received, total) {
              if (total > 0) {
                final progress = (received / total).clamp(0.0, 1.0);
                state = state.copyWith(downloadProgress: progress);
              }
            },
          );

          final downloadedFile = File(savePath);
          if (await downloadedFile.exists() && await downloadedFile.length() > 500000) {
            downloadSucceeded = true;
            break;
          }
        } catch (e) {
          debugPrint('[AppUpdateService] Mirror $downloadUrl failed: $e. Trying next mirror...');
          lastError = e;
        }
      }

      if (!downloadSucceeded) {
        throw Exception('All download mirrors failed. Last error: $lastError');
      }

      state = state.copyWith(
        status: UpdateStatus.readyToInstall,
        downloadProgress: 1.0,
      );

      // Trigger Android Package Installer via OpenFilex
      final result = await OpenFilex.open(
        savePath,
        type: 'application/vnd.android.package-archive',
      );

      debugPrint('[AppUpdateService] OpenFilex result: ${result.type} - ${result.message}');
      return true;
    } catch (e) {
      debugPrint('[AppUpdateService] Download/Install error: $e');
      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage: 'Failed to download update. Please check internet connection or download from GitHub release.',
      );
      return false;
    }
  }

  /// Compares semantic versions accurately (e.g. 1.0.2 is not newer than 1.0.2+3)
  bool _isVersionNewer({required String latest, required String current}) {
    try {
      // Remove any 'v', tags, build numbers, or non-numeric characters except dots
      final cleanLatest = latest.replaceAll(RegExp(r'[^0-9.]'), '').split('.');
      final cleanCurrent = current.split('+').first.replaceAll(RegExp(r'[^0-9.]'), '').split('.');

      final lParts = cleanLatest.map((e) => int.tryParse(e) ?? 0).toList();
      final cParts = cleanCurrent.map((e) => int.tryParse(e) ?? 0).toList();

      final maxLen = lParts.length > cParts.length ? lParts.length : cParts.length;

      for (int i = 0; i < maxLen; i++) {
        final l = i < lParts.length ? lParts[i] : 0;
        final c = i < cParts.length ? cParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
    } catch (_) {}
    return false;
  }
}

final appUpdateProvider = StateNotifierProvider<AppUpdateNotifier, UpdateState>((ref) {
  return AppUpdateNotifier();
});
