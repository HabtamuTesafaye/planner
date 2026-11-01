import 'package:flutter/foundation.dart';

enum ProjectStatus {
  active,
  done;

  static ProjectStatus parse(String? v) =>
      v == 'done' ? ProjectStatus.done : ProjectStatus.active;
}

/// A project in a space. Its steps are [ProjectItem]s.
@immutable
class Project {
  const Project({
    required this.id,
    required this.spaceId,
    required this.name,
    required this.template,
    required this.status,
    required this.createdBy,
    required this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'] as String,
    spaceId: json['team_id'] as String,
    name: json['name'] as String,
    template: json['template'] as String? ?? 'blank',
    status: ProjectStatus.parse(json['status'] as String?),
    createdBy: json['created_by'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
  );

  static const int maxNameLength = 80;

  final String id;
  final String spaceId;
  final String name;

  /// Template key (see ProjectTemplate).
  final String template;
  final ProjectStatus status;
  final String? createdBy;
  final DateTime createdAt;

  bool get isDone => status == ProjectStatus.done;

  Map<String, dynamic> toInsertJson() => {
    'id': id,
    'team_id': spaceId,
    'name': name.trim(),
    'template': template,
    'status': status.name,
    'created_by': createdBy,
  };

  @override
  bool operator ==(Object other) =>
      other is Project &&
      other.id == id &&
      other.name == name &&
      other.template == template &&
      other.status == status;

  @override
  int get hashCode => Object.hash(id, name, template, status);
}

/// One step of a project's checklist.
@immutable
class ProjectItem {
  const ProjectItem({
    required this.id,
    required this.projectId,
    required this.spaceId,
    required this.title,
    required this.done,
    required this.position,
    required this.createdBy,
  });

  factory ProjectItem.fromJson(Map<String, dynamic> json) => ProjectItem(
    id: json['id'] as String,
    projectId: json['project_id'] as String,
    spaceId: json['team_id'] as String,
    title: json['title'] as String,
    done: json['done'] as bool? ?? false,
    position: (json['position'] as num?)?.toInt() ?? 0,
    createdBy: json['created_by'] as String?,
  );

  static const int maxTitleLength = 200;

  final String id;
  final String projectId;
  final String spaceId;
  final String title;
  final bool done;
  final int position;
  final String? createdBy;

  ProjectItem copyWith({bool? done}) => ProjectItem(
    id: id,
    projectId: projectId,
    spaceId: spaceId,
    title: title,
    done: done ?? this.done,
    position: position,
    createdBy: createdBy,
  );

  Map<String, dynamic> toInsertJson() => {
    'id': id,
    'project_id': projectId,
    'team_id': spaceId,
    'title': title.trim(),
    'done': done,
    'position': position,
    'created_by': createdBy,
  };

  @override
  bool operator ==(Object other) =>
      other is ProjectItem &&
      other.id == id &&
      other.title == title &&
      other.done == done &&
      other.position == position;

  @override
  int get hashCode => Object.hash(id, title, done, position);
}

/// Steps done / total, as 0..1 (0 for an empty project).
double projectProgress(Iterable<ProjectItem> items) {
  final list = items.toList();
  if (list.isEmpty) return 0;
  return list.where((i) => i.done).length / list.length;
}
