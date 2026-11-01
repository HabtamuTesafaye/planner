import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/dates.dart';
import '../app_exception.dart';
import '../models/contact.dart';
import '../supabase_client.dart';

/// The outreach pipeline of a space. Any member can add and edit; only the
/// creator or the space owner can delete (enforced by the database).
class ContactsRepository {
  const ContactsRepository(this._client);

  final SupabaseClient _client;

  Stream<List<Contact>> watchContacts(String spaceId) => _client
      .from('contacts')
      .stream(primaryKey: ['id'])
      .eq('team_id', spaceId)
      .map((rows) => rows.map(Contact.fromJson).toList(growable: false))
      .handleError((Object e, StackTrace s) => throw AppException.from(e, s));

  Future<void> add(Contact contact) =>
      _guard(() => _client.from('contacts').insert(contact.toInsertJson()));

  Future<void> update(Contact contact) => _guard(
    () => _client
        .from('contacts')
        .update(contact.toEditableJson())
        .eq('id', contact.id),
  );

  Future<void> setStatus(String id, ContactStatus status) => _guard(
    () => _client.from('contacts').update({'status': status.name}).eq('id', id),
  );

  /// "Followed up": sets the next date (null clears it).
  Future<void> setFollowUp(String id, DateTime? next) => _guard(
    () => _client
        .from('contacts')
        .update({'next_follow_up': next == null ? null : Dates.toDb(next)})
        .eq('id', id),
  );

  /// Returns false when the database refused (not the creator or owner).
  Future<bool> delete(String id) => _guard(() async {
    final rows = await _client
        .from('contacts')
        .delete()
        .eq('id', id)
        .select('id');
    return rows.isNotEmpty;
  });

  /// Contacts added in a space between two dates (for the Space tab).
  Future<List<Contact>> fetchAddedBetween(
    String spaceId,
    DateTime from,
    DateTime to,
  ) => _guard(() async {
    final rows = await _client
        .from('contacts')
        .select()
        .eq('team_id', spaceId)
        .gte('created_at', from.toUtc().toIso8601String())
        .lt('created_at', to.toUtc().toIso8601String());
    return rows.map(Contact.fromJson).toList(growable: false);
  });

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e, s) {
      throw AppException.from(e, s);
    }
  }
}

final contactsRepositoryProvider = Provider<ContactsRepository>(
  (ref) => ContactsRepository(ref.watch(supabaseClientProvider)),
);
