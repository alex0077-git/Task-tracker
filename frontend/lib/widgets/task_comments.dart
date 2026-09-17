import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task_comment.dart';
import '../services/api_service.dart';

class TaskCommentsSection extends StatefulWidget {
  const TaskCommentsSection({super.key, required this.taskId});

  final int taskId;

  @override
  State<TaskCommentsSection> createState() => _TaskCommentsSectionState();
}

class _TaskCommentsSectionState extends State<TaskCommentsSection> {
  final _commentController = TextEditingController();
  List<TaskComment> _comments = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
    });
    final comments = await ApiService.instance.getComments(widget.taskId);
    if (!mounted) {
      return;
    }
    setState(() {
      _comments = comments;
      _isLoading = false;
    });
  }

  Future<void> _addComment() async {
    final body = _commentController.text.trim();
    if (body.isEmpty || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });
    final error = await ApiService.instance.addComment(widget.taskId, body);
    if (!mounted) {
      return;
    }
    if (error != null) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    _commentController.clear();
    setState(() {
      _isSaving = false;
    });
    await _loadComments();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comments',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_comments.isEmpty)
          Text(
            'No comments yet',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade700,
            ),
          )
        else
          for (final comment in _comments) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(comment.authorName),
              subtitle: Text(comment.body),
              trailing: Text(
                DateFormat('d MMM, HH:mm').format(comment.createdAt.toLocal()),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                enabled: !_isSaving,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Add a comment',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _isSaving ? null : _addComment,
              icon: const Icon(Icons.send),
              tooltip: 'Store comment',
            ),
          ],
        ),
      ],
    );
  }
}
