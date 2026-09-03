import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/count_badge.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import '../controllers/community_controller.dart';

class CommunityView extends GetView<CommunityController> {
  const CommunityView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.surface,
        appBar: const DarkTopBar(title: 'Community', showBack: true),
        body: Column(children: [
          Obx(() => Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8),
              child: Row(children: [
                _tab('Group', 0, Icons.groups_outlined),
                _tab('Members', 1, Icons.people_outline),
              ]))),
          Expanded(
              child: Obx(() =>
                  controller.tabIndex.value == 0 ? _group() : _members())),
        ]),
      );

  Widget _tab(String text, int index, IconData icon) => Expanded(
          child: InkWell(
        onTap: () {
          controller.tabIndex.value = index;
          if (index == 0) controller.markGroupRead();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
                color: controller.tabIndex.value == index
                    ? AppColors.primary
                    : Colors.white,
                borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon,
                  size: 18,
                  color: controller.tabIndex.value == index
                      ? Colors.white
                      : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(text,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: controller.tabIndex.value == index
                          ? Colors.white
                          : AppColors.textSecondary))
            ])),
      ));

  Widget _group() => Column(children: [
        Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: controller.groupStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary));
                  }
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Could not load group messages'));
                  }
                  final rows = snapshot.data ?? [];
                  if (rows.isEmpty) {
                    return const Center(
                        child: Text('Start the community conversation'));
                  }
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => controller.markGroupRead());
                  return ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: rows.length,
                      reverse: true,
                      itemBuilder: (_, i) {
                        final msg = rows[i];
                        final mine = msg['sender_id'] == controller.myId;
                        final person =
                            controller.member(msg['sender_id'] as String);
                        return Align(
                            alignment: mine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                                constraints:
                                    const BoxConstraints(maxWidth: 300),
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                    color:
                                        mine ? AppColors.primary : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: mine
                                        ? null
                                        : Border.all(
                                            color: AppColors.borderColor)),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (!mine)
                                        Text(
                                            person?['name']?.toString() ??
                                                'Member',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.primary)),
                                      Text(msg['text']?.toString() ?? '',
                                          style: TextStyle(
                                              color: mine
                                                  ? Colors.white
                                                  : AppColors.textPrimary))
                                    ])));
                      });
                })),
        Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
            child: Row(children: [
              Expanded(
                  child: TextField(
                      controller: controller.messageController,
                      maxLength: 2000,
                      decoration: const InputDecoration(
                          hintText: 'Message everyone...',
                          counterText: '',
                          filled: true,
                          fillColor: AppColors.surface))),
              const SizedBox(width: 8),
              IconButton.filled(
                  onPressed: controller.sendGroupMessage,
                  icon: const Icon(Icons.send))
            ])),
      ]);

  Widget _members() => Obx(() => controller.isLoading.value
      ? const Center(child: CircularProgressIndicator())
      : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: controller.members.length,
          itemBuilder: (_, i) {
            final m = controller.members[i];
            final mine = m['id'] == controller.myId;
            return Card(
                color: Colors.white,
                surfaceTintColor: Colors.white,
                child: ListTile(
                    onTap: () => _profile(m),
                    leading: UserAvatar(
                        initials: _initials(m['name']?.toString() ?? '?'),
                        imageUrl: m['avatar_url'] as String?,
                        size: 44,
                        color: AppColors.cardBlue),
                    title: Text(m['name']?.toString() ?? 'Member',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(m['role'] == 'admin'
                        ? 'Administrator'
                        : 'Active member'),
                    trailing: mine
                        ? const Text('You')
                        : CountBadge(
                            count: (m['unread_count'] as num?)?.toInt() ?? 0,
                            child: const Icon(Icons.chevron_right))));
          }));

  void _profile(Map<String, dynamic> m) => Get.bottomSheet(Container(
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        UserAvatar(
            initials: _initials(m['name']?.toString() ?? '?'),
            imageUrl: m['avatar_url'] as String?,
            size: 72,
            color: AppColors.cardBlue),
        const SizedBox(height: 12),
        Text(m['name']?.toString() ?? 'Member',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        Text(
            m['role'] == 'admin'
                ? 'Foundation Administrator'
                : 'Active foundation member',
            style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text('Joined ${m['joined_at']?.toString().split('T').first ?? '-'}',
            style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
        if (m['id'] != controller.myId) ...[
          const SizedBox(height: 18),
          SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                  onPressed: () {
                    Get.back();
                    Get.toNamed(
                        AuthService.to.isAdmin
                            ? AppRoutes.ADMIN_CHAT_DETAIL
                            : AppRoutes.USER_DIRECT_CHAT,
                        arguments: UserModel(
                            id: m['id'],
                            name: m['name'] ?? 'Member',
                            email: '',
                            phone: '',
                            role: m['role'] ?? 'user',
                            status: 'active',
                            monthlyAmount: 0,
                            totalSaved: 0,
                            dues: 0,
                            avatarUrl: m['avatar_url'],
                            joinedAt: DateTime.tryParse(
                                    m['joined_at']?.toString() ?? '') ??
                                DateTime.now()));
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Private message')))
        ]
      ]))));

  String _initials(String name) {
    final p = name.trim().split(RegExp(r'\s+'));
    return p
        .take(2)
        .where((e) => e.isNotEmpty)
        .map((e) => e[0])
        .join()
        .toUpperCase();
  }
}
