import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/event.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';

// ── Design tokens ────────────────────────────────────────────────────────
const _bg = Color(0xFF1A1714);
const _surfaceHigh = Color(0xFF2C2820);
const _border = Color(0xFF3A3328);
const _primary = Color(0xFFF0A500);
const _onPrimary = Color(0xFF1A1714);
const _onSurface = Color(0xFFF5EFE6);
const _muted = Color(0xFF9C8E7E);
const _terracotta = Color(0xFFE8956D);
const _primaryContainer = Color(0xFF3D2E00);

class AddEventScreen extends StatefulWidget {
  /// null in offline/guest mode
  final User? user;

  /// null in offline/guest mode
  final String? classId;

  final int initialFeedIndex; // 0 = class, 1 = personal

  /// Called after a local event is saved (offline mode only)
  final VoidCallback? onLocalEventAdded;

  const AddEventScreen({
    super.key,
    required this.user,
    required this.classId,
    this.initialFeedIndex = 0,
    this.onLocalEventAdded,
  });

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _firestoreService = FirestoreService();
  final _localService = LocalStorageService();
  final _uuid = const Uuid();
  final _titleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _category = 'exam';
  DateTime? _selectedDate;
  bool _isPersonal = false;
  bool _isLoading = false;

  bool get _isOffline => widget.user == null;

  static const _categories = [
    ('exam', 'Exam', Icons.school_rounded),
    ('submission', 'Submission', Icons.assignment_rounded),
    ('fest', 'Fest', Icons.celebration_rounded),
    ('other', 'Other', Icons.event_rounded),
  ];

  @override
  void initState() {
    super.initState();
    // In offline mode, always save to personal (no class available)
    _isPersonal = _isOffline || widget.initialFeedIndex == 1;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final ctx = context; // capture before any await
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: ctx,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _primary,
              onPrimary: _onPrimary,
              surface: _surfaceHigh,
              onSurface: _onSurface,
            ),
            dialogBackgroundColor: _bg,
          ),
          child: child!,
        );
      },
    );
    if (!mounted || picked == null) return;
    
    // ignore: use_build_context_synchronously
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
          DateTime.now().add(const Duration(hours: 1))),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _primary,
              onPrimary: _onPrimary,
              surface: _surfaceHigh,
              onSurface: _onSurface,
            ),
            dialogBackgroundColor: _bg,
          ),
          child: child!,
        );
      },
    );
    if (mounted) {
      setState(() {
        _selectedDate = time != null
            ? DateTime(picked.year, picked.month, picked.day,
                time.hour, time.minute)
            : DateTime(picked.year, picked.month, picked.day, 23, 59);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date.',
              style: TextStyle(fontFamily: 'Inter')),
          backgroundColor: _terracotta,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final event = Event(
      id: _uuid.v4(),
      title: _titleController.text.trim(),
      category: _category,
      date: _selectedDate!,
      createdBy: widget.user?.uid ?? 'local',
      createdAt: DateTime.now(),
      isPersonal: _isPersonal,
    );

    try {
      if (_isOffline) {
        // Save to local device storage
        await _localService.addPersonalEvent(event);
        widget.onLocalEventAdded?.call();
      } else if (_isPersonal) {
        await _firestoreService.addPersonalEvent(widget.user!.uid, event);
      } else {
        await _firestoreService.addClassEvent(widget.classId!, event);
      }
      await NotificationService.scheduleEventNotifications(event);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add event: $e',
                style: const TextStyle(fontFamily: 'Inter')),
            backgroundColor: _terracotta,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _onSurface),
        title: const Text(
          'Add Event',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: _onSurface,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontFamily: 'Inter', color: _onSurface),
              decoration: _inputDecoration(
                context,
                label: 'Event title',
                hint: 'e.g. Data Structures Internal Exam',
                icon: Icons.title_rounded,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 24),

            // Category
            const Text(
              'Category',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _muted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: _categories.map((cat) {
                final isSelected = _category == cat.$1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _CategoryChip(
                      label: cat.$2,
                      icon: cat.$3,
                      selected: isSelected,
                      onTap: () => setState(() => _category = cat.$1),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Date picker
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: _surfaceHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 30,
                        color: _selectedDate != null ? _primary : _muted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? 'Select date & time'
                            : _formatSelectedDate(_selectedDate!),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          color: _selectedDate != null ? _onSurface : _muted,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: _muted.withValues(alpha: 0.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Feed selector — hidden in offline mode (personal only)
            if (!_isOffline) ...[
              const Text(
                'Add to',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _FeedChip(
                      label: 'Class Feed',
                      icon: Icons.group_rounded,
                      selected: !_isPersonal,
                      onTap: () => setState(() => _isPersonal = false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FeedChip(
                      label: 'Personal',
                      icon: Icons.lock_rounded,
                      selected: _isPersonal,
                      onTap: () => setState(() => _isPersonal = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ] else
              const SizedBox(height: 40),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: _onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: _onPrimary, strokeWidth: 2.5))
                    : const Text(
                        'Add Event',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: 'Inter', color: _muted),
      hintText: hint,
      hintStyle: TextStyle(
          fontFamily: 'Inter', color: _muted.withValues(alpha: 0.6)),
      prefixIcon: Icon(icon, size: 30, color: _muted),
      filled: true,
      fillColor: _surfaceHigh,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _terracotta),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _terracotta, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  String _formatSelectedDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} ${date.year} · $hour:$min';
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _primaryContainer : _surfaceHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _primary : _border,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: selected ? _primary : _muted),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? _primary : _muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FeedChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _primaryContainer : _surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _primary : _border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? _primary : _muted),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? _primary : _muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}