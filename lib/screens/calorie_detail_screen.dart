import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../controllers/health_data_controller.dart';
import '../models/activity_models.dart';
import '../widgets/common_widgets.dart';
import '../services/food_api_service.dart';
import '../services/food_recognition_service.dart';
import '../services/gemini_ai_service.dart'; // Changed from groq
import '../widgets/notification_widget.dart';

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
                Text('Unable to Identify Food',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
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
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text('Add Food',
                style: GoogleFonts.inter(
                    fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            _buildSourceOption(
              icon: Icons.camera_alt,
              title: 'Take Photo',
              subtitle: 'Use camera to detect food',
              color: const Color(0xFF3A86FF),
              onTap: () {
                Navigator.pop(context);
                _pickImageAndDetect(ImageSource.camera);
              },
            ),
            const SizedBox(height: 12),
            _buildSourceOption(
              icon: Icons.photo_library,
              title: 'Choose from Gallery',
              subtitle: 'Select existing photo',
              color: const Color(0xFF8338EC),
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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
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
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        selectedType.color,
                        selectedType.color.withOpacity(0.8),
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
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.restaurant_menu,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Add to Log',
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.9))),
                            const SizedBox(height: 4),
                            Text(food['name'],
                                style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meal Type Selector
                      Text('Meal Category',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: MealType.values.map((type) {
                            final isSelected = selectedType == type;
                            return InkWell(
                              onTap: () => setState(() => selectedType = type),
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? type.color : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? type.color
                                        : Colors.grey.shade200,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: type.color.withOpacity(0.3),
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
                                        size: 16,
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
                                              : Colors.black87,
                                        )),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Quantity Selector with better UI
                      Text('Quantity',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.shade200,
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
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: quantity > 1
                                        ? selectedType.color.withOpacity(0.1)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: quantity > 1
                                          ? selectedType.color.withOpacity(0.3)
                                          : Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.remove,
                                    color: quantity > 1
                                        ? selectedType.color
                                        : Colors.grey.shade400,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),

                            // Quantity display
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedType.color.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text('$quantity',
                                      style: GoogleFonts.inter(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: selectedType.color,
                                          height: 1)),
                                  const SizedBox(height: 2),
                                  Text(quantity == 1 ? 'serving' : 'servings',
                                      style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black54)),
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
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: quantity < 10
                                        ? selectedType.color.withOpacity(0.1)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: quantity < 10
                                          ? selectedType.color.withOpacity(0.3)
                                          : Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    color: quantity < 10
                                        ? selectedType.color
                                        : Colors.grey.shade400,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Nutrition Summary Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              selectedType.color,
                              selectedType.color.withOpacity(0.85),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: selectedType.color.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total Calories',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withOpacity(0.9))),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('${food['calories'] * quantity}',
                                        style: GoogleFonts.inter(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            height: 1)),
                                    const SizedBox(width: 4),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text('kcal',
                                          style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white
                                                  .withOpacity(0.9))),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
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
                                    height: 24,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  _buildMacroInfo('Carbs', '${food['carbs']}g',
                                      Icons.grain),
                                  Container(
                                    width: 1,
                                    height: 24,
                                    color: Colors.white.withOpacity(0.3),
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
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Cancel',
                              style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
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
                          style: FilledButton.styleFrom(
                            backgroundColor: selectedType.color,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_circle_outline, size: 20),
                              const SizedBox(width: 8),
                              Text('Add to Log',
                                  style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                            ],
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
    );
  }

  Widget _buildMacroInfo(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 18),
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
                color: Colors.white.withOpacity(0.8))),
      ],
    );
  }

  void _showDeleteMealDialog(MealEntry meal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF006E)),
            const SizedBox(width: 12),
            Text('Remove Meal?',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text('Do you want to remove "${meal.name}" from your log?',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF006E),
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
            child: Text('Remove', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        title: Text('Calorie Tracker',
            style:
                GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<HealthDataController>(
        builder: (context, data, _) {
          final goal = data.recommendedGoals;
          final caloriePercent =
              (data.caloriesConsumed / goal.calorieGoal).clamp(0.0, 1.0);

          final mealsByType = <MealType, List<MealEntry>>{};
          for (var meal in data.meals) {
            mealsByType.putIfAbsent(meal.mealType, () => []).add(meal);
          }

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              // Hero Card
              Container(
                margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF006E), Color(0xFFFF4081)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF006E).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Today\'s Calories',
                                style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${data.caloriesConsumed.round()}',
                                    style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 42,
                                        fontWeight: FontWeight.w800,
                                        height: 1)),
                                const SizedBox(width: 6),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text('/ ${goal.calorieGoal.round()}',
                                      style: GoogleFonts.inter(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${(caloriePercent * 100).round()}%',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: caloriePercent,
                        minHeight: 8,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          data.caloriesConsumed >= goal.calorieGoal
                              ? Icons.check_circle
                              : Icons.local_fire_department,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          data.caloriesConsumed >= goal.calorieGoal
                              ? 'Goal achieved! 🎉'
                              : '${(goal.calorieGoal - data.caloriesConsumed).round()} kcal remaining',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Search Bar
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: _filterFoods,
                  onSubmitted: _filterFoods,
                  decoration: InputDecoration(
                    hintText: 'Search food items...',
                    hintStyle:
                        GoogleFonts.inter(color: Colors.black38, fontSize: 15),
                    prefixIcon: const Icon(Icons.search,
                        color: Color(0xFF3A86FF), size: 22),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: Colors.black38, size: 20),
                            onPressed: () {
                              searchController.clear();
                              _filterFoods('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),

              // Content Section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meal Type Filter Chips
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x08000000),
                              blurRadius: 8,
                              offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Quick Add To',
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: MealType.values.map((type) {
                              final isSelected = selectedMealType == type;
                              final typeCalories = mealsByType[type]?.fold<int>(
                                      0, (sum, meal) => sum + meal.calories) ??
                                  0;
                              return FilterChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(type.displayName),
                                    if (typeCalories > 0) ...[
                                      const SizedBox(width: 6),
                                      Text('($typeCalories)',
                                          style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700)),
                                    ],
                                  ],
                                ),
                                avatar: Icon(type.icon,
                                    size: 16,
                                    color:
                                        isSelected ? Colors.white : type.color),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() => selectedMealType = type);
                                },
                                selectedColor: type.color,
                                backgroundColor: type.color.withOpacity(0.1),
                                labelStyle: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Search Results
                    if (isSearching) ...[
                      Row(
                        children: [
                          const Icon(Icons.search,
                              color: Color(0xFF3A86FF), size: 20),
                          const SizedBox(width: 8),
                          Text('Search Results',
                              style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87)),
                          if (isLoadingSearch) ...[
                            const SizedBox(width: 10),
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (isLoadingSearch)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                Text('Searching...',
                                    style: GoogleFonts.inter(
                                        color: Colors.black54)),
                              ],
                            ),
                          ),
                        )
                      else if (filteredFoods.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF5F7FA),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.search_off,
                                      size: 40, color: Color(0xFFBDBDBD)),
                                ),
                                const SizedBox(height: 16),
                                Text('No results found',
                                    style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87)),
                                const SizedBox(height: 6),
                                Text('Try different keywords',
                                    style: GoogleFonts.inter(
                                        fontSize: 13, color: Colors.black45)),
                              ],
                            ),
                          ),
                        )
                      else
                        ...filteredFoods.map(
                            (food) => _buildFoodItemWithDetails(food, data)),
                      const SizedBox(height: 24),
                    ],

                    // Meals by Type
                    if (data.meals.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.restaurant_menu,
                              color: Color(0xFF3A86FF), size: 20),
                          const SizedBox(width: 8),
                          Text('Today\'s Meals',
                              style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87)),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                              decoration: BoxDecoration(
                                color: type.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(type.icon, size: 18, color: type.color),
                                  const SizedBox(width: 8),
                                  Text(type.displayName,
                                      style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: type.color)),
                                  const Spacer(),
                                  Text('$totalCalories kcal',
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: type.color)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...meals.map((meal) => _buildMealItem(meal)),
                            const SizedBox(height: 16),
                          ],
                        );
                      }),
                    ] else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF5F7FA),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.restaurant_menu,
                                    size: 40, color: Color(0xFFBDBDBD)),
                              ),
                              const SizedBox(height: 16),
                              Text('No meals logged yet',
                                  style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black54)),
                              const SizedBox(height: 6),
                              Text('Start by searching or scanning food',
                                  style: GoogleFonts.inter(
                                      fontSize: 13, color: Colors.black38)),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showImageSourceDialog,
        backgroundColor: const Color(0xFF3A86FF),
        icon: const Icon(Icons.add_a_photo),
        label: Text('Scan Food',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildFoodItemWithDetails(
      Map<String, dynamic> food, HealthDataController data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            _showQuantityDialog(food, data);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF006E), Color(0xFFFF4081)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.restaurant,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(food['name'],
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87)),
                      const SizedBox(height: 6),
                      Text(
                          'P: ${food['protein']}g • C: ${food['carbs']}g • F: ${food['fat']}g',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: Colors.black45)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text('${food['calories']}',
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFF006E))),
                    Text('kcal',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: Colors.black45)),
                  ],
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A86FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.add, color: Color(0xFF3A86FF), size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMealItem(MealEntry meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: meal.mealType.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: meal.mealType.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                Icon(meal.mealType.icon, color: meal.mealType.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(meal.name,
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(meal.mealType.icon,
                      size: 12, color: meal.mealType.color),
                  const SizedBox(width: 4),
                  Text(meal.mealType.displayName,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: meal.mealType.color,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Text('• ${DateFormat.jm().format(meal.time)}',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: Colors.black45)),
                ],
              ),
            ]),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${meal.calories}',
                  style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: meal.mealType.color)),
              Text('kcal',
                  style:
                      GoogleFonts.inter(fontSize: 11, color: Colors.black45)),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              _showDeleteMealDialog(meal);
            },
            icon: const Icon(Icons.delete_outline, color: Color(0xFFFF006E)),
            iconSize: 24,
          ),
        ],
      ),
    );
  }
}
