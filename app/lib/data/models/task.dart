// Farmer task (public.tasks).

class FarmTask {
  const FarmTask({
    required this.id,
    required this.profileId,
    this.fieldId,
    this.cropId,
    required this.title,
    this.description,
    this.dueDate,
    this.priority = 'medium',
    this.status = 'pending',
    this.completedAt,
  });

  final String id;
  final String profileId;
  final String? fieldId;
  final String? cropId;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String priority;
  final String status;
  final DateTime? completedAt;

  bool get isCompleted => status == 'done';

  factory FarmTask.fromJson(Map<String, dynamic> json) => FarmTask(
    id: json['id'] as String,
    profileId: json['profile_id'] as String,
    fieldId: json['field_id'] as String?,
    cropId: json['crop_id'] as String?,
    title: json['title'] as String? ?? '',
    description: json['description'] as String?,
    dueDate: json['due_date'] == null
        ? null
        : DateTime.parse(json['due_date'] as String),
    priority: json['priority'] as String? ?? 'medium',
    status: json['status'] as String? ?? 'pending',
    completedAt: json['completed_at'] == null
        ? null
        : DateTime.parse(json['completed_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'profile_id': profileId,
    'field_id': fieldId,
    'crop_id': cropId,
    'title': title,
    'description': description,
    'due_date': dueDate?.toIso8601String(),
    'priority': priority,
    'status': status,
    'completed_at': completedAt?.toIso8601String(),
  };

  FarmTask copyWith({
    String? title,
    String? Function()? description,
    DateTime? Function()? dueDate,
    String? priority,
    String? status,
  }) => FarmTask(
    id: id,
    profileId: profileId,
    fieldId: fieldId,
    cropId: cropId,
    title: title ?? this.title,
    description: description == null ? this.description : description(),
    dueDate: dueDate == null ? this.dueDate : dueDate(),
    priority: priority ?? this.priority,
    status: status ?? this.status,
    completedAt: completedAt,
  );
}
