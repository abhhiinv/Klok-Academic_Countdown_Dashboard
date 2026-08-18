// ClassGroup model
class ClassGroup {
  final String id;
  final String name;
  final String classCode;
  final String adminUID;
  final List<String> members;

  ClassGroup({
    required this.id,
    required this.name,
    required this.classCode,
    required this.adminUID,
    required this.members,
  });

  factory ClassGroup.fromFirestore(Map<String, dynamic> data, String id) {
    return ClassGroup(
      id: id,
      name: data['name'] as String,
      classCode: data['classCode'] as String,
      adminUID: data['adminUID'] as String,
      members: List<String>.from(data['members'] as List? ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'classCode': classCode,
      'adminUID': adminUID,
      'members': members,
    };
  }

  bool isAdmin(String uid) => adminUID == uid;
}
