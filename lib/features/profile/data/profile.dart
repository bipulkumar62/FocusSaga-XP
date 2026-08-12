/// Row of the `profiles` table.
class Profile {
  const Profile({
    required this.userId,
    this.displayName,
    this.email,
    this.avatarUrl,
    required this.coins,
    required this.profileLevel,
    required this.tutorialCompleted,
    this.selectedCharacterId,
    this.createdAt,
    this.updatedAt,
  });

  final String userId;
  final String? displayName;
  final String? email;
  final String? avatarUrl;
  final int coins;
  final int profileLevel;
  final bool tutorialCompleted;
  final String? selectedCharacterId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      coins: json['coins'] as int,
      profileLevel: json['profile_level'] as int,
      tutorialCompleted: json['tutorial_completed'] as bool,
      selectedCharacterId: json['selected_character_id'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }
}