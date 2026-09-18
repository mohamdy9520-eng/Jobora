/// Profile fields that live outside Firebase Auth's `User` object —
/// stored in the 'users' Firestore collection, keyed by uid.
class UserProfileModel {
  final String uid;
  final String? username;
  final String? jobTitle;

  const UserProfileModel({
    required this.uid,
    this.username,
    this.jobTitle,
  });

  factory UserProfileModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfileModel(
      uid: uid,
      username: data['username'] as String?,
      jobTitle: data['jobTitle'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (username != null) 'username': username,
      if (jobTitle != null) 'jobTitle': jobTitle,
    };
  }

  UserProfileModel copyWith({String? username, String? jobTitle}) {
    return UserProfileModel(
      uid: uid,
      username: username ?? this.username,
      jobTitle: jobTitle ?? this.jobTitle,
    );
  }
}