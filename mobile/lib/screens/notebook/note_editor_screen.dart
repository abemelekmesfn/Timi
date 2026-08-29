import 'package:flutter/material.dart';

import '../../l10n/app_locale.dart';
import '../../models/note_model.dart';
import '../../services/note_service.dart';

class NoteEditorScreen extends StatefulWidget {
  final NoteModel? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController title;
  late final TextEditingController content;

  bool pinned = false;

  @override
  void initState() {
    super.initState();

    title = TextEditingController(text: widget.note?.title ?? "");

    content = TextEditingController(text: widget.note?.content ?? "");

    pinned = widget.note?.pinned ?? false;
  }

  Future<void> save() async {
    final note = NoteModel(
      id: widget.note?.id ?? "",
      title: title.text,
      content: content.text,
      pinned: pinned,
      createdBy: "",
      updatedAt: "",
    );

    try {
      if (widget.note == null) {
        await NoteService().createNote(note);
      } else {
        await NoteService().updateNote(note);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context, "noteSaved"))),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${S.of(context, "error")}: $e")),
        );
      }
    }
  }

  Future<void> remove() async {
    if (widget.note == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(S.of(context, "deleteNote")),
        content: Text(S.of(context, "cannotUndo")),
        actions: [
          TextButton(
            child: Text(S.of(context, "cancel")),
            onPressed: () => Navigator.pop(context, false),
          ),
          FilledButton(
            child: Text(S.of(context, "delete")),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await NoteService().deleteNote(widget.note!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context, "noteDeleted"))),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${S.of(context, "error")}: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.note != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? S.of(context, "editNote") : S.of(context, "newNote")),
        actions: [
          IconButton(
            icon: Icon(pinned ? Icons.push_pin : Icons.push_pin_outlined),
            onPressed: () {
              setState(() {
                pinned = !pinned;
              });
            },
          ),
          if (editing)
            IconButton(icon: const Icon(Icons.delete), onPressed: remove),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            TextField(
              controller: title,
              decoration: InputDecoration(hintText: S.of(context, "titleOptional")),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: content,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: S.of(context, "writeNote"),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: save, child: Text(S.of(context, "save"))),
          ],
        ),
      ),
    );
  }
}
