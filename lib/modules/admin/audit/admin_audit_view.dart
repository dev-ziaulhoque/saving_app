import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/audit_log_model.dart';
import '../../../data/services/supabase_service.dart';

class AdminAuditController extends GetxController {
  final isLoading = false.obs;
  final logs = <AuditLogModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchLogs();
  }

  Future<void> fetchLogs() async {
    isLoading.value = true;
    try {
      logs.value = await SupabaseService.to.getAuditLogs();
    } catch (error) {
      Get.snackbar('Error', 'Could not load audit logs: $error');
    } finally {
      isLoading.value = false;
    }
  }
}

class AdminAuditBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminAuditController>(() => AdminAuditController());
  }
}

class AdminAuditView extends GetView<AdminAuditController> {
  const AdminAuditView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const DarkTopBar(title: 'Audit Logs', showBack: true),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.logs.isEmpty) {
          return const EmptyState(
            icon: '📋',
            title: 'No audit activity',
            subtitle: 'Admin and financial changes will appear here.',
          );
        }
        return RefreshIndicator(
          onRefresh: controller.fetchLogs,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final log = controller.logs[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(_iconFor(log.action), size: 18),
                  ),
                  title:
                      Text('${log.action.toUpperCase()} · ${log.entityType}'),
                  subtitle: Text(
                    '${log.entityId ?? 'No entity id'}\n'
                    '${DateFormat('dd MMM yyyy, hh:mm a').format(log.createdAt)}',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        );
      }),
    );
  }

  IconData _iconFor(String action) {
    switch (action) {
      case 'insert':
        return Icons.add;
      case 'delete':
        return Icons.delete_outline;
      default:
        return Icons.edit_outlined;
    }
  }
}
