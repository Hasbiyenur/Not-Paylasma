import '../models/note_model.dart';
import '../models/selected_file.dart';

abstract class NoteRepository {
  Stream<void> get changes;
  Future<NotePage> query(NoteQuery query);
  Future<NoteModel?> getById(String id);
  Future<NoteModel> save(
    NoteDraft draft, {
    String? id,
    SelectedFile? file,
    void Function(double)? onProgress,
  });
  Future<void> delete(String id);
  Future<void> recordDownload(String id);
}
