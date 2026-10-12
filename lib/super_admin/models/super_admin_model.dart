class SuperAdminModel {
  final String id;
  final String email;
  final String role;
  final String status;

  SuperAdminModel({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
  });

  factory SuperAdminModel.fromFirestore(
      String documentId,
      Map<String, dynamic> data,
      ) {
    return SuperAdminModel(
      id: documentId,
      email: data['email']?.toString() ?? '',
      role: data['role']?.toString().toLowerCase() ?? '',
      status: data['status']?.toString().toLowerCase() ?? '',
    );
  }
}