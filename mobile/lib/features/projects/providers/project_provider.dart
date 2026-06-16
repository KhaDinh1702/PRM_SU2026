import 'package:flutter/foundation.dart';
import '../services/project_service.dart';

enum ProjectLoadStatus { initial, loading, loaded, error }

/// ProjectProvider tập trung quản lý danh sách projects.
/// Thay thế _isLoading, _projects, setState() trong project_screen.
class ProjectProvider extends ChangeNotifier {
  final ProjectService _service;

  ProjectProvider({ProjectService? service})
      : _service = service ?? const ProjectService();

  List<dynamic> _projects = [];
  ProjectLoadStatus _status = ProjectLoadStatus.initial;
  String? _errorMessage;

  // --- Getters ---
  List<dynamic> get projects => _projects;
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

  List<dynamic> _normalize(dynamic decoded) {
    final rawProjects = decoded is List
        ? decoded
        : (decoded is Map<String, dynamic> && decoded['projects'] is List
            ? decoded['projects'] as List
            : const []);

    return rawProjects.map((p) {
      if (p is Map<String, dynamic> && p.containsKey('project')) {
        return p;
      }

      return {
        'project': p,
        'currentUserRole': null,
        'pendingInvitationUserIds': [],
        'stats': {
          'totalTasks': 0,
          'completedTasks': 0,
          'progressPercentage': 0,
        },
      };
    }).toList();
  }

  // --- Tạo project mới và tự reload ---
  Future<void> createProject({
    required String name,
    required String description,
  }) async {
    await _service.createProject(name: name, description: description);
    await loadProjects(silent: true);
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
    _projects.removeWhere((p) {
      final proj = p['project'];
      if (proj is Map) {
        return (proj['_id'] ?? proj['id']) == projectId;
      }
      return false;
    });
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
}
