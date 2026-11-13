import 'bill_result.dart';

/// A bill estimate the user chose to keep in history.
class SavedEstimate {
  const SavedEstimate({required this.id, required this.savedAt, required this.result});

  final String id;
  final DateTime savedAt;
  final BillResult result;

  Map<String, dynamic> toJson() => {
        'id': id,
        'savedAt': savedAt.toIso8601String(),
        'result': result.toJson(),
      };

  factory SavedEstimate.fromJson(Map<String, dynamic> json) => SavedEstimate(
        id: json['id'] as String,
        savedAt: DateTime.parse(json['savedAt'] as String),
        result: BillResult.fromJson(Map<String, dynamic>.from(json['result'] as Map)),
      );
}
