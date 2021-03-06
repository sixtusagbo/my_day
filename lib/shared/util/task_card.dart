import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:my_day/services/task_service.dart';
import 'package:my_day/shared/util/loading.dart';

import '../../models/task.dart';
import '../../providers/task_notifier.dart';
import '../constants.dart';
import 'circular_gradient_icon.dart';
import 'color_dot.dart';

class TaskCard extends StatefulWidget {
  /// This widget displays a [Task]
  /// with mini-details.

  const TaskCard({
    Key? key,
    required this.task,
    this.press,
    this.isDoneScreen = false,
    this.isMarkDoneScreen = false,
  }) : super(key: key);

  final Task task;
  final Function()? press;
  final bool isDoneScreen, isMarkDoneScreen;

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.press,
      child: Card(
        margin: EdgeInsets.only(bottom: 20.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(miDefaultSize),
        ),
        elevation: 3.0,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            vertical: miDefaultSize * 0.8,
            horizontal: miDefaultSize * 0.6,
          ),
          leading: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 0,
                left: 0,
                child: widget.isDoneScreen
                    ? SvgPicture.asset(
                        "assets/icons/done_task.svg",
                        color: Color(miIcons[widget.task.icon]?.colorCode ??
                                0xffffffff)
                            .withOpacity(1.0),
                      )
                    : ColorDot(
                        color: Color(
                            miIcons[widget.task.icon]?.colorCode ?? 0xffffffff),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: miDefaultSize * 0.4),
                child: CircularGradientIcon(
                  icon: miIcons[widget.task.icon],
                ),
              ),
            ],
          ),
          title: Text(
            widget.task.title,
            style: TextStyle(
              fontSize: miDefaultSize * 1.2,
              overflow: TextOverflow.ellipsis,
              color: miTextColor,
            ),
          ),
          trailing: widget.isMarkDoneScreen
              ? Consumer(
                  builder: (context, outerRef, child) {
                    final asyncTaskProvider =
                        outerRef.watch(futureTaskNotifierProvider);

                    return asyncTaskProvider.when(
                      data: (data) {
                        return ProviderScope(
                          overrides: [
                            taskNotifierProvider.overrideWithValue(data)
                          ],
                          child: Consumer(
                            builder: (context, ref, child) {
                              final tasksProvider =
                                  ref.watch(taskNotifierProvider.notifier);

                              return InkWell(
                                onTap: () async {
                                  setState(() => _isChecked = !_isChecked);

                                  if (_isChecked) {
                                    await saveChanges(tasksProvider, true);
                                  } else {
                                    await saveChanges(tasksProvider, false);
                                  }
                                },
                                child: Ink(
                                  width: miDefaultSize * 3,
                                  height: miDefaultSize * 3,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        miDefaultSize * 0.6),
                                    color: const Color(0xffffffff),
                                    border: Border.all(
                                        color: const Color(0x33181743)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0x1afe1e9a),
                                        offset: Offset(0, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: _isChecked
                                      ? Padding(
                                          padding: const EdgeInsets.all(
                                              miDefaultSize * 0.7),
                                          child: SvgPicture.asset(
                                            "assets/icons/selected.svg",
                                          ),
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                        );
                      },
                      error: (_, stack) => Center(child: Text(_.toString())),
                      loading: () => const Loading(),
                    );
                  },
                )
              : Column(
                  children: [
                    Text(
                      DateFormat('d MMM').format(widget.task.schedule),
                      style: TextStyle(
                        fontFamily: "Lato Black",
                        fontSize: miDefaultSize * 1.2,
                        color: miTextBoldColor,
                      ),
                    ),
                    SizedBox(height: miDefaultSize - 4),
                    Text(
                      DateFormat.Hm().format(widget.task.schedule),
                      style: TextStyle(
                        fontFamily: "Lato Light",
                        color: miTextColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  saveChanges(TaskNotifier tasksProvider, bool status) async {
    Future.delayed(Duration(milliseconds: 50), () async {
      TaskService _taskService = TaskService();

      final result =
          await _taskService.setTaskStatusInDatabase(widget.task.id, status);

      if (result == "success") {
        tasksProvider.updateTaskStatusInState(widget.task.id, status);
      } else {
        throw ("failed to update db");
      }
    });
  }
}
