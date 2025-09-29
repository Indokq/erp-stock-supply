import 'dart:async';
import 'dart:io';

import 'package:barcode_scanner/scanbot_barcode_sdk_v2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BarcodeScanResult {
  BarcodeScanResult._({
    required this.operationResult,
    this.barcode,
    this.message,
  });

  factory BarcodeScanResult.success(String code) => BarcodeScanResult._(
        operationResult: OperationResult.SUCCESS,
        barcode: code,
      );

  factory BarcodeScanResult.canceled() => BarcodeScanResult._(
        operationResult: OperationResult.CANCELED,
      );

  factory BarcodeScanResult.error(String? message) => BarcodeScanResult._(
        operationResult: OperationResult.ERROR,
        message: message,
      );

  final OperationResult operationResult;
  final String? barcode;
  final String? message;

  bool get isSuccess =>
      operationResult == OperationResult.SUCCESS && barcode != null && barcode!.isNotEmpty;

  bool get isCanceled => operationResult == OperationResult.CANCELED;
}

class BarcodeScannerService {
  BarcodeScannerService._();

  static final BarcodeScannerService instance = BarcodeScannerService._();

  bool _initialized = false;
  bool _initializing = false;

  bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<bool> _ensureInitialized() async {
    if (!isSupported) {
      return false;
    }
    if (_initialized) {
      return true;
    }
    if (_initializing) {
      // Avoid concurrent initialization attempts.
      while (_initializing) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      return _initialized;
    }

    _initializing = true;
    try {
      const licenseKey = String.fromEnvironment('SCANBOT_LICENSE_KEY');
      final config = ScanbotSdkConfig(
        licenseKey: licenseKey.isEmpty ? null : licenseKey,
        loggingEnabled: kDebugMode,
      );
      await ScanbotBarcodeSdk.initScanbotSdk(config);
      _initialized = true;
      return true;
    } catch (_) {
      _initialized = false;
      return false;
    } finally {
      _initializing = false;
    }
  }

  Future<BarcodeScanResult> scanBarcode() async {
    if (!isSupported) {
      return BarcodeScanResult.error('Barcode scanner hanya tersedia di perangkat mobile.');
    }
    final ready = await _ensureInitialized();
    if (!ready) {
      return BarcodeScanResult.error('Gagal menginisialisasi barcode scanner.');
    }

    try {
      final result = await ScanbotBarcodeSdk.startBarcodeScanner(
        BarcodeScannerConfiguration(),
      );

      switch (result.operationResult) {
        case OperationResult.SUCCESS:
          final items = result.value?.items ?? <BarcodeItem>[];
          final code = items
              .map((item) => item.text.trim())
              .firstWhere((value) => value.isNotEmpty, orElse: () => '');
          if (code.isEmpty) {
            return BarcodeScanResult.error('Barcode tidak terbaca.');
          }
          return BarcodeScanResult.success(code);
        case OperationResult.CANCELED:
          return BarcodeScanResult.canceled();
        case OperationResult.ERROR:
        default:
          return BarcodeScanResult.error(result.message);
      }
    } on PlatformException catch (e) {
      return BarcodeScanResult.error(e.message);
    } catch (e) {
      return BarcodeScanResult.error(e.toString());
    }
  }
}
