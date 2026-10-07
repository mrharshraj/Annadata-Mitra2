// Farmer task (todo_tasks).

class TodoTask {
  const TodoTask({
    required this.id,
    required this.farmerId,
    required this.title,
    this.description,
    this.dueDate,
    this.isCompleted = false,
  });

  final String id;
  final String farmerId;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final bool isCompleted;

  factory TodoTask.fromJson(Map<String, dynamic> json) => TodoTask(
    id: json['id'] as String,
    farmerId: json['farmer_id'] as String,
    title: json['title'] as String? ?? '',
    description: json['description'] as String?,
    dueDate: json['due_date'] == null
        ? null
        : DateTime.parse(json['due_date'] as String),
    isCompleted: json['is_completed'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'farmer_id': farmerId,
    'title': title,
    'description': description,
    'due_date': dueDate?.toIso8601String(),
    'is_completed': isCompleted,
  };

  TodoTask copyWith({bool? isCompleted, String? title}) => TodoTask(
    id: id,
    farmerId: farmerId,
    title: title ?? this.title,
    description: description,
    dueDate: dueDate,
    isCompleted: isCompleted ?? this.isCompleted,
  );
}
