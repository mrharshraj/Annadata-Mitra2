// Weather advisory (backend-written, farmer reads own-village rows),
// AI conversation/message, and crop scan records.

class WeatherAdvisory {
  const WeatherAdvisory({
    required this.id,
    required this.villageId,
    this.profileId,
    required this.weatherDate,
    this.temperature,
    this.rainfall,
    this.humidity,
    this.wind,
    this.advisoryText,
    this.severity = 'info',
  });

  final String id;
  final String villageId;
  final String? profileId;
  final DateTime weatherDate;
  final double? temperature;
  final double? rainfall;
  final double? humidity;
  final double? wind;
  final String? advisoryText;
  final String? severity;

  factory WeatherAdvisory.fromJson(Map<String, dynamic> json) =>
      WeatherAdvisory(
        id: json['id'] as String,
        villageId: json['village_id'] as String,
        profileId: json['profile_id'] as String?,
        weatherDate: DateTime.parse(json['weather_date'] as String),
        temperature: (json['temperature'] as num?)?.toDouble(),
        rainfall: (json['rainfall'] as num?)?.toDouble(),
        humidity: (json['humidity'] as num?)?.toDouble(),
        wind: (json['wind'] as num?)?.toDouble(),
        advisoryText: json['advisory_text'] as String?,
        severity: json['severity'] as String? ?? 'info',
      );
}

class AiConversation {
  const AiConversation({
    required this.id,
    required this.profileId,
    this.title,
    this.language = 'hi',
  });

  final String id;
  final String profileId;
  final String? title;
  final String? language;

  factory AiConversation.fromJson(Map<String, dynamic> json) => AiConversation(
    id: json['id'] as String,
    profileId: json['profile_id'] as String,
    title: json['title'] as String?,
    language: json['language'] as String? ?? 'hi',
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
    required this.profileId,
    this.fieldId,
    required this.imagePath,
    this.detectedCrop,
    this.detectedIssue,
    this.confidence,
    this.status = 'pending',
  });

  final String id;
  final String profileId;
  final String? fieldId;
  final String imagePath;
  final String? detectedCrop;
  final String? detectedIssue;
  final double? confidence;
  final String? status;

  factory CropScan.fromJson(Map<String, dynamic> json) => CropScan(
    id: json['id'] as String,
    profileId: json['profile_id'] as String,
    fieldId: json['field_id'] as String?,
    imagePath: json['image_path'] as String? ?? '',
    detectedCrop: json['detected_crop'] as String?,
    detectedIssue: json['detected_issue'] as String?,
    confidence: (json['confidence'] as num?)?.toDouble(),
    status: json['status'] as String? ?? 'pending',
  );
}
