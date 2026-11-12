class UserModel {
  const UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    this.photoUrl,
  });
  final String uid, firstName, lastName, email;
  final String? photoUrl;
  final DateTime createdAt, updatedAt;
  String get fullName => '$firstName $lastName';
  UserModel copyWith({String? firstName, String? lastName, String? photoUrl}) =>
      UserModel(
        uid: uid,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email,
        photoUrl: photoUrl ?? this.photoUrl,
        createdAt: createdAt,
        updatedAt: DateTime.now().toUtc(),
      );
  Map<String, dynamic> toJson() => {
    'uid': uid,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'photoUrl': photoUrl,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    uid: json['uid'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    email: json['email'] as String,
    photoUrl: json['photoUrl'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}
