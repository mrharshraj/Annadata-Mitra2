// Weather advisory (backend-written, farmer reads own-village rows),
// AI conversation/message, and crop scan records.

class WeatherAdvisory {
  const WeatherAdvisory({
    required this.id,
    required this.villageId,
    required this.advisoryDate,
    this.weatherData,
    this.advisoryText,
  });

  final String id;
  final String villageId;
  final DateTime advisoryDate;
  final Map<String, dynamic>? weatherData;
  final String? advisoryText;

  factory WeatherAdvisory.fromJson(Map<String, dynamic> json) =>
      WeatherAdvisory(
        id: json['id'] as String,
        villageId: json['village_id'] as String,
        advisoryDate: DateTime.parse(json['advisory_date'] as String),
        weatherData: json['weather_data'] as Map<String, dynamic>?,
        advisoryText: json['advisory_text'] as String?,
      );
}

class AiConversation {
  const AiConversation({required this.id, required this.farmerId, this.title});

  final String id;
  final String farmerId;
  final String? title;

  factory AiConversation.fromJson(Map<String, dynamic> json) => AiConversation(
    id: json['id'] as String,
    farmerId: json['farmer_id'] as String,
    title: json['title'] as String?,
  );
}

class AiMessage {
  const AiMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
  });

  final String id;
  final String conversationId;
  final String role;
  final String content;

  factory AiMessage.fromJson(Map<String, dynamic> json) => AiMessage(
    id: json['id'] as String,
    conversationId: json['conversation_id'] as String,
    role: json['role'] as String? ?? 'user',
    content: json['content'] as String? ?? '',
  );
}

class CropScan {
  const CropScan({
    required this.id,
    required this.farmerId,
    this.fieldId,
    required this.imagePath,
    this.detectedCrop,
    this.detectedIssue,
    this.confidence,
  });

  final String id;
  final String farmerId;
  final String? fieldId;
  final String imagePath;
  final String? detectedCrop;
  final String? detectedIssue;
  final double? confidence;

  factory CropScan.fromJson(Map<String, dynamic> json) => CropScan(
    id: json['id'] as String,
    farmerId: json['farmer_id'] as String,
    fieldId: json['field_id'] as String?,
    imagePath: json['image_path'] as String? ?? '',
    detectedCrop: json['detected_crop'] as String?,
    detectedIssue: json['detected_issue'] as String?,
    confidence: (json['confidence'] as num?)?.toDouble(),
  );
}
