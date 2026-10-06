// Repository contracts for Phase 2+ (Supabase) and Phase 3+ (FastAPI).
// Phase 1 ships interfaces only — no fake API/database implementations.

/// Farmer profile + village association (Phase 5).
abstract class FarmerRepository {
  Future<void> loadProfile();
}

/// Fields + field_crops lifecycle (Phase 6).
abstract class FieldRepository {
  Future<void> listFields();
}

/// Crop catalogue + advice (Phase 6).
abstract class CropRepository {
  Future<void> listCrops();
}

/// Task CRUD over todo_tasks (Phase 7).
abstract class TaskRepository {
  Future<void> listTasks();
}

/// Weather via FastAPI → Weather API (Phase 8).
abstract class WeatherRepository {
  Future<void> currentWeather();
}

/// Contextual AI via FastAPI → provider (Phase 9).
abstract class AiRepository {
  Future<void> sendMessage();
}

/// Crop image analysis via FastAPI + Storage (Phase 10).
abstract class ScannerRepository {
  Future<void> analyzeScan();
}
