import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import '../models/class_item.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../widgets/class_card.dart';
import 'add_class_screen.dart';

class TimetableScreen extends StatefulWidget {
  final StorageService storageService;

  const TimetableScreen({super.key, required this.storageService});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  List<ClassItem> _classes = [];

  final List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  // Config for time slots
  final int _startHour = 8; // 8:00 AM
  final int _endHour = 19;  // 7:00 PM
  final double _hourHeight = 100.0;

  @override
  void initState() {
    super.initState();
    int weekday = DateTime.now().weekday - 1;
    _currentPage = weekday;
    _pageController = PageController(initialPage: _currentPage);
    _loadClasses();
  }

  void _loadClasses() {
    setState(() {
      _classes = widget.storageService.getClasses();
    });
  }

  List<ClassItem> _getClassesForDay(String day) {
    return _classes.where((item) => item.day == day).toList();
  }

  Future<void> _navigateToAddClass([ClassItem? classItem]) async {
    // Extract unique templates based on title
    final seenTitles = <String>{};
    final templates = _classes.where((c) => seenTitles.add(c.title)).toList();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddClassScreen(
          classItem: classItem,
          storageService: widget.storageService,
          templates: templates,
        ),
      ),
    );

    // Reload classes when returning, as AddClassScreen might have added/updated classes directly
    _loadClasses();
  }

  void _confirmDelete(ClassItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Class', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this class?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              await widget.storageService.deleteClass(item.id);
              _loadClasses();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showClassOptions(ClassItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: const Text('Edit', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _navigateToAddClass(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text('Delete', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
        title: Text(
          _days[_currentPage],
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _navigateToAddClass(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Day navigation
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _days.length,
              itemBuilder: (context, index) {
                final isSelected = index == _currentPage;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      _days[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _days.length,
              itemBuilder: (context, index) {
                return TimetableDayView(
                  day: _days[index],
                  classes: _getClassesForDay(_days[index]),
                  startHour: _startHour,
                  endHour: _endHour,
                  hourHeight: _hourHeight,
                  onClassTap: _showClassOptions,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddClass(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class TimetableDayView extends StatefulWidget {
  final String day;
  final List<ClassItem> classes;
  final int startHour;
  final int endHour;
  final double hourHeight;
  final Function(ClassItem) onClassTap;

  const TimetableDayView({
    super.key,
    required this.day,
    required this.classes,
    required this.startHour,
    required this.endHour,
    required this.hourHeight,
    required this.onClassTap,
  });

  @override
  State<TimetableDayView> createState() => _TimetableDayViewState();
}

class _TimetableDayViewState extends State<TimetableDayView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scrollToFirstClass();
    });
  }

  void _scrollToFirstClass() {
    if (widget.classes.isEmpty) return;

    // Find earliest class
    double minTopOffset = double.infinity;
    
    for (var item in widget.classes) {
      final top = _calculateTopOffset(item.startTime);
      if (top < minTopOffset) {
        minTopOffset = top;
      }
    }

    if (minTopOffset != double.infinity) {
      // Add some padding (e.g. 20 pixels) so it looks good
      final target = (minTopOffset - 20).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.jumpTo(target);
    }
  }

  double _calculateTopOffset(String timeStr) {
    try {
      final format = DateFormat.jm();
      final date = format.parse(timeStr);
      final minutesFromStart = (date.hour - widget.startHour) * 60 + date.minute;
      return (minutesFromStart / 60) * widget.hourHeight;
    } catch (e) {
      return 0; // Fallback
    }
  }

  double _calculateHeight(String startStr, String endStr) {
    try {
      final format = DateFormat.jm();
      final startDate = format.parse(startStr);
      final endDate = format.parse(endStr);
      
      final diff = endDate.difference(startDate);
      final minutes = diff.inMinutes;
      
      return (minutes / 60) * widget.hourHeight;
    } catch (e) {
      return widget.hourHeight; // Fallback to 1 hour
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Labels
          SizedBox(
            width: 60,
            child: Column(
              children: List.generate((widget.endHour - widget.startHour) + 1, (i) {
                final hour = widget.startHour + i;
                final time = TimeOfDay(hour: hour, minute: 0);
                final now = DateTime.now();
                final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
                final timeStr = DateFormat.jm().format(dt);
                
                return SizedBox(
                  height: widget.hourHeight,
                  child: Text(
                    timeStr,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.right,
                  ),
                );
              }),
            ),
          ),
          // Schedule Grid
          Expanded(
            child: SizedBox(
              height: (widget.endHour - widget.startHour + 1) * widget.hourHeight,
              child: Stack(
                children: [
                  // Grid lines
                  ...List.generate((widget.endHour - widget.startHour) + 1, (i) {
                    return Positioned(
                      top: i * widget.hourHeight,
                      left: 0,
                      right: 0,
                      child: const Divider(color: Colors.grey, thickness: 0.5),
                    );
                  }),
                  // Classes
                  ...widget.classes.map((classItem) {
                    final top = _calculateTopOffset(classItem.startTime);
                    final height = _calculateHeight(classItem.startTime, classItem.endTime);
                    
                    return Positioned(
                      top: top,
                      left: 0,
                      right: 0,
                      height: height,
                      child: ClassCard(
                        classItem: classItem,
                        onTap: () => widget.onClassTap(classItem),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
