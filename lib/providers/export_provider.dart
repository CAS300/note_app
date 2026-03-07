import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/export_service.dart';

/// Provider for the [ExportService].
final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});
