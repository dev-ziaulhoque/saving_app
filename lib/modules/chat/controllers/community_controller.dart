import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/services/badge_service.dart';

class CommunityController extends GetxController {
  final tabIndex = 0.obs;
  final members = <Map<String, dynamic>>[].obs;
  final messageController = TextEditingController();
  final isLoading = false.obs;
  final client = Supabase.instance.client;
  Worker? _badgeWorker;

  String get myId => client.auth.currentUser?.id ?? '';

  @override
  void onInit() {
    super.onInit();
    loadMembers();
    markGroupRead();
    _badgeWorker = ever<int>(BadgeService.to.unreadChats, (_) => loadMembers());
  }

  Stream<List<Map<String, dynamic>>> groupStream() => client
      .from('group_messages')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((rows) => rows.map(Map<String, dynamic>.from).toList());

  Future<void> loadMembers() async {
    isLoading.value = true;
    try {
      final data = await client.rpc('get_community_members');
      members.assignAll(
          (data as List).map((e) => Map<String, dynamic>.from(e as Map)));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendGroupMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;
    messageController.clear();
    await client
        .from('group_messages')
        .insert({'sender_id': myId, 'text': text});
  }

  Future<void> markGroupRead() async {
    await client.rpc('mark_group_messages_read');
    await BadgeService.to.refresh();
  }

  Map<String, dynamic>? member(String id) {
    for (final item in members) {
      if (item['id'] == id) return item;
    }
    return null;
  }

  @override
  void onClose() {
    _badgeWorker?.dispose();
    messageController.dispose();
    super.onClose();
  }
}
