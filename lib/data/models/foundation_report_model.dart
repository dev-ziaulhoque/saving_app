class FoundationReportModel {
  final DateTime month;
  final List<Map<String, dynamic>> members;
  final List<Map<String, dynamic>> investments;
  final List<Map<String, dynamic>> profits;
  final List<Map<String, dynamic>> expenses;
  final Map<String, dynamic> summary;

  const FoundationReportModel({
    required this.month,
    required this.members,
    required this.investments,
    required this.profits,
    required this.expenses,
    required this.summary,
  });

  factory FoundationReportModel.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> rows(String key) =>
        (json[key] as List? ?? const [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
    return FoundationReportModel(
      month: DateTime.parse(json['report_month'] as String),
      members: rows('members'),
      investments: rows('investments'),
      profits: rows('profits'),
      expenses: rows('expenses'),
      summary: Map<String, dynamic>.from(json['summary'] as Map? ?? const {}),
    );
  }

  double amount(String key) => (summary[key] as num? ?? 0).toDouble();
}
