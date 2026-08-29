import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_locale.dart';
import '../../providers/note_provider.dart';
import '../../widgets/note_tile.dart';
import 'note_editor_screen.dart';

class NotebookScreen extends ConsumerWidget {
  const NotebookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(noteProvider);

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, "notebook"))),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NoteEditorScreen()),
          );

          ref.invalidate(noteProvider);
        },
      ),
      body: notes.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(child: Text(S.of(context, "noNotes")));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              return NoteTile(
                note: list[i],
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NoteEditorScreen(note: list[i]),
                    ),
                  );

                  ref.invalidate(noteProvider);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(S.of(context, "error"))),
      ),
    );
  }
}
