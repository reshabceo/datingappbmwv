import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StepCalendarPicker extends StatefulWidget {
  final DateTime? initialDate;
  final Function(DateTime) onDateSelected;
  final VoidCallback? onCancel;

  const StepCalendarPicker({
    Key? key,
    this.initialDate,
    required this.onDateSelected,
    this.onCancel,
  }) : super(key: key);

  @override
  State<StepCalendarPicker> createState() => _StepCalendarPickerState();
}

class _StepCalendarPickerState extends State<StepCalendarPicker> {
  int _currentStep = 0; // 0: Year, 1: Month, 2: Day
  int? _selectedYear;
  int? _selectedMonth;
  int? _selectedDay;
  
  final int _currentYear = DateTime.now().year;
  final int _minAge = 18;
  final int _maxAge = 100;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _selectedYear = widget.initialDate!.year;
      _selectedMonth = widget.initialDate!.month;
      _selectedDay = widget.initialDate!.day;
    }
  }

  int get _minYear => _currentYear - _maxAge;
  int get _maxYear => _currentYear - _minAge;

  List<int> get _availableYears {
    List<int> years = [];
    for (int year = _maxYear; year >= _minYear; year--) {
      years.add(year);
    }
    return years;
  }

  List<int> get _availableMonths {
    return List.generate(12, (index) => index + 1);
  }

  List<int> get _availableDays {
    if (_selectedYear == null || _selectedMonth == null) return [];
    
    int daysInMonth = DateTime(_selectedYear!, _selectedMonth! + 1, 0).day;
    return List.generate(daysInMonth, (index) => index + 1);
  }

  String get _monthName {
    if (_selectedMonth == null) return '';
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[_selectedMonth! - 1];
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Complete selection
      if (_selectedYear != null && _selectedMonth != null && _selectedDay != null) {
        final selectedDate = DateTime(_selectedYear!, _selectedMonth!, _selectedDay!);
        widget.onDateSelected(selectedDate);
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      widget.onCancel?.call();
    }
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _selectedYear != null;
      case 1:
        return _selectedMonth != null;
      case 2:
        return _selectedDay != null;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400.h,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _previousStep,
                  icon: Icon(
                    _currentStep == 0 ? Icons.close : Icons.arrow_back,
                    color: Colors.grey[600],
                  ),
                ),
                Expanded(
                  child: Text(
                    _getStepTitle(),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (_canProceed)
                  TextButton(
                    onPressed: _nextStep,
                    child: Text(
                      _currentStep == 2 ? 'Done' : 'Next',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  SizedBox(width: 60.w),
              ],
            ),
          ),
          
          // Progress indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: List.generate(3, (index) {
                return Expanded(
                  child: Container(
                    height: 4.h,
                    margin: EdgeInsets.symmetric(horizontal: 2.w),
                    decoration: BoxDecoration(
                      color: index <= _currentStep 
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          // Content
          Expanded(
            child: _buildStepContent(),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Select Year';
      case 1:
        return 'Select Month';
      case 2:
        return 'Select Day';
      default:
        return '';
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildYearSelector();
      case 1:
        return _buildMonthSelector();
      case 2:
        return _buildDaySelector();
      default:
        return Container();
    }
  }

  Widget _buildYearSelector() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _availableYears.length,
      itemBuilder: (context, index) {
        final year = _availableYears[index];
        final isSelected = _selectedYear == year;
        final age = _currentYear - year;
        
        return ListTile(
          title: Text(
            '$year',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            'Age: $age years old',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14.sp,
            ),
          ),
          trailing: isSelected ? Icon(
            Icons.check_circle,
            color: Theme.of(context).primaryColor,
          ) : null,
          selected: isSelected,
          onTap: () {
            setState(() {
              _selectedYear = year;
            });
          },
        );
      },
    );
  }

  Widget _buildMonthSelector() {
    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 8.h,
      ),
      itemCount: _availableMonths.length,
      itemBuilder: (context, index) {
        final month = _availableMonths[index];
        final isSelected = _selectedMonth == month;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedMonth = month;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected 
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: isSelected 
                    ? Theme.of(context).primaryColor
                    : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                _getMonthAbbreviation(month),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected 
                      ? Theme.of(context).primaryColor
                      : Colors.grey[700],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDaySelector() {
    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
        crossAxisSpacing: 4.w,
        mainAxisSpacing: 4.h,
      ),
      itemCount: _availableDays.length,
      itemBuilder: (context, index) {
        final day = _availableDays[index];
        final isSelected = _selectedDay == day;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay = day;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected 
                  ? Theme.of(context).primaryColor
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isSelected 
                    ? Theme.of(context).primaryColor
                    : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected 
                      ? Colors.white
                      : Colors.grey[700],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
