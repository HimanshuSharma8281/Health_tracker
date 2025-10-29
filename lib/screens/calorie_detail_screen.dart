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
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Processing image...',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );

      try {
        final result =
            await FoodApiService.detectFoodFromImage(File(file.path));

        if (!mounted) return;
        Navigator.pop(context);

        if (result['error'] == 'IMAGE_MANUAL_ENTRY') {
          _showManualFoodEntryDialog(data);
        } else if (result['detected'] == true) {
          _showDetectedFoodDialog(result, data);
        } else {
          CustomNotification.show(
            context,
            message: result['error'] ?? 'Could not detect food',
            type: NotificationType.error,
            title: 'Detection Failed',
          );
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        CustomNotification.show(
          context,
          message: 'Error: $e',
          type: NotificationType.error,
        );
      }
    }
  }

  void _showManualFoodEntryDialog(HealthDataController data) {
    final TextEditingController foodNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.edit, color: Color(0xFF3A86FF)),
            const SizedBox(width: 12),
            Text('Describe the Food',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('What food do you see in the image?',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 16),
            TextField(
              controller: foodNameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g., grilled chicken, pizza slice',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.restaurant),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              foodNameController.dispose();
              Navigator.pop(context);
            },
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          FilledButton(
            onPressed: () async {
              final foodName = foodNameController.text.trim();
              if (foodName.isEmpty) return;

              Navigator.pop(context);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text('Getting nutrition info...',
                            style:
                                GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              );

              try {
                final results = await FoodApiService.searchFood(foodName);

                if (!mounted) return;
                Navigator.pop(context);

                if (results.isNotEmpty) {
                  _showDetectedFoodDialog({
                    'detected': true,
                    'name': results[0]['name'],
                    'calories': results[0]['calories'],
                    'protein': results[0]['protein'],
                    'carbs': results[0]['carbs'],
                    'fat': results[0]['fat'],
                    'confidence': 0.85,
                  }, data);
                } else {
                  CustomNotification.show(
                    context,
                    message: 'Could not find nutrition info for "$foodName"',
                    type: NotificationType.warning,
                    title: 'Not Found',
                  );
                }
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                CustomNotification.show(
                  context,
                  message: 'Error: $e',
                  type: NotificationType.error,
                );
              }

              foodNameController.dispose();
            },
            child: Text('Search', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  void _showDetectedFoodDialog(
      Map<String, dynamic> result, HealthDataController data) {
    int quantity = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
              const SizedBox(width: 12),
              Text('Food Detected!',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result['name'],
                  style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),

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
                  '${(double.parse(result['protein']) * quantity).toStringAsFixed(1)}g',
                  Icons.fitness_center),
              _buildNutrientRow(
                  'Carbs',
                  '${(double.parse(result['carbs']) * quantity).toStringAsFixed(1)}g',
                  Icons.grain),
              _buildNutrientRow(
                  'Fat',
                  '${(double.parse(result['fat']) * quantity).toStringAsFixed(1)}g',
                  Icons.water_drop),
              const SizedBox(height: 12),
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
                    Text('Confidence: ${(result['confidence'] * 100).round()}%',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
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
                ));
                Navigator.pop(context);
                CustomNotification.show(
                  context,
                  message: '${result['name']} x$quantity added to your log!',
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
                                Text('${data.caloriesConsumed}',
                                    style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 42,
                                        fontWeight: FontWeight.w800,
                                        height: 1)),
                                const SizedBox(width: 6),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text('/ ${goal.calorieGoal}',
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
                              : '${goal.calorieGoal - data.caloriesConsumed} kcal remaining',
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
              const SizedBox(height: 16),

              // Search Bar Section
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
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      onChanged: _filterFoods,
                      onSubmitted: _filterFoods,
                      decoration: InputDecoration(
                        hintText: 'Search food items...',
                        hintStyle: GoogleFonts.inter(
                            color: Colors.black38, fontSize: 15),
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
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _showImageSourceDialog,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3A86FF), Color(0xFF8338EC)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3A86FF).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text('Scan Food with AI',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content Section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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

                    // Recent Meals
                    Row(
                      children: [
                        const Icon(Icons.history,
                            color: Color(0xFF3A86FF), size: 20),
                        const SizedBox(width: 8),
                        Text('Recent Meals',
                            style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (data.meals.isEmpty)
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
                      )
                    else
                      ...data.meals.map((meal) => _buildMealItem(meal)),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          );
        },
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

  void _showQuantityDialog(
      Map<String, dynamic> food, HealthDataController data) {
    int quantity = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Add ${food['name']}',
              style:
                  GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
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
                          icon: const Icon(Icons.remove_circle),
                          color: const Color(0xFF3A86FF),
                          iconSize: 32,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFF3A86FF), width: 2),
                          ),
                          child: Text('$quantity',
                              style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF3A86FF))),
                        ),
                        IconButton(
                          onPressed: quantity < 10
                              ? () => setState(() => quantity++)
                              : null,
                          icon: const Icon(Icons.add_circle),
                          color: const Color(0xFF3A86FF),
                          iconSize: 32,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF006E), Color(0xFFFF4081)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Calories',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                    Text('${food['calories'] * quantity} kcal',
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter()),
            ),
            FilledButton(
              onPressed: () {
                data.logMeal(MealEntry(
                  name: quantity > 1
                      ? '${food['name']} x$quantity'
                      : food['name'],
                  calories: food['calories'] * quantity,
                  time: DateTime.now(),
                ));
                Navigator.pop(context);
                CustomNotification.show(
                  context,
                  message: '${food['name']} x$quantity added to your log!',
                  type: NotificationType.success,
                  title: 'Meal Added',
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF3A86FF),
              ),
              child: Text('Add to Log', style: GoogleFonts.inter()),
            ),
          ],
        ),
      ),
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

  Widget _buildMealItem(MealEntry meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.restaurant,
                color: Color(0xFF3A86FF), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.name,
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
                const SizedBox(height: 4),
                Text(DateFormat.jm().format(meal.time),
                    style:
                        GoogleFonts.inter(fontSize: 12, color: Colors.black45)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${meal.calories}',
                  style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3A86FF))),
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
