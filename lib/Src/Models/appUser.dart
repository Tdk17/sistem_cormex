class AppUser {
  const AppUser({
    required this.objectId,
    required this.name,
    required this.email,
    required this.username,
    this.document = '',
    this.phone = '',
    this.role = '',
    this.roleLabel = '',
    this.companyId,
    this.companyName = '',
    this.sellerId,
    this.ordersAccess = false,
    this.createdAt,
  });

  final String objectId;
  final String name;
  final String email;
  final String username;
  final String document;
  final String phone;
  final String role;
  final String roleLabel;
  final String? companyId;
  final String companyName;
  final String? sellerId;
  final bool ordersAccess;
  final DateTime? createdAt;

  factory AppUser.fromMap(Map<String, dynamic> map) {
    final username = map['username']?.toString() ?? '';
    final email = map['email']?.toString() ?? username;
    return AppUser(
      objectId: map['id']?.toString() ?? map['objectId']?.toString() ?? '',
      name: map['fullname']?.toString() ??
          map['name']?.toString() ??
          email.split('@').first,
      email: email,
      username: username.isEmpty ? email : username,
      document: map['document']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      roleLabel: map['roleLabel']?.toString() ?? '',
      companyId: map['companyId']?.toString(),
      companyName: map['companyName']?.toString() ?? '',
      sellerId: map['sellerId']?.toString(),
      ordersAccess: map['ordersAccess'] == true,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? ''),
    );
  }
}
