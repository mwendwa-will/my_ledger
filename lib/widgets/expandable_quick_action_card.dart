import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ExpandableQuickActionCard extends StatefulWidget {

  const ExpandableQuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.collapsedChild,
    required this.expandedChild,
    this.color,
  });
  final IconData icon;
  final String title;
  final Widget collapsedChild;
  final Widget expandedChild;
  final Color? color;

  @override
  State<ExpandableQuickActionCard> createState() => _ExpandableQuickActionCardState();
}

class _ExpandableQuickActionCardState extends State<ExpandableQuickActionCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      color: widget.color ?? Theme.of(context).cardColor,
      child: Semantics(
        label: '${widget.title}, currently ${_isExpanded ? 'expanded' : 'collapsed'}',
        button: true,
        child: InkWell(
          onTap: _toggleExpanded,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(widget.icon, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: AppConstants.smallPadding),
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    Tooltip(
                      message: _isExpanded ? 'Collapse' : 'Expand',
                      child: Icon(
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                SizeTransition(
                  sizeFactor: _animation,
                  axisAlignment: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppConstants.defaultPadding),
                    child: widget.expandedChild,
                  ),
                ),
                if (!_isExpanded) // Show collapsed child only when not expanded
                  widget.collapsedChild,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
