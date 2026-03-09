class AsyncTaskModel {
  final String id;
  final String taskType;
  final String status;
  final String? description;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? resultData;
  final String? errorMessage;
  final double progress; // 0.0 to 1.0

  AsyncTaskModel({
    required this.id,
    required this.taskType,
    required this.status,
    this.description,
    required this.createdAt,
    this.completedAt,
    this.resultData,
    this.errorMessage,
    required this.progress,
  });

  factory AsyncTaskModel.fromJson(Map<String, dynamic> json) {
    return AsyncTaskModel(
      id: json['id'] as String,
      taskType: json['task_type'] as String,
      status: json['status'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      resultData: json['result_data'] as String?,
      errorMessage: json['error_message'] as String?,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_type': taskType,
      'status': status,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'result_data': resultData,
      'error_message': errorMessage,
      'progress': progress,
    };
  }

  bool get isCompleted {
    return status == 'COMPLETED' || status == 'SUCCESS';
  }

  bool get isFailed {
    return status == 'FAILED' || status == 'ERROR';
  }

  bool get isPending {
    return status == 'PENDING' || status == 'QUEUED';
  }

  bool get isProcessing {
    return status == 'PROCESSING' || status == 'RUNNING';
  }

  String get statusDisplay {
    switch (status) {
      case 'PENDING':
      case 'QUEUED':
        return 'Pending';
      case 'PROCESSING':
      case 'RUNNING':
        return 'Processing';
      case 'COMPLETED':
      case 'SUCCESS':
        return 'Completed';
      case 'FAILED':
      case 'ERROR':
        return 'Failed';
      default:
        return status;
    }
  }

  String get statusIcon {
    if (isCompleted) return '✅';
    if (isFailed) return '❌';
    if (isProcessing) return '🔄';
    return '⏳';
  }

  String get progressPercentage {
    return '${(progress * 100).toStringAsFixed(1)}%';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AsyncTaskModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  AsyncTaskModel copyWith({
    String? id,
    String? taskType,
    String? status,
    String? description,
    DateTime? createdAt,
    DateTime? completedAt,
    String? resultData,
    String? errorMessage,
    double? progress,
  }) {
    return AsyncTaskModel(
      id: id ?? this.id,
      taskType: taskType ?? this.taskType,
      status: status ?? this.status,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      resultData: resultData ?? this.resultData,
      errorMessage: errorMessage ?? this.errorMessage,
      progress: progress ?? this.progress,
    );
  }
}