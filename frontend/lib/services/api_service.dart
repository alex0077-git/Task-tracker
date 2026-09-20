import '../data/database_helper.dart';
import '../data/password_hasher.dart';
import '../models/app_user.dart';
import '../models/task.dart';
import '../models/task_comment.dart';

/// Local SQLite API — same surface as the former Django-backed Dio client.
class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  AppUser? currentUser;

  bool get isManager => currentUser?.isManager ?? false;

  Future<void> _ensureCsrfToken() async {}

  Future<AppUser?> login(String username, String password) async {
    await _ensureCsrfToken();
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'users',
        where: 'username = ? COLLATE NOCASE',
        whereArgs: [username.trim()],
        limit: 1,
      );
      if (rows.isEmpty) {
        currentUser = null;
        return null;
      }
      final row = rows.first;
      if (!_asBool(row['is_active'], defaultValue: true)) {
        currentUser = null;
        return null;
      }
      final hash = row['password_hash'] as String? ?? '';
      if (!PasswordHasher.verify(password, hash)) {
        currentUser = null;
        return null;
      }
      currentUser = _userFromRow(row);
      return currentUser;
    } catch (_) {
      currentUser = null;
      return null;
    }
  }

  Future<void> logout() async {
    await _ensureCsrfToken();
    currentUser = null;
  }

  Future<List<AppUser>> getUsers() async {
    if (!_requireAuth() || !isManager) {
      return [];
    }
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'users',
        orderBy: 'username COLLATE NOCASE ASC',
      );
      return rows.map(_userFromRow).toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> createUser({
    required String username,
    required String password,
    required bool isStaff,
  }) async {
    if (!_requireAuth()) {
      return 'Not logged in';
    }
    if (!isManager) {
      return 'Only managers can perform this action.';
    }
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      return 'Username is required';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('users', {
        'username': trimmed,
        'password_hash': PasswordHasher.hash(password),
        'email': '',
        'is_manager': isStaff ? 1 : 0,
        'is_active': 1,
      });
      return null;
    } catch (error) {
      if (error.toString().contains('UNIQUE')) {
        return 'A user with that username already exists.';
      }
      return 'Could not create user';
    }
  }

  Future<List<Task>> getTasks({
    bool overdueOnly = false,
    String? searchQuery,
    String? statusFilter,
    String? priorityFilter,
    int? assigneeFilter,
  }) async {
    if (!_requireAuth()) {
      return [];
    }
    try {
      final db = await DatabaseHelper.instance.database;
      final where = <String>[];
      final args = <Object?>[];

      if (!isManager) {
        where.add('t.assignee_id = ?');
        args.add(currentUser!.id);
      }

      final trimmedSearch = searchQuery?.trim();
      if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
        // Matches Django title__istartswith
        where.add('t.title LIKE ? COLLATE NOCASE');
        args.add('$trimmedSearch%');
      }
      if (statusFilter != null && statusFilter.isNotEmpty) {
        where.add('t.status = ?');
        args.add(statusFilter);
      }
      if (priorityFilter != null && priorityFilter.isNotEmpty) {
        where.add('t.priority = ?');
        args.add(priorityFilter);
      }
      if (assigneeFilter != null) {
        where.add('t.assignee_id = ?');
        args.add(assigneeFilter);
      }
      if (overdueOnly) {
        where.add(
          "t.due_date < date('now', 'localtime') AND t.status != 'Completed'",
        );
      }

      final whereSql = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
      final rows = await db.rawQuery(
        '''
SELECT t.id, t.title, t.description, t.priority, t.status, t.due_date,
       t.assignee_id, t.created_at, t.updated_at,
       u.username AS assignee_name
FROM tasks t
LEFT JOIN users u ON u.id = t.assignee_id
$whereSql
ORDER BY t.created_at DESC
''',
        args,
      );
      return rows.map(_taskFromRow).toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> createTask(Task task) async {
    if (!_requireAuth()) {
      return 'Not logged in';
    }
    if (!isManager) {
      return 'Only managers can perform this action.';
    }
    final validation = _validateTaskFields(task);
    if (validation != null) {
      return validation;
    }
    try {
      final conflict = await _assignmentConflict(
        assigneeId: task.assignee,
        dueDate: _formatDate(task.dueDate),
        status: task.status,
      );
      if (conflict != null) {
        return conflict;
      }
      final db = await DatabaseHelper.instance.database;
      final now = _nowIso();
      await db.insert('tasks', {
        'title': task.title,
        'description': task.description,
        'priority': task.priority,
        'status': task.status,
        'due_date': _formatDate(task.dueDate),
        'assignee_id': task.assignee,
        'created_at': now,
        'updated_at': now,
      });
      return null;
    } catch (_) {
      return 'Could not save task';
    }
  }

  Future<String?> updateTask(Task task) async {
    if (task.id == null) {
      return 'Task is missing an id';
    }
    if (!_requireAuth()) {
      return 'Not logged in';
    }
    if (!isManager) {
      return 'Only managers can perform this action.';
    }
    final validation = _validateTaskFields(task);
    if (validation != null) {
      return validation;
    }
    try {
      final conflict = await _assignmentConflict(
        assigneeId: task.assignee,
        dueDate: _formatDate(task.dueDate),
        status: task.status,
        excludeTaskId: task.id,
      );
      if (conflict != null) {
        return conflict;
      }
      final db = await DatabaseHelper.instance.database;
      final updated = await db.update(
        'tasks',
        {
          'title': task.title,
          'description': task.description,
          'priority': task.priority,
          'status': task.status,
          'due_date': _formatDate(task.dueDate),
          'assignee_id': task.assignee,
          'updated_at': _nowIso(),
        },
        where: 'id = ?',
        whereArgs: [task.id],
      );
      if (updated == 0) {
        return 'Could not save task';
      }
      return null;
    } catch (_) {
      return 'Could not save task';
    }
  }

  Future<bool> deleteTask(int taskId) async {
    if (!_requireAuth() || !isManager) {
      return false;
    }
    try {
      final db = await DatabaseHelper.instance.database;
      final deleted = await db.delete(
        'tasks',
        where: 'id = ?',
        whereArgs: [taskId],
      );
      return deleted > 0;
    } catch (_) {
      return false;
    }
  }

  Future<String?> reassignTask(int taskId, int newAssigneeId) async {
    if (!_requireAuth()) {
      return 'Not logged in';
    }
    if (!isManager) {
      return 'Only managers can perform this action.';
    }
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'tasks',
        columns: ['due_date', 'status'],
        where: 'id = ?',
        whereArgs: [taskId],
        limit: 1,
      );
      if (rows.isEmpty) {
        return 'Could not reassign task';
      }
      final row = rows.first;
      final conflict = await _assignmentConflict(
        assigneeId: newAssigneeId,
        dueDate: row['due_date'] as String,
        status: row['status'] as String,
        excludeTaskId: taskId,
      );
      if (conflict != null) {
        return conflict;
      }
      final updated = await db.update(
        'tasks',
        {
          'assignee_id': newAssigneeId,
          'updated_at': _nowIso(),
        },
        where: 'id = ?',
        whereArgs: [taskId],
      );
      if (updated == 0) {
        return 'Could not reassign task';
      }
      return null;
    } catch (_) {
      return 'Could not reassign task';
    }
  }

  Future<bool> updateTaskStatus(int taskId, String newStatus) async {
    if (!_requireAuth()) {
      return false;
    }
    if (!_validStatuses.contains(newStatus)) {
      return false;
    }
    try {
      if (!await _canAccessTask(taskId)) {
        return false;
      }
      final db = await DatabaseHelper.instance.database;
      final updated = await db.update(
        'tasks',
        {
          'status': newStatus,
          'updated_at': _nowIso(),
        },
        where: 'id = ?',
        whereArgs: [taskId],
      );
      return updated > 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateTaskPriority(int taskId, String newPriority) async {
    if (!_requireAuth() || !isManager) {
      return false;
    }
    if (!_validPriorities.contains(newPriority)) {
      return false;
    }
    try {
      final db = await DatabaseHelper.instance.database;
      final updated = await db.update(
        'tasks',
        {
          'priority': newPriority,
          'updated_at': _nowIso(),
        },
        where: 'id = ?',
        whereArgs: [taskId],
      );
      return updated > 0;
    } catch (_) {
      return false;
    }
  }

  Future<List<TaskComment>> getComments(int taskId) async {
    if (!_requireAuth()) {
      return [];
    }
    try {
      if (!await _canAccessTask(taskId)) {
        return [];
      }
      final db = await DatabaseHelper.instance.database;
      final rows = await db.rawQuery(
        '''
SELECT c.id, c.body, c.created_at, u.username AS author_name
FROM task_comments c
LEFT JOIN users u ON u.id = c.author_id
WHERE c.task_id = ?
ORDER BY c.created_at ASC, c.id ASC
''',
        [taskId],
      );
      return rows.map(_commentFromRow).toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> addComment(int taskId, String body) async {
    if (!_requireAuth()) {
      return 'Not logged in';
    }
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return 'Comment cannot be empty.';
    }
    try {
      if (!await _canAccessTask(taskId)) {
        return 'Task not found';
      }
      final db = await DatabaseHelper.instance.database;
      await db.insert('task_comments', {
        'task_id': taskId,
        'author_id': currentUser!.id,
        'body': trimmed,
        'created_at': _nowIso(),
      });
      return null;
    } catch (_) {
      return 'Could not add comment';
    }
  }

  bool _requireAuth() => currentUser != null;

  Future<bool> _canAccessTask(int taskId) async {
    final db = await DatabaseHelper.instance.database;
    final where = isManager ? 'id = ?' : 'id = ? AND assignee_id = ?';
    final args = isManager
        ? <Object?>[taskId]
        : <Object?>[taskId, currentUser!.id];
    final rows = await db.query(
      'tasks',
      columns: ['id'],
      where: where,
      whereArgs: args,
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<String?> _assignmentConflict({
    required int assigneeId,
    required String dueDate,
    required String status,
    int? excludeTaskId,
  }) async {
    if (status == 'Completed') {
      return null;
    }
    final db = await DatabaseHelper.instance.database;
    final where = StringBuffer(
      "assignee_id = ? AND due_date = ? AND status != 'Completed'",
    );
    final args = <Object?>[assigneeId, dueDate];
    if (excludeTaskId != null) {
      where.write(' AND id != ?');
      args.add(excludeTaskId);
    }
    final rows = await db.query(
      'tasks',
      columns: ['id'],
      where: where.toString(),
      whereArgs: args,
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return 'This employee already has an incomplete task due on that date.';
    }
    return null;
  }

  String? _validateTaskFields(Task task) {
    if (!_validStatuses.contains(task.status)) {
      return 'Invalid status value';
    }
    if (!_validPriorities.contains(task.priority)) {
      return 'Invalid priority value';
    }
    if (task.title.trim().isEmpty) {
      return 'Title is required';
    }
    return null;
  }

  static const _validStatuses = {'To Do', 'In Progress', 'Completed'};
  static const _validPriorities = {'Low', 'Medium', 'High'};

  AppUser _userFromRow(Map<String, dynamic> row) {
    final manager = _asBool(row['is_manager']);
    return AppUser(
      id: row['id'] as int,
      username: row['username'] as String,
      email: row['email'] as String? ?? '',
      isStaff: manager,
      isManagerFlag: manager,
      isActive: _asBool(row['is_active'], defaultValue: true),
      role: manager ? 'admin' : 'employee',
    );
  }

  Task _taskFromRow(Map<String, dynamic> row) {
    final dueDate = DateTime.parse(row['due_date'] as String);
    final status = row['status'] as String;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final isOverdue =
        status != 'Completed' && dueDate.isBefore(todayDate);

    return Task(
      id: row['id'] as int,
      title: row['title'] as String,
      description: row['description'] as String? ?? '',
      priority: row['priority'] as String,
      status: status,
      dueDate: dueDate,
      assignee: row['assignee_id'] as int,
      assigneeName: row['assignee_name'] as String? ?? '',
      isOverdue: isOverdue,
    );
  }

  TaskComment _commentFromRow(Map<String, dynamic> row) {
    return TaskComment(
      id: row['id'] as int,
      body: row['body'] as String,
      authorName: row['author_name'] as String? ?? '',
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  static bool _asBool(Object? value, {bool defaultValue = false}) {
    if (value is bool) {
      return value;
    }
    if (value is int) {
      return value != 0;
    }
    return defaultValue;
  }

  static String _nowIso() => DateTime.now().toIso8601String();

  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
