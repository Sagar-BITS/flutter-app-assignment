class NotificationItem {
  final String message;
  final bool isSuccess;
  final DateTime timestamp;

  NotificationItem({
    required this.message,
    required this.isSuccess,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'message': message,
        'isSuccess': isSuccess,
        'timestamp': timestamp.toIso8601String(),
      };

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      message: json['message'],
      isSuccess: json['isSuccess'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}