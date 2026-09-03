import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../controllers/foundation_report_controller.dart';

class FoundationReportView extends GetView<FoundationReportController> {
  const FoundationReportView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.surface,
        appBar: DarkTopBar(
            title: 'Live Foundation Statement',
            showBack: true,
            actions: [
              IconButton(
                  onPressed: () => controller.load(),
                  icon: const Icon(Icons.refresh, color: Colors.white)),
              IconButton(
                  onPressed: controller.downloadPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined,
                      color: Colors.white)),
            ]),
        floatingActionButton: controller.isAdmin
            ? FloatingActionButton.extended(
                onPressed: () => _actions(context),
                icon: const Icon(Icons.add),
                label: const Text('Accounting entry'))
            : null,
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final report = controller.report.value;
          if (report == null) {
            return const EmptyState(
                icon: '📊',
                title: 'Report unavailable',
                subtitle: 'Run the live-report database migration first.');
          }
          return RefreshIndicator(
            onRefresh: controller.load,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              const Text('All-time live statement',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              const Text(
                  'Approved payments and accounting entries update automatically.',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 14),
              _summaryGrid(report.summary),
              _section('Member savings & dues', report.members,
                  (r) => _memberCard(r)),
              _section(
                  'Investments & income', report.investments, _investmentCard),
              _section(
                  'Foundation expenses',
                  report.expenses,
                  (r) => _row(
                      r['title'] ?? '',
                      '${r['expense_date'] ?? ''} • ${r['category'] ?? ''}',
                      '- ৳${_money(r['amount'])}',
                      color: AppColors.error)),
              const SizedBox(height: 90),
            ]),
          );
        }),
      );

  Widget _summaryGrid(Map<String, dynamic> s) {
    final values = [
      ('Total required', s['total_required'], Icons.flag_outlined),
      ('Total collected', s['total_collected'], Icons.savings_outlined),
      ('Total due', s['total_due'], Icons.pending_actions_outlined),
      ('Total invested', s['total_invested'], Icons.account_balance_outlined),
      ('Total profit', s['total_profit'], Icons.trending_up),
      ('Total expense', s['total_expenses'], Icons.receipt_long_outlined),
      ('Foundation total', s['foundation_total'], Icons.paid_outlined),
      (
        'Available cash',
        s['available_cash'],
        Icons.account_balance_wallet_outlined
      ),
    ];
    return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.65,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: values
            .map((v) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderColor)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(v.$3, size: 18, color: AppColors.primary),
                      Text(v.$1,
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textSecondary)),
                      Text('৳${_money(v.$2)}',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800))
                    ])))
            .toList());
  }

  Widget _memberCard(Map<String, dynamic> r) => Card(
      child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Row(children: [
              const CircleAvatar(child: Icon(Icons.person_outline)),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(r['name']?.toString() ?? 'Member',
                      style: const TextStyle(fontWeight: FontWeight.w800))),
              Text('Due ৳${_money(r['due'])}',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: (r['due'] as num? ?? 0) > 0
                          ? AppColors.error
                          : AppColors.success))
            ]),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Paid ৳${_money(r['paid'])}'),
              Text('Required ৳${_money(r['required'])}')
            ]),
            const SizedBox(height: 5),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Monthly amount',
                  style:
                      TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text('৳${_money(r['monthly_amount'])}',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700))
            ]),
          ])));

  Widget _investmentCard(Map<String, dynamic> item) {
    final profits = (item['profits'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return Card(
        child: ExpansionTile(
      leading: const CircleAvatar(
          backgroundColor: AppColors.cardGreen,
          child: Icon(Icons.trending_up, color: Colors.white)),
      title: Text(item['title']?.toString() ?? 'Investment',
          style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(
          'Invested ৳${_money(item['amount'])}  •  Income ৳${_money(item['profit_total'])}'),
      children: [
        ListTile(
            dense: true,
            title: const Text('Investment date'),
            trailing: Text(item['invested_at']?.toString() ?? '')),
        if (profits.isEmpty)
          const ListTile(dense: true, title: Text('No income recorded yet')),
        ...profits.map((p) => ListTile(
            dense: true,
            leading:
                const Icon(Icons.add_circle_outline, color: AppColors.success),
            title: Text(DateFormat('MMMM yyyy')
                .format(DateTime.parse(p['profit_month'].toString()))),
            subtitle: Text(p['notes']?.toString() ?? ''),
            trailing: Text('+ ৳${_money(p['amount'])}',
                style: const TextStyle(
                    color: AppColors.success, fontWeight: FontWeight.w800)))),
        if (controller.isAdmin)
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                      onPressed: () => _profitDialog(
                          initialInvestmentId: item['id'].toString()),
                      icon: const Icon(Icons.add),
                      label: const Text('Add income/profit')))),
      ],
    ));
  }

  Widget _section(String title, List<Map<String, dynamic>> rows,
          Widget Function(Map<String, dynamic>) builder) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 22),
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 7),
        if (rows.isEmpty)
          const Card(
              child: Padding(
                  padding: EdgeInsets.all(14), child: Text('No entries')))
        else
          ...rows.map(builder)
      ]);

  Widget _row(String title, String subtitle, String trailing, {Color? color}) =>
      Card(
          child: ListTile(
              title: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(subtitle),
              trailing: Text(trailing,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: color ?? AppColors.textPrimary))));

  void _actions(BuildContext context) => showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
              child: Wrap(children: [
            ListTile(
                leading: const Icon(Icons.business_center_outlined),
                title: const Text('Add investment'),
                onTap: () {
                  Get.back();
                  _entryDialog('Investment', investment: true);
                }),
            ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Add expense'),
                onTap: () {
                  Get.back();
                  _entryDialog('Expense', investment: false);
                }),
          ])));

  void _entryDialog(String heading, {required bool investment}) {
    final title = TextEditingController();
    final amount = TextEditingController();
    final notes = TextEditingController();
    final category = TextEditingController(text: 'general');
    Get.dialog(AlertDialog(
        title: Text('Add $heading'),
        content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: title,
              decoration:
                  const InputDecoration(labelText: 'Title / description')),
          const SizedBox(height: 10),
          TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount')),
          if (!investment) ...[
            const SizedBox(height: 10),
            TextField(
                controller: category,
                decoration: const InputDecoration(labelText: 'Category'))
          ],
          const SizedBox(height: 10),
          TextField(
              controller: notes,
              decoration: const InputDecoration(labelText: 'Notes (optional)')),
        ])),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                final n = double.tryParse(amount.text);
                if (title.text.trim().isEmpty || n == null || n <= 0) {
                  Get.snackbar(
                      'Invalid data', 'Enter a title and valid amount.');
                  return;
                }
                if (investment) {
                  controller.addInvestment(
                      title.text.trim(), n, DateTime.now(), notes.text.trim());
                } else {
                  controller.addExpense(title.text.trim(), n, DateTime.now(),
                      category.text.trim(), notes.text.trim());
                }
              },
              child: const Text('Save'))
        ]));
  }

  void _profitDialog({String? initialInvestmentId}) {
    if (controller.investments.isEmpty) {
      Get.snackbar('No investment', 'Add an investment first.');
      return;
    }
    String selected =
        initialInvestmentId ?? controller.investments.first['id'].toString();
    final amount = TextEditingController();
    final notes = TextEditingController();
    final month = DateTime.now().obs;
    Get.dialog(StatefulBuilder(
        builder: (_, setState) => AlertDialog(
                title: const Text('Add investment income'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  DropdownButtonFormField<String>(
                      initialValue: selected,
                      items: controller.investments
                          .map((i) => DropdownMenuItem(
                              value: i['id'].toString(),
                              child: Text(i['title'].toString())))
                          .toList(),
                      onChanged: (v) => setState(() => selected = v!),
                      decoration:
                          const InputDecoration(labelText: 'Investment')),
                  const SizedBox(height: 10),
                  ListTile(
                      title: Obx(() =>
                          Text(DateFormat('MMMM yyyy').format(month.value))),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final picked = await showDatePicker(
                            context: Get.context!,
                            initialDate: month.value,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100));
                        if (picked != null) month.value = picked;
                      }),
                  const SizedBox(height: 10),
                  TextField(
                      controller: amount,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Income / profit amount')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: notes,
                      decoration:
                          const InputDecoration(labelText: 'Source / notes')),
                ]),
                actions: [
                  TextButton(onPressed: Get.back, child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () {
                        final n = double.tryParse(amount.text);
                        if (n == null || n <= 0) {
                          Get.snackbar(
                              'Invalid amount', 'Enter a valid amount.');
                          return;
                        }
                        controller.addProfit(
                            selected, n, month.value, notes.text.trim());
                      },
                      child: const Text('Save'))
                ])));
  }

  String _money(dynamic value) =>
      NumberFormat('#,##0.##').format((value as num? ?? 0));
}
