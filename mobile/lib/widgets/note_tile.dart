import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../core/theme/app_colors.dart';

class NoteTile extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;

  const NoteTile({super.key, required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: Icon(
          note.pinned ? Icons.push_pin : Icons.note,
          color: note.pinned ? AppColors.primary : AppColors.warmGrey,
          size: 22,
        ),
        title: Text(
          note.title.isEmpty ? "Untitled" : note.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            note.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.warmGrey, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
