import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/class_item.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class AddClassScreen extends StatefulWidget {
  final ClassItem? classItem;
  final StorageService storageService;
  final List<ClassItem> templates;

  const AddClassScreen({
    super.key,
    this.classItem,
    required this.storageService,
    required this.templates,
  });

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  
  String _selectedDay = 'Monday';
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 50);
  int _selectedColorIndex = 0;

  final List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.classItem != null) {
      _loadFromItem(widget.classItem!);
    }
  }

  void _loadFromItem(ClassItem item, {bool keepTime = false}) {
    setState(() {
      _titleController.text = item.title;
      _noteController.text = item.note ?? '';
      _selectedColorIndex = item.colorIndex;
      if (!keepTime) {
        _selectedDay = item.day;
        _startTime = _parseTime(item.startTime);
        _endTime = _parseTime(item.endTime);
      }
    });
  }

  TimeOfDay _parseTime(String timeStr) {
    // Expected format "9:00 AM"
    try {
      final format = DateFormat.jm(); 
      final date = format.parse(timeStr);
      return TimeOfDay.fromDateTime(date);
    } catch (e) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          // Smart time selection: auto set end time to start time + 50 mins
          final startDateTime = DateTime(2022, 1, 1, _startTime.hour, _startTime.minute);
          final endDateTime = startDateTime.add(const Duration(minutes: 50));
          _endTime = TimeOfDay.fromDateTime(endDateTime);
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  Future<void> _saveClass({bool closeAfterSave = true}) async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    final newItem = ClassItem(
      id: widget.classItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      day: _selectedDay,
      startTime: _formatTime(_startTime),
      endTime: _formatTime(_endTime),
      colorIndex: _selectedColorIndex,
      note: _noteController.text,
    );

    if (widget.classItem != null && closeAfterSave) {
        // Edit mode - always close after update
        await widget.storageService.updateClass(newItem);
        if (mounted) Navigator.pop(context);
    } else {
        // Add mode
        await widget.storageService.addClass(newItem);
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Saved "${newItem.title}" to $_selectedDay')),
            );
            if (closeAfterSave) {
                Navigator.pop(context);
            }
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.classItem != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.primary)),
        ),
        leadingWidth: 80,
        title: Text(isEditing ? 'Edit Class' : 'Add Class', style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => _saveClass(closeAfterSave: true),
            child: Text(isEditing ? 'Update' : 'Save', style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Title', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Day and Time Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Day', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedDay,
                            dropdownColor: AppColors.surface,
                            isExpanded: true,
                            style: const TextStyle(color: Colors.white),
                            items: _days.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedDay = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Time', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectTime(context, true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _formatTime(_startTime),
                                  style: const TextStyle(color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectTime(context, false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _formatTime(_endTime),
                                  style: const TextStyle(color: Colors.white),
                                  textAlign: TextAlign.center,
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
            
            const SizedBox(height: 16),
            
            // Add Multiple Button (Only for new classes)
            if (!isEditing)
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _saveClass(closeAfterSave: false),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Save & Add Another', style: TextStyle(fontSize: 16)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            const Text('Color', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: AppColors.predefinedColors.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColorIndex = index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.predefinedColors[index],
                        shape: BoxShape.circle,
                        border: _selectedColorIndex == index
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                      ),
                      child: _selectedColorIndex == index
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            const Text('Information', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Additional notes...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            
            // Quick Templates
            if (!isEditing && widget.templates.isNotEmpty) ...[
                const SizedBox(height: 32),
                const Divider(color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Recent Classes (Quick Fill)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                    height: 80,
                    child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.templates.length,
                        itemBuilder: (context, index) {
                            final template = widget.templates[index];
                            final color = AppColors.predefinedColors[template.colorIndex % AppColors.predefinedColors.length];
                            return GestureDetector(
                                onTap: () => _loadFromItem(template, keepTime: true),
                                child: Container(
                                    width: 140,
                                    margin: const EdgeInsets.only(right: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                        color: color.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                            Text(
                                                template.title, 
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                    ),
                                ),
                            );
                        },
                    ),
                ),
                const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}
