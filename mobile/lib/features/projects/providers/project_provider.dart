import 'package:flutter/foundation.dart';
import '../models/project_model.dart';
import '../services/project_service.dart';

enum ProjectLoadStatus { initial, loading, loaded, error }

/// ProjectProvider tập trung quản lý danh sách projects.
/// Thay thế _isLoading, _projects, setState() trong project_screen.
class ProjectProvider extends ChangeNotifier {
  final ProjectService _service;

  ProjectProvider({ProjectService? service})
      : _service = service ?? const ProjectService();

  List<ProjectModel> _projects = [];
  ProjectLoadStatus _status = ProjectLoadStatus.initial;
  String? _errorMessage;

  // --- Getters ---
  List<ProjectModel> get projects => _projects;
  ProjectLoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ProjectLoadStatus.loading;

  /// Tổng số project
  int get projectCount => _projects.length;

  // --- Load danh sách projects ---
  Future<void> loadProjects({bool silent = false}) async {
    if (!silent) {
      _status = ProjectLoadStatus.loading;
      notifyListeners();
    }
    try {
      final list = await _service.getProjects();
      _projects = _normalize(list);
      _status = ProjectLoadStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      _status = ProjectLoadStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  List<ProjectModel> _normalize(dynamic decoded) {
    final rawProjects = decoded is List
        ? decoded
        : (decoded is Map && decoded['projects'] is List
            ? decoded['projects'] as List
            : const []);

    return rawProjects.map((p) {
      if (p is Map) {
        return ProjectModel.fromJson(Map<String, dynamic>.from(p));
      }
      return ProjectModel.fromJson(const {});
    }).toList();
  }

  // --- Tạo project mới và tự reload ---
  /// Trả về `_id` của project vừa tạo (chuỗi rỗng nếu backend không trả).
  /// Caller (sheet tạo project) dùng id này để gọi tiếp update/invite.
  Future<String> createProject({
    required Map<String, dynamic> payload,
  }) async {
    final created = await _service.createProject(payload: payload);
    await loadProjects(silent: true);
    return (created['_id'] ?? created['id'] ?? '').toString();
  }

  // --- Cập nhật project và update local state ngay ---
  Future<void> updateProject({
    required String projectId,
    required Map<String, dynamic> payload,
  }) async {
    await _service.updateProject(projectId: projectId, payload: payload);
    await loadProjects(silent: true);
  }

  // --- Xóa project ---
  Future<void> deleteProject(String projectId) async {
    await _service.deleteProject(projectId);
    _projects.removeWhere((p) => p.project.id == projectId);
    notifyListeners();
  }

  // --- Thêm thành viên ---
  Future<Map<String, dynamic>> addMember({
    required String projectId,
    required String email,
  }) async {
    return _service.addMember(projectId: projectId, email: email);
  }

  // --- Cập nhật role thành viên ---
  Future<Map<String, dynamic>> updateMemberRole({
    required String projectId,
    required String userId,
    required String role,
  }) async {
    return _service.updateMemberRole(
        projectId: projectId, userId: userId, role: role);
  }

  // --- Rời project ---
  Future<void> leaveProject(String projectId) async {
    await _service.leaveProject(projectId);
    _projects.removeWhere((p) => p.project.id == projectId);
    notifyListeners();
  }
}
