import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../controllers/health_data_controller.dart';
import '../models/activity_models.dart';
import '../services/food_api_service.dart';
import '../services/food_recognition_service.dart';
import '../widgets/notification_widget.dart';
import '../widgets/glass_container.dart';

class CalorieDetailScreen extends StatefulWidget {
  const CalorieDetailScreen({super.key});

  @override
  State<CalorieDetailScreen> createState() => _CalorieDetailScreenState();
}

class _CalorieDetailScreenState extends State<CalorieDetailScreen> {
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredFoods = [];
  bool isSearching = false;
  bool isLoadingSearch = false;
  MealType selectedMealType = MealType.snack;
  String selectedChartFilter = 'Weekly'; // Add chart filter

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _filterFoods(String query) async {
    if (query.isEmpty) {
      setState(() {
        filteredFoods = [];
        isSearching = false;
        isLoadingSearch = false;
      });
      return;
    }

    setState(() {
      isSearching = true;
      isLoadingSearch = true;
    });

    try {
      final results = await FoodApiService.searchFood(query);
      setState(() {
        filteredFoods = results;
        isLoadingSearch = false;
      });
    } catch (e) {
      setState(() {
        filteredFoods = [];
        isLoadingSearch = false;
      });
      if (mounted) {
        CustomNotification.show(
          context,
          message: 'Error searching food: $e',
          type: NotificationType.error,
          title: 'Search Failed',
        );
      }
    }
  }

