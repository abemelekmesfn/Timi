import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note_model.dart';
import '../services/note_service.dart';

final noteProvider = FutureProvider<List<NoteModel>>((ref) async {
  return NoteService().getNotes();
});
