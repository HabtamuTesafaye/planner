import 'package:flutter/foundation.dart';

import '../../core/utils/dates.dart';

/// Where a lead is in the pipeline. Names match the database check.
enum ContactStatus {
  contacted('Contacted'),
  replied('Replied'),
  meeting('Meeting'),
  proposal('Proposal'),
  paid('Paid'),
  dead('Not now');

  const ContactStatus(this.label);

  final String label;

  static ContactStatus parse(String? v) =>
      values.firstWhere((s) => s.name == v, orElse: () => contacted);

  /// Finished leads (won or dropped) need no follow-up.
  bool get isClosed => this == paid || this == dead;
}

/// A business someone in the space reached out to.
@immutable
class Contact {
  const Contact({
    required this.id,
    required this.spaceId,
    required this.ownerId,
    required this.name,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.business = '',
    this.channel = '',
    this.nextFollowUp,
    this.price,
    this.notes = '',
  });

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
    id: json['id'] as String,
    spaceId: json['team_id'] as String,
    ownerId: json['owner_id'] as String?,
    name: json['name'] as String,
    business: json['business'] as String? ?? '',
    channel: json['channel'] as String? ?? '',
    status: ContactStatus.parse(json['status'] as String?),
    nextFollowUp: switch (json['next_follow_up']) {
      final String d => Dates.fromDb(d),
      _ => null,
    },
    price: (json['price'] as num?)?.toDouble(),
    notes: json['notes'] as String? ?? '',
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
  );

  static const int maxName = 120;
  static const int maxBusiness = 120;
  static const int maxChannel = 40;
  static const int maxNotes = 2000;

  final String id;
  final String spaceId;
  final String? ownerId;
  final String name;
  final String business;
  final String channel;
  final ContactStatus status;
  final DateTime? nextFollowUp;
  final double? price;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Columns the app may write (matches the database's update grants).
  Map<String, dynamic> toEditableJson() => {
    'name': name.trim(),
    'business': business.trim(),
    'channel': channel.trim(),
    'status': status.name,
    'next_follow_up': nextFollowUp == null ? null : Dates.toDb(nextFollowUp!),
    'price': price,
    'notes': notes.trim(),
  };

  Map<String, dynamic> toInsertJson() => {
    'id': id,
    'team_id': spaceId,
    'owner_id': ownerId,
    ...toEditableJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is Contact &&
      other.id == id &&
      other.name == name &&
      other.business == business &&
      other.channel == channel &&
      other.status == status &&
      other.nextFollowUp == nextFollowUp &&
      other.price == price &&
      other.notes == notes;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    business,
    channel,
    status,
    nextFollowUp,
    price,
    notes,
  );
}
