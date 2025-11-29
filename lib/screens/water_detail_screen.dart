import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/health_data_controller.dart';
import '../widgets/notification_widget.dart';

class WaterDetailScreen extends StatefulWidget {
  const WaterDetailScreen({super.key});

  @override
  State<WaterDetailScreen> createState() => _WaterDetailScreenState();
}

class _WaterDetailScreenState extends State<WaterDetailScreen>
    with SingleTickerProviderStateMixin {
  final List<int> quickAddAmounts = [100, 250, 500, 750, 1000];
  int selectedAmount = 250;
  final TextEditingController customAmountController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Add filter state
  String selectedFilter = 'Weekly'; // 'Weekly' or 'Monthly'

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    customAmountController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _addWater(HealthDataController data, int amount) {
    data.addWater(amount);
    _animationController.forward(from: 0);
    CustomNotification.show(
      context,
      message: 'Added $amount ml to your water intake',
      type: NotificationType.success,
      title: 'Water Added',
    );
  }

  void _removeWater(HealthDataController data, WaterIntakeReading entry) {
    data.removeWaterIntake(entry);
    CustomNotification.show(
      context,
      message: 'Removed ${entry.amount} ml from your water intake',
      type: NotificationType.info,
      title: 'Water Removed',
    );
  }

  void _showCustomAmountDialog(HealthDataController data) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2EC4B6).withOpacity(0.2),
                  blurRadius: 30,
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2EC4B6), Color(0xFF1A8F8A)],
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.water_drop,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Custom Amount',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enter your water intake',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Input field with enhanced styling
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9F8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF2EC4B6).withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: TextField(
                          controller: customAmountController,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2EC4B6),
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: '250',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.black26,
                            ),
                            suffixText: 'ml',
                            suffixStyle: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2EC4B6),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Info card with icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF2EC4B6).withOpacity(0.1),
                              const Color(0xFF1A8F8A).withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF2EC4B6).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2EC4B6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.info_outline,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Enter 1 to 5000 ml',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF2EC4B6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Quick suggestions
                      Text(
                        'Quick Suggestions',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [300, 500, 750].map((amount) {
                          return InkWell(
                            onTap: () {
                              customAmountController.text = amount.toString();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      const Color(0xFF2EC4B6).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '$amount',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2EC4B6),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                customAmountController.clear();
                                Navigator.pop(context);
                              },
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2EC4B6),
                                    Color(0xFF1A8F8A)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2EC4B6)
                                        .withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    final amount = int.tryParse(
                                        customAmountController.text);
                                    if (amount != null &&
                                        amount > 0 &&
                                        amount <= 5000) {
                                      _addWater(data, amount);
                                      customAmountController.clear();
                                      Navigator.pop(context);
                                    } else {
                                      CustomNotification.show(
                                        context,
                                        message:
                                            'Please enter a valid amount (1-5000 ml)',
                                        type: NotificationType.error,
                                        title: 'Invalid Amount',
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.add_circle_outline,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Add Water',
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9F8),
      body: Consumer<HealthDataController>(
        builder: (context, data, _) {
          final progress = (data.waterMl / data.waterGoal).clamp(0.0, 1.0);
          final remaining = data.waterGoal - data.waterMl;
          final glassesCount = (data.waterMl / 250).floor();

          return CustomScrollView(
            slivers: [
              // Custom App Bar
              SliverAppBar(
                expandedHeight: 280,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF2EC4B6),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF2EC4B6),
                          const Color(0xFF1A8F8A),
                          const Color(0xFF128C85),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                        child: Column(
                          children: [
                            // Animated water drop icon
                            ScaleTransition(
                              scale: _scaleAnimation,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.3),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      Icons.water_drop,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                                    Positioned(
                                      bottom: 20,
                                      child: Container(
                                        height: 30,
                                        width: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.3),
                                          borderRadius:
                                              BorderRadius.circular(25),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Current amount
                            Text(
                              '${data.waterMl} ml',
                              style: GoogleFonts.inter(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'of ${data.waterGoal} ml goal',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2EC4B6).withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${(progress * 100).toStringAsFixed(0)}%',
                                      style: GoogleFonts.inter(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF2EC4B6),
                                      ),
                                    ),
                                    Text(
                                      'Daily Progress',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2EC4B6)
                                        .withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.local_drink,
                                          color: const Color(0xFF2EC4B6),
                                          size: 28),
                                      Text(
                                        '$glassesCount',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF2EC4B6),
                                        ),
                                      ),
                                      Text(
                                        'glasses',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Animated Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                children: [
                                  Container(
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2EC4B6)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 600),
                                    height: 16,
                                    width: MediaQuery.of(context).size.width *
                                        progress *
                                        0.82,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF2EC4B6),
                                          Color(0xFF1A8F8A)
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF2EC4B6)
                                              .withOpacity(0.4),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  remaining <= 0
                                      ? Icons.celebration
                                      : Icons.water_drop_outlined,
                                  color: const Color(0xFF2EC4B6),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  remaining <= 0
                                      ? 'Amazing! Goal achieved! 🎉'
                                      : '$remaining ml to go today',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2EC4B6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Quick Add Section (MOVED UP)
                      Row(
                        children: [
                          Icon(Icons.touch_app,
                              color: const Color(0xFF2EC4B6), size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Quick Add',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Quick add buttons in grid
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.3,
                        children: [
                          ...quickAddAmounts.map((amount) {
                            final isSelected = selectedAmount == amount;
                            return InkWell(
                              onTap: () {
                                setState(() => selectedAmount = amount);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFF2EC4B6),
                                            Color(0xFF1A8F8A)
                                          ],
                                        )
                                      : null,
                                  color: isSelected ? null : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF2EC4B6)
                                        : Colors.grey.shade200,
                                    width: 2,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF2EC4B6)
                                                .withOpacity(0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 6),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.water_drop,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF2EC4B6),
                                      size: 28,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '$amount ml',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          // Custom button
                          InkWell(
                            onTap: () => _showCustomAmountDialog(data),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFF2EC4B6), width: 2),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit,
                                      color: const Color(0xFF2EC4B6), size: 28),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Custom',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF2EC4B6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Big Add Button
                      Container(
                        width: double.infinity,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2EC4B6), Color(0xFF1A8F8A)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2EC4B6).withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _addWater(data, selectedAmount),
                            borderRadius: BorderRadius.circular(20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add,
                                      color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Add $selectedAmount ml',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Chart Header with Dropdown Filter (NOW BELOW QUICK ADD)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.bar_chart,
                                  color: const Color(0xFF2EC4B6), size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'Water Intake',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          // Dropdown Filter
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF2EC4B6).withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF2EC4B6).withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedFilter,
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: const Color(0xFF2EC4B6),
                                  size: 24,
                                ),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2EC4B6),
                                ),
                                borderRadius: BorderRadius.circular(12),
                                dropdownColor: Colors.white,
                                items: [
                                  DropdownMenuItem(
                                    value: 'Weekly',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_view_week,
                                          color: const Color(0xFF2EC4B6),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text('Weekly'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Monthly',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_month,
                                          color: const Color(0xFF2EC4B6),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text('Monthly'),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      selectedFilter = newValue;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Chart based on filter
                      Container(
                        height: 240,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2EC4B6).withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: selectedFilter == 'Weekly'
                            ? _buildWeeklyChart(data)
                            : _buildMonthlyChart(data),
                      ),
                      const SizedBox(height: 32),

                      // Hourly Distribution Pie Chart
                      Row(
                        children: [
                          Icon(Icons.pie_chart,
                              color: const Color(0xFF2EC4B6), size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Daily Distribution',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2EC4B6).withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: data.getTodayWaterIntake().isNotEmpty
                            ? _buildWaterDistributionChart(data)
                            : Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.water_drop_outlined,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No water intake today',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Start logging to see distribution',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: Colors.grey[500],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 32),

                      // Water History
                      if (data.getTodayWaterIntake().isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.history,
                                    color: const Color(0xFF2EC4B6), size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  'Today\'s History',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2EC4B6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${data.getTodayWaterIntake().length} entries',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2EC4B6),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...data
                            .getTodayWaterIntake()
                            .reversed
                            .map((entry) => Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    leading: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF2EC4B6),
                                            Color(0xFF1A8F8A)
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.water_drop,
                                          color: Colors.white, size: 22),
                                    ),
                                    title: Text(
                                      '${entry.amount} ml',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    subtitle: Text(
                                      _formatTime(entry.timestamp),
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      onPressed: () =>
                                          _removeWater(data, entry),
                                      icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Color(0xFFFF006E)),
                                      iconSize: 24,
                                    ),
                                  ),
                                )),
                        const SizedBox(height: 24),
                      ],

                      // Hydration Tips
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF2EC4B6).withOpacity(0.1),
                              const Color(0xFF1A8F8A).withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF2EC4B6).withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2EC4B6),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.tips_and_updates,
                                      color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Hydration Tips',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2EC4B6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildTip(
                                '💧', 'Drink water first thing in the morning'),
                            _buildTip('⏰', 'Set reminders every 2 hours'),
                            _buildTip(
                                '🏃', 'Drink extra water during exercise'),
                            _buildTip('🍎', 'Eat water-rich foods like fruits'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWeeklyChart(HealthDataController data) {
    final now = DateTime.now();

    // Create a map for the last 7 days using getWaterForDay helper
    final Map<int, int> waterByDay = {};
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: 6 - i));
      waterByDay[i] = data.getWaterForDay(day);
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.waterGoal.toDouble() * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.round()} ml',
                GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                final today = DateTime.now().weekday - 1;
                final dayIndex = (today - 6 + value.toInt()) % 7;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    days[dayIndex < 0 ? dayIndex + 7 : dayIndex],
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${(value / 1000).toStringAsFixed(1)}L',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.black45,
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1000,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (index) {
          final waterAmount = waterByDay[index] ?? 0;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: waterAmount > 0 ? waterAmount.toDouble() : 0,
                gradient: LinearGradient(
                  colors: waterAmount > 0
                      ? [const Color(0xFF2EC4B6), const Color(0xFF1A8F8A)]
                      : [Colors.grey.shade300, Colors.grey.shade300],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMonthlyChart(HealthDataController data) {
    final now = DateTime.now();
    final Map<int, int> waterByWeek = {0: 0, 1: 0, 2: 0, 3: 0};

    for (int i = 0; i < 28; i++) {
      final day = now.subtract(Duration(days: i));
      final water = data.getWaterForDay(day);
      final weekIndex = 3 - (i ~/ 7);

      if (weekIndex >= 0 && weekIndex < 4) {
        waterByWeek[weekIndex] = (waterByWeek[weekIndex] ?? 0) + water;
      }
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.waterGoal.toDouble() * 7 * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${(rod.toY / 1000).toStringAsFixed(1)}L',
                GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const weeks = ['W1', 'W2', 'W3', 'W4'];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    weeks[value.toInt()],
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${(value / 1000).toStringAsFixed(0)}L',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.black45,
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5000,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(4, (index) {
          final weeklyTotal = waterByWeek[index] ?? 0;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: weeklyTotal > 0 ? weeklyTotal.toDouble() : 0,
                gradient: LinearGradient(
                  colors: weeklyTotal > 0
                      ? [
                          const Color(0xFF2EC4B6)
                              .withOpacity(0.8 + (index * 0.05)),
                          const Color(0xFF1A8F8A)
                              .withOpacity(0.8 + (index * 0.05)),
                        ]
                      : [Colors.grey.shade300, Colors.grey.shade300],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 40,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF2EC4B6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF2EC4B6), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTip(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterDistributionChart(HealthDataController data) {
    final todayIntake = data.getTodayWaterIntake();

    // Calculate water distribution by time periods
    double morning = 0; // 5 AM - 12 PM
    double afternoon = 0; // 12 PM - 5 PM
    double evening = 0; // 5 PM - 9 PM
    double night = 0; // 9 PM - 5 AM

    for (var reading in todayIntake) {
      final hour = reading.timestamp.hour;
      if (hour >= 5 && hour < 12) {
        morning += reading.amount;
      } else if (hour >= 12 && hour < 17) {
        afternoon += reading.amount;
      } else if (hour >= 17 && hour < 21) {
        evening += reading.amount;
      } else {
        night += reading.amount;
      }
    }

    final total = morning + afternoon + evening + night;

    if (total == 0) {
      return Center(
        child: Text(
          'No data available',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    // Calculate percentages
    final morningPercent = (morning / total * 100).round();
    final afternoonPercent = (afternoon / total * 100).round();
    final eveningPercent = (evening / total * 100).round();
    final nightPercent = (night / total * 100).round();

    return Row(
      children: [
        // Pie Chart
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: [
                  if (morning > 0)
                    PieChartSectionData(
                      value: morning.toDouble(),
                      title: '$morningPercent%',
                      color: const Color(0xFF2EC4B6),
                      radius: 50,
                      titleStyle: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  if (afternoon > 0)
                    PieChartSectionData(
                      value: afternoon.toDouble(),
                      title: '$afternoonPercent%',
                      color: const Color(0xFF1A8F8A),
                      radius: 50,
                      titleStyle: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  if (evening > 0)
                    PieChartSectionData(
                      value: evening.toDouble(),
                      title: '$eveningPercent%',
                      color: const Color(0xFF128C85),
                      radius: 50,
                      titleStyle: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  if (night > 0)
                    PieChartSectionData(
                      value: night.toDouble(),
                      title: '$nightPercent%',
                      color: const Color(0xFF0D7A75),
                      radius: 50,
                      titleStyle: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        // Legend
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (morning > 0)
                _buildLegendItem(
                  'Morning',
                  '${(morning / 1000).toStringAsFixed(1)}L',
                  const Color(0xFF2EC4B6),
                ),
              if (morning > 0 && (afternoon > 0 || evening > 0 || night > 0))
                const SizedBox(height: 12),
              if (afternoon > 0)
                _buildLegendItem(
                  'Afternoon',
                  '${(afternoon / 1000).toStringAsFixed(1)}L',
                  const Color(0xFF1A8F8A),
                ),
              if (afternoon > 0 && (evening > 0 || night > 0))
                const SizedBox(height: 12),
              if (evening > 0)
                _buildLegendItem(
                  'Evening',
                  '${(evening / 1000).toStringAsFixed(1)}L',
                  const Color(0xFF128C85),
                ),
              if (evening > 0 && night > 0) const SizedBox(height: 12),
              if (night > 0)
                _buildLegendItem(
                  'Night',
                  '${(night / 1000).toStringAsFixed(1)}L',
                  const Color(0xFF0D7A75),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
