import 'package:task_domain/task_domain.dart';
import 'package:task_presentation/task_presentation.dart';

class TaskEditScreen extends StatelessWidget {
  const TaskEditScreen({
    super.key,
    this.taskId,
    this.cachedTask,
  }) : assert(cachedTask == null ? true : taskId != null);

  final UuidValue? taskId;
  final Task? cachedTask;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TaskEditViewModelProvider(
        taskId: taskId,
        cachedTask: cachedTask,
        child: BlocBuilder<TaskEditViewModel, TaskEditState>(
          builder: (context, state) {
            return state.map(
              loadedTask: (state) {
                return _TaskEditPage(
                  state.textController,
                  state.importance,
                  state.deadline,
                  task: cachedTask,
                );
              },
              newTask: (state) {
                return _TaskEditPage(
                  state.textController,
                  state.importance,
                  state.deadline,
                );
              },
              errorTask: (state) => FailureDecoratorWidget(state.failure),
              loadingTask: (state) => LoaderWidget(),
            );
          },
        ),
      ),
    );
  }
}

class _TaskEditPage extends StatelessWidget {
  const _TaskEditPage(
    this.textController,
    this.importance,
    this.deadline, {
    this.task,
  });

  final Task? task;
  final TextEditingController textController;
  final Importance importance;
  final DateTime? deadline;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverLayoutBuilder(
          builder: (context, constraints) {
            final scrolled = constraints.scrollOffset > 0;
            return SliverAppBar(
              pinned: true,
              backgroundColor: scrolled
                  ? context.theme.appBarTheme.backgroundColor
                  : context.theme.scaffoldBackgroundColor,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => onClose(context),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => onSaveTask(context),
                  child: Text(context.localizations.saveTask.toUpperCase()),
                ),
              ],
            );
          },
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              _Editor(textController: textController),
              _ImportanceSelector(
                importance: importance,
                onChanged: context.read<TaskEditViewModel>().setImportance,
              ),
              const Divider(
                indent: 16,
                endIndent: 16,
              ),
              SwitchListTile(
                value: deadline != null,
                onChanged: (value) => onDeadlineChanged(context, value),
                title: Text(context.localizations.taskDeadline),
                subtitle: deadline == null
                    ? null
                    : Text(
                        DateFormat.yMMMMd(context.localizations.locale)
                            .format(deadline!),
                        style: context.textTheme.bodyText2!.copyWith(
                          color: context.theme.colorBlue,
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              ListTile(
                enabled: task != null,
                iconColor: context.theme.colorRed,
                textColor: context.theme.colorRed,
                leading: const Icon(Icons.delete),
                title: Text(context.localizations.taskDelete),
                onTap: () => onDeleteTask(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String getFormattedDeadlineText(BuildContext context) {
    return DateFormat.yMMMMd(context.localizations.locale).format(deadline!);
  }

  void onClose(BuildContext context) {
    context.sp.getRequired<TaskNavigatorMixin>().showTaskList();
  }

  Future<void> onSaveTask(BuildContext context) async {
    final navigator = context.sp.getRequired<TaskNavigatorMixin>();

    if (task == null) {
      await context.read<TaskEditViewModel>().createTask();
    } else {
      await context.read<TaskEditViewModel>().editTask();
    }

    navigator.showTaskList();
  }

  void onDeleteTask(BuildContext context) {
    context.read<TaskEditViewModel>().deleteTask();
    context.sp.getRequired<TaskNavigatorMixin>().showTaskList();
  }

  Future<void> onDeadlineChanged(BuildContext context, bool value) async {
    FocusScope.of(context).unfocus();

    final viewModel = context.read<TaskEditViewModel>();
    if (value) {
      final dateTime = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now().subtract(const Duration(days: 100)),
        lastDate: DateTime.now().add(const Duration(days: 100)),
      );

      return viewModel.setDeadline(dateTime);
    }

    viewModel.setDeadline(null);
  }
}

class _ImportanceSelector extends StatelessWidget {
  const _ImportanceSelector({
    required this.importance,
    required this.onChanged,
  });

  final Importance importance;
  final ValueChanged<Importance?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ListTile(
          title: Text(context.localizations.taskImportance),
          subtitle: Text(
            TaskImportanceLocalization.localize(context, importance),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Importance>(
              items: [
                // TODO: оформить по дизайну
                DropdownMenuItem(
                  value: Importance.none,
                  child: Text(
                    TaskImportanceLocalization.localize(
                      context,
                      Importance.none,
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: Importance.low,
                  child: Text(
                    TaskImportanceLocalization.localize(
                      context,
                      Importance.low,
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: Importance.high,
                  child: Text(
                    "!! ${TaskImportanceLocalization.localize(
                      context,
                      Importance.high,
                    )}",
                    style: context.textTheme.bodyText1!.copyWith(
                      color: getHighImportanceColor(context),
                    ),
                  ),
                ),
              ],
              isExpanded: true,
              iconSize: 0,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _Editor extends StatelessWidget {
  const _Editor({
    required this.textController,
  });

  final TextEditingController? textController;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: textController,
        autofocus: true,
        maxLines: null,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
          hintText: context.localizations.taskEditHint,
          // TODO: magic numbers
          constraints: const BoxConstraints(minHeight: 104),
        ),
      ),
    );
  }
}
