import '../../models/selected_file.dart';
import '../utils/app_exception.dart';

Future<void> openDocument(SelectedFile file) async => throw const AppException(
  'Bu platformda dosyayı indirip uygun uygulamayla açın.',
);
