import '../models/note_model.dart';
import 'api/api_service.dart';

class NoteService {
  Future<List<NoteModel>> getNotes() async {
    final res = await ApiService.dio.get("/notebook/");

    return (res.data as List).map((e) => NoteModel.fromJson(e)).toList();
  }

  Future<void> createNote(NoteModel note) async {
    await ApiService.dio.post("/notebook/", data: note.toJson());
  }

  Future<void> updateNote(NoteModel note) async {
    await ApiService.dio.put("/notebook/${note.id}/", data: note.toJson());
  }

  Future<void> deleteNote(String id) async {
    await ApiService.dio.delete("/notebook/$id/");
  }
}