  Future<void> _pickImageAndDetect(ImageSource source) async {
    final data = context.read<HealthDataController>();
    final file = await ImagePicker().pickImage(source: source);

    if (!mounted) return;

    if (file != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3A86FF), Color(0xFF8338EC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3A86FF).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Analyzing Meal',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Identifying food & calculating nutrition...',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image_search, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'AI Vision Processing',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      try {
        final result = await FoodRecognitionService.recognizeFoodFromImage(
          File(file.path),
        );

        if (!mounted) return;
        Navigator.pop(context);

        // Show detected food dialog
        if (result['predictions'] != null &&
            (result['predictions'] as List).length > 1) {
          _showFoodSelectionDialog(result['predictions'], data);
        } else {
          _showDetectedFoodDialog(result, data);
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);

        print('Error details: $e');

        // Show try again dialog instead of fallback
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFFF006E)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Unable to Identify Food',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We couldn\'t identify the food in this image. This could be because:',
                  style: GoogleFonts.inter(fontSize: 14),
                ),
                const SizedBox(height: 12),
                _buildTipRow('📸', 'Image quality is too low'),
                _buildTipRow('🍽️', 'Food is not clearly visible'),
                _buildTipRow('🌐', 'Network connection issues'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tips_and_updates,
                          color: Color(0xFF3A86FF), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Try taking a clearer photo or use the search bar',
                          style: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  searchController.clear();
                },
                child: Text('Search Manually', style: GoogleFonts.inter()),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showImageSourceDialog();
                },
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3A86FF)),
                child: Text('Try Again', style: GoogleFonts.inter()),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildTipRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  void _showFoodSelectionDialog(
      List<dynamic> predictions, HealthDataController data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.fastfood, color: Color(0xFF3A86FF)),
            const SizedBox(width: 12),
            Text('Select Food Item',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('We detected multiple items. Please select the correct one:',
                  style:
                      GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 16),
              ...predictions.take(3).map((prediction) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _showDetectedFoodDialog(prediction, data);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF3A86FF),
                                    Color(0xFF3A86FF).withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.restaurant,
                                  color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(prediction['name'],
                                      style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87)),
                                  const SizedBox(height: 4),
                                  Text('${prediction['calories']} kcal',
                                      style: GoogleFonts.inter(
                                          fontSize: 12, color: Colors.black45)),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Text('${prediction['confidence']}%',
                                    style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF3A86FF))),
                                Text('match',
                                    style: GoogleFonts.inter(
                                        fontSize: 11, color: Colors.black45)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  void _showDetectedFoodDialog(
      Map<String, dynamic> result, HealthDataController data) {
    int quantity = 1;
    MealType selectedType = selectedMealType;

    // Check if food was detected
    final isFoodDetected =
        result['name'] != 'Unable to detect food' && result['calories'] > 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                isFoodDetected ? Icons.check_circle : Icons.help_outline,
                color: isFoodDetected
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFFF9800),
              ),
              const SizedBox(width: 12),
              Text(
                isFoodDetected ? 'Food Detected!' : 'Food Detection',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isFoodDetected)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF9800)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Color(0xFFFF9800), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Unable to detect food clearly. You can still add estimated values or try another image.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!isFoodDetected) const SizedBox(height: 16),

                Text(result['name'],
                    style: GoogleFonts.inter(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),

                // Meal Type Selector
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Meal Type',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: MealType.values.map((type) {
                          final isSelected = selectedType == type;
                          return ChoiceChip(
                            label: Text(type.displayName),
                            avatar: Icon(type.icon,
                                size: 16,
                                color: isSelected ? Colors.white : type.color),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => selectedType = type);
                            },
                            selectedColor: type.color,
                            backgroundColor: type.color.withOpacity(0.1),
                            labelStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Quantity Selector
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Quantity',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87)),
                      Row(
                        children: [
                          IconButton(
                            onPressed: quantity > 1
                                ? () => setState(() => quantity--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                            color: const Color(0xFF3A86FF),
                            iconSize: 28,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('$quantity',
                                style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF3A86FF))),
                          ),
                          IconButton(
                            onPressed: quantity < 10
                                ? () => setState(() => quantity++)
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                            color: const Color(0xFF3A86FF),
                            iconSize: 28,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _buildNutrientRow(
                    'Calories',
                    '${result['calories'] * quantity} kcal',
                    Icons.local_fire_department),
                _buildNutrientRow(
                    'Protein',
                    '${(double.parse(result['protein'].toString()) * quantity).toStringAsFixed(1)}g',
                    Icons.fitness_center),
                _buildNutrientRow(
                    'Carbs',
                    '${(double.parse(result['carbs'].toString()) * quantity).toStringAsFixed(1)}g',
                    Icons.grain),
                _buildNutrientRow(
                    'Fat',
                    '${(double.parse(result['fat'].toString()) * quantity).toStringAsFixed(1)}g',
                    Icons.water_drop),
                const SizedBox(height: 12),
                if (result['confidence'] != null &&
                    result['confidence'] != '0.0')
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.psychology,
                            color: Color(0xFF3A86FF), size: 20),
                        const SizedBox(width: 8),
                        Text('Confidence: ${result['confidence']}%',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter()),
            ),
            FilledButton(
              onPressed: () {
                data.logMeal(MealEntry(
                  name: '${result['name']} x$quantity',
                  calories: result['calories'] * quantity,
                  time: DateTime.now(),
                  mealType: selectedType,
                ));
                Navigator.pop(context);
                CustomNotification.show(
                  context,
                  message:
                      '${result['name']} x$quantity added to ${selectedType.displayName}!',
                  type: NotificationType.success,
                  title: 'Meal Added',
                );
              },
              child: Text('Add to Log', style: GoogleFonts.inter()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF3A86FF)),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.inter(color: Colors.black54)),
          const Spacer(),
          Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF141A22),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0x33FF5C7A), width: 1.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add Food with AI',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            _buildSourceOption(
              icon: Icons.camera_alt_rounded,
              title: 'Take Photo',
              subtitle: 'Scan meal with device camera',
              color: const Color(0xFFFF5C7A),
              onTap: () {
                Navigator.pop(context);
                _pickImageAndDetect(ImageSource.camera);
              },
            ),
            const SizedBox(height: 12),
            _buildSourceOption(
              icon: Icons.photo_library_rounded,
              title: 'Choose from Gallery',
              subtitle: 'Select meal photo from library',
              color: const Color(0xFFFF8E53),
              onTap: () {
                Navigator.pop(context);
                _pickImageAndDetect(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }

  void _showQuantityDialog(
      Map<String, dynamic> food, HealthDataController data) {
    int quantity = 1;
    MealType selectedType = selectedMealType;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: GlassContainer(
            blur: 24,
            padding: EdgeInsets.zero,
            color: const Color(0xE6141A22),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with gradient
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          selectedType.color,
                          selectedType.color.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.restaurant_menu,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ADD TO LOG',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                food['name'],
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Meal Type Selector
                        Text(
                          'MEAL CATEGORY',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white54,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: MealType.values.map((type) {
                              final isSelected = selectedType == type;
                              return InkWell(
                                onTap: () =>
                                    setState(() => selectedType = type),
                                borderRadius: BorderRadius.circular(10),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? type.color
                                        : Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? type.color
                                          : Colors.white
                                              .withValues(alpha: 0.08),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color:
                                                  type.color.withOpacity(0.35),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(type.icon,
                                          size: 15,
                                          color: isSelected
                                              ? Colors.white
                                              : type.color),
                                      const SizedBox(width: 6),
                                      Text(type.displayName,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.white70,
                                          )),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Quantity Selector
                        Text(
                          'QUANTITY',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white54,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Decrease button
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: quantity > 1
                                      ? () => setState(() => quantity--)
                                      : null,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: quantity > 1
                                          ? selectedType.color
                                              .withOpacity(0.18)
                                          : Colors.white.withValues(alpha: 0.03),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: quantity > 1
                                            ? selectedType.color
                                                .withOpacity(0.4)
                                            : Colors.white
                                                .withValues(alpha: 0.06),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.remove,
                                      color: quantity > 1
                                          ? selectedType.color
                                          : Colors.white24,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),

                              // Quantity display
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 26, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF090D10),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        selectedType.color.withOpacity(0.35),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text('$quantity',
                                        style: GoogleFonts.inter(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w800,
                                            color: selectedType.color,
                                            height: 1)),
                                    const SizedBox(height: 2),
                                    Text(
                                        quantity == 1 ? 'serving' : 'servings',
                                        style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white54)),
                                  ],
                                ),
                              ),

                              // Increase button
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: quantity < 10
                                      ? () => setState(() => quantity++)
                                      : null,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: quantity < 10
                                          ? selectedType.color
                                              .withOpacity(0.18)
                                          : Colors.white.withValues(alpha: 0.03),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: quantity < 10
                                            ? selectedType.color
                                                .withOpacity(0.4)
                                            : Colors.white
                                                .withValues(alpha: 0.06),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      color: quantity < 10
                                          ? selectedType.color
                                          : Colors.white24,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Nutrition Summary Card
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                selectedType.color.withValues(alpha: 0.22),
                                selectedType.color.withValues(alpha: 0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: selectedType.color.withValues(alpha: 0.35)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total Calories',
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white70)),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text('${food['calories'] * quantity}',
                                          style: GoogleFonts.inter(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              height: 1)),
                                      const SizedBox(width: 4),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 2),
                                        child: Text('kcal',
                                            style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white70)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.white
                                          .withValues(alpha: 0.08)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildMacroInfo(
                                        'Protein',
                                        '${food['protein']}g',
                                        Icons.fitness_center),
                                    Container(
                                      width: 1,
                                      height: 22,
                                      color: Colors.white.withValues(alpha: 0.12),
                                    ),
                                    _buildMacroInfo('Carbs', '${food['carbs']}g',
                                        Icons.grain),
                                    Container(
                                      width: 1,
                                      height: 22,
                                      color: Colors.white.withValues(alpha: 0.12),
                                    ),
                                    _buildMacroInfo('Fat', '${food['fat']}g',
                                        Icons.water_drop),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('Cancel',
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white54)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  selectedType.color,
                                  selectedType.color.withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: selectedType.color.withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                data.logMeal(MealEntry(
                                  name: quantity > 1
                                      ? '${food['name']} x$quantity'
                                      : food['name'],
                                  calories: food['calories'] * quantity,
                                  time: DateTime.now(),
                                  mealType: selectedType,
                                ));
                                Navigator.pop(context);
                                CustomNotification.show(
                                  context,
                                  message:
                                      '${food['name']} x$quantity added to ${selectedType.displayName}!',
                                  type: NotificationType.success,
                                  title: 'Meal Added',
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_circle_outline,
                                      size: 18),
                                  const SizedBox(width: 8),
                                  Text('Add to Log',
                                      style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMacroInfo(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.white54)),
      ],
    );
  }

  void _showDeleteMealDialog(MealEntry meal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141A22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x33FF5C7A), width: 1.2),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5C7A)),
            const SizedBox(width: 12),
            Text(
              'Remove Meal?',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'Do you want to remove "${meal.name}" from your log?',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF5C7A),
            ),
            onPressed: () {
              final data = context.read<HealthDataController>();
              data.removeMeal(meal);
              Navigator.pop(context);
              CustomNotification.show(
                context,
                message: '${meal.name} removed from your log',
                type: NotificationType.info,
                title: 'Meal Removed',
              );
            },
            child: Text('Remove', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D10),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF090D10),
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.6),
            radius: 1.25,
            colors: [
              Color(0xFF260D18), // Deep warm rose/coral glow
              Color(0xFF090D10), // Deep obsidian background
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<HealthDataController>(
            builder: (context, data, _) {
              final goal = data.recommendedGoals;
              final caloriePercent =
                  (data.caloriesConsumed / goal.calorieGoal).clamp(0.0, 1.0);

              final mealsByType = <MealType, List<MealEntry>>{};
              for (var meal in data.meals) {
                mealsByType.putIfAbsent(meal.mealType, () => []).add(meal);
              }

              return ListView(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                children: [
                  // 1. Navigation Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF5C7A),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x99FF5C7A),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'CALORIE TRACKER',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _showImageSourceDialog,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFF5C7A).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFFF5C7A)
                                    .withValues(alpha: 0.3)),
                          ),
                          child: const Icon(
                            Icons.add_a_photo_rounded,
                            size: 16,
                            color: Color(0xFFFF5C7A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 2. Hero Card
                  GlassContainer(
                    blur: 16,
                    color: const Color(0xE6141A20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFFF5C7A).withValues(alpha: 0.25)),
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TODAY\'S CALORIES',
                                  style: GoogleFonts.inter(
                                    color: Colors.white54,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${data.caloriesConsumed.round()}',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 38,
                                        fontWeight: FontWeight.w800,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        '/ ${goal.calorieGoal.round()} kcal',
                                        style: GoogleFonts.inter(
                                          color: Colors.white54,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0x33FF5C7A),
                                    Color(0x1AFF8E53)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0x66FF5C7A), width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  '${(caloriePercent * 100).round()}%',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFFF5C7A),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: caloriePercent,
                            minHeight: 8,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.08),
                            valueColor: const AlwaysStoppedAnimation(
                                Color(0xFFFF5C7A)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              data.caloriesConsumed >= goal.calorieGoal
                                  ? Icons.check_circle_rounded
                                  : Icons.local_fire_department_rounded,
                              color: const Color(0xFFFF5C7A),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              data.caloriesConsumed >= goal.calorieGoal
                                  ? 'Daily target achieved! 🎉'
                                  : '${(goal.calorieGoal - data.caloriesConsumed).round()} kcal remaining',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. Search Bar
                  GlassContainer(
                    blur: 16,
                    color: const Color(0xE6141A20),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    child: TextField(
                      controller: searchController,
                      onChanged: _filterFoods,
                      onSubmitted: _filterFoods,
                      style: GoogleFonts.inter(
                          color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search food items...',
                        hintStyle: GoogleFonts.inter(
                            color: Colors.white38, fontSize: 14),
                        prefixIcon: const Icon(Icons.search,
                            color: Color(0xFFFF5C7A), size: 20),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: Colors.white54, size: 18),
                                onPressed: () {
                                  searchController.clear();
                                  _filterFoods('');
                                },
                              )
                            : null,
                        filled: false,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 4. Meal Type Filter Chips
                  GlassContainer(
                    blur: 16,
                    color: const Color(0xE6141A20),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QUICK ADD TO',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white54,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: MealType.values.map((type) {
                            final isSelected = selectedMealType == type;
                            final typeCalories = mealsByType[type]?.fold<int>(
                                    0, (sum, meal) => sum + meal.calories) ??
                                0;
                            return InkWell(
                              onTap: () {
                                setState(() => selectedMealType = type);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? type.color.withOpacity(0.25)
                                      : Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? type.color
                                        : Colors.white
                                            .withValues(alpha: 0.08),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color:
                                                type.color.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(type.icon,
                                        size: 15,
                                        color: isSelected
                                            ? Colors.white
                                            : type.color),
                                    const SizedBox(width: 6),
                                    Text(
                                      type.displayName,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white70,
                                      ),
                                    ),
                                    if (typeCalories > 0) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? type.color
                                              : Colors.white
                                                  .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '$typeCalories',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // 5. Search Results Section
                  if (isSearching) ...[
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF5C7A),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SEARCH RESULTS',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Colors.white70,
                          ),
                        ),
                        if (isLoadingSearch) ...[
                          const SizedBox(width: 10),
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(Color(0xFFFF5C7A)),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (isLoadingSearch)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              const CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation(Color(0xFFFF5C7A)),
                              ),
                              const SizedBox(height: 16),
                              Text('Searching food database...',
                                  style: GoogleFonts.inter(
                                      color: Colors.white54)),
                            ],
                          ),
                        ),
                      )
                    else if (filteredFoods.isEmpty)
                      GlassContainer(
                        blur: 16,
                        color: const Color(0xE6141A20),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08)),
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.search_off_rounded,
                                    size: 36, color: Colors.white38),
                              ),
                              const SizedBox(height: 14),
                              Text('No results found',
                                  style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                              const SizedBox(height: 4),
                              Text('Try a different search term or scan food',
                                  style: GoogleFonts.inter(
                                      fontSize: 12, color: Colors.white38)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...filteredFoods.map(
                          (food) => _buildFoodItemWithDetails(food, data)),
                    const SizedBox(height: 22),
                  ],

                  // 6. Today's Meals Section
                  if (data.meals.isNotEmpty) ...[
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF8E53),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'TODAY\'S MEALS',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...MealType.values.map((type) {
                      final meals = mealsByType[type] ?? [];
                      if (meals.isEmpty) return const SizedBox.shrink();

                      final totalCalories = meals.fold<int>(
                          0, (sum, meal) => sum + meal.calories);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: type.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: type.color.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              children: [
                                Icon(type.icon, size: 16, color: type.color),
                                const SizedBox(width: 8),
                                Text(type.displayName,
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: type.color)),
                                const Spacer(),
                                Text('$totalCalories kcal',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: type.color)),
                              ],
                            ),
                          ),
                          ...meals.map((meal) => _buildMealItem(meal)),
                          const SizedBox(height: 12),
                        ],
                      );
                    }),
                  ] else
                    GlassContainer(
                      blur: 16,
                      color: const Color(0xE6141A20),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08)),
                      padding: const EdgeInsets.all(36),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.restaurant_menu_rounded,
                                  size: 36, color: Colors.white38),
                            ),
                            const SizedBox(height: 14),
                            Text('No meals logged today',
                                style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                            const SizedBox(height: 4),
                            Text('Start by searching or scanning your food',
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: Colors.white38)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF5C7A), Color(0xFFFF8E53)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5C7A).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _showImageSourceDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.document_scanner_rounded, color: Colors.white),
          label: Text('Scan Food',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildFoodItemWithDetails(
      Map<String, dynamic> food, HealthDataController data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        blur: 14,
        color: const Color(0xE6141A20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () {
              _showQuantityDialog(food, data);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5C7A), Color(0xFFFF8E53)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.restaurant_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(food['name'],
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(
                            'P: ${food['protein']}g • C: ${food['carbs']}g • F: ${food['fat']}g',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: Colors.white54)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${food['calories']}',
                          style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFFF5C7A))),
                      Text('kcal',
                          style: GoogleFonts.inter(
                              fontSize: 10, color: Colors.white38)),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5C7A).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFFFF5C7A).withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Color(0xFFFF5C7A), size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMealItem(MealEntry meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        blur: 14,
        color: const Color(0xE6141A20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: meal.mealType.color.withValues(alpha: 0.25)),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: meal.mealType.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: meal.mealType.color.withValues(alpha: 0.3)),
              ),
              child:
                  Icon(meal.mealType.icon, color: meal.mealType.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(meal.mealType.icon,
                          size: 11, color: meal.mealType.color),
                      const SizedBox(width: 4),
                      Text(
                        meal.mealType.displayName,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: meal.mealType.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• ${DateFormat.jm().format(meal.time)}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${meal.calories}',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: meal.mealType.color,
                  ),
                ),
                Text(
                  'kcal',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: () => _showDeleteMealDialog(meal),
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFFF5C7A), size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}
