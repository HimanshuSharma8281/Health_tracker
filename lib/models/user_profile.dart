class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.devices,
  });

  final String name;
  final String email;
  final String avatarUrl;
  final List<String> devices;
}
