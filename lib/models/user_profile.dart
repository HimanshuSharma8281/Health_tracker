/// Canonical user profile — stored in Firestore at users/{uid}.
///
/// Extends the minimal 4-field version with full demographic and goal fields
/// required for personalized health scoring.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.avatarUrl = '',
    this.devices = const [],
    // Demographics — required for personalised scoring
    this.age,
    this.sex,
    this.heightCm,
    this.weightKg,
    this.activityLevel,
    this.fitnessGoal,
    // User-defined daily goals
    this.stepGoal = 10000,
    this.waterGoalMl = 2500,
    this.calorieGoal = 2000,
    this.sleepGoalHours = 8.0,
  });

  final String uid;
  final String name;
  final String email;
  final String avatarUrl;
  final List<String> devices;

  // Demographics
  final int? age;
  final String? sex; // 'male' | 'female' | 'other'
  final double? heightCm;
  final double? weightKg;
  final String? activityLevel; // 'sedentary' | 'lightly_active' | 'moderately_active' | 'very_active'
  final String? fitnessGoal;   // 'maintain' | 'lose_weight' | 'gain_weight' | 'improve_fitness'

  // Daily goals (also persisted in Firestore for cross-device sync)
  final int stepGoal;
  final int waterGoalMl;
  final double calorieGoal;
  final double sleepGoalHours;

  /// Whether the profile has enough data for personalized health scoring.
  bool get isComplete =>
      age != null &&
      sex != null &&
      heightCm != null &&
      weightKg != null &&
      activityLevel != null &&
      fitnessGoal != null;

  /// BMI — null if height/weight unavailable.
  double? get bmi {
    if (heightCm == null || weightKg == null || heightCm! <= 0) return null;
    final hm = heightCm! / 100.0;
    return weightKg! / (hm * hm);
  }

  /// Human-readable BMI category.
  String get bmiCategory {
    final b = bmi;
    if (b == null) return 'Unknown';
    if (b < 18.5) return 'Underweight';
    if (b < 25.0) return 'Normal';
    if (b < 30.0) return 'Overweight';
    return 'Obese';
  }

  UserProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? avatarUrl,
    List<String>? devices,
    int? age,
    String? sex,
    double? heightCm,
    double? weightKg,
    String? activityLevel,
    String? fitnessGoal,
    int? stepGoal,
    int? waterGoalMl,
    double? calorieGoal,
    double? sleepGoalHours,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      devices: devices ?? this.devices,
      age: age ?? this.age,
      sex: sex ?? this.sex,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      stepGoal: stepGoal ?? this.stepGoal,
      waterGoalMl: waterGoalMl ?? this.waterGoalMl,
      calorieGoal: calorieGoal ?? this.calorieGoal,
      sleepGoalHours: sleepGoalHours ?? this.sleepGoalHours,
    );
  }

  /// Serialize to Firestore document map.
  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
        'devices': devices,
        if (age != null) 'age': age,
        if (sex != null) 'sex': sex,
        if (heightCm != null) 'heightCm': heightCm,
        if (weightKg != null) 'weightKg': weightKg,
        if (activityLevel != null) 'activityLevel': activityLevel,
        if (fitnessGoal != null) 'fitnessGoal': fitnessGoal,
        'stepGoal': stepGoal,
        'waterGoalMl': waterGoalMl,
        'calorieGoal': calorieGoal,
        'sleepGoalHours': sleepGoalHours,
      };

  /// Deserialize from Firestore document map.
  factory UserProfile.fromFirestore(Map<String, dynamic> data) => UserProfile(
        uid: data['uid'] as String? ?? '',
        name: data['name'] as String? ?? 'User',
        email: data['email'] as String? ?? '',
        avatarUrl: data['avatarUrl'] as String? ?? '',
        devices: List<String>.from(data['devices'] ?? []),
        age: data['age'] as int?,
        sex: data['sex'] as String?,
        heightCm: (data['heightCm'] as num?)?.toDouble(),
        weightKg: (data['weightKg'] as num?)?.toDouble(),
        activityLevel: data['activityLevel'] as String?,
        fitnessGoal: data['fitnessGoal'] as String?,
        stepGoal: data['stepGoal'] as int? ?? 10000,
        waterGoalMl: data['waterGoalMl'] as int? ?? 2500,
        calorieGoal: (data['calorieGoal'] as num?)?.toDouble() ?? 2000,
        sleepGoalHours: (data['sleepGoalHours'] as num?)?.toDouble() ?? 8.0,
      );

  /// Create a minimal profile from Firebase Auth data (no demographics yet).
  factory UserProfile.fromFirebaseAuth({
    required String uid,
    required String name,
    required String email,
    String avatarUrl = '',
  }) =>
      UserProfile(uid: uid, name: name, email: email, avatarUrl: avatarUrl);
}

/// Activity level display helpers.
extension ActivityLevelExtension on String {
  String get activityDisplayName {
    switch (this) {
      case 'sedentary':
        return 'Sedentary';
      case 'lightly_active':
        return 'Lightly Active';
      case 'moderately_active':
        return 'Moderately Active';
      case 'very_active':
        return 'Very Active';
      default:
        return this;
    }
  }
}

/// Fitness goal display helpers.
extension FitnessGoalExtension on String {
  String get goalDisplayName {
    switch (this) {
      case 'maintain':
        return 'Maintain Weight';
      case 'lose_weight':
        return 'Lose Weight';
      case 'gain_weight':
        return 'Gain Weight';
      case 'improve_fitness':
        return 'Improve Fitness';
      default:
        return this;
    }
  }
}
