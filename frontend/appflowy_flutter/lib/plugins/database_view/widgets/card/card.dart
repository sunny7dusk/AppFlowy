import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/row/action.dart';
import 'package:appflowy_backend/protobuf/flowy-database/row_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'card_bloc.dart';
import 'cells/card_cell.dart';
import 'card_cell_builder.dart';
import 'container/accessory.dart';
import 'container/card_container.dart';

class Card<CustomCardData> extends StatefulWidget {
  final RowPB row;
  final String viewId;
  final String fieldId;
  final CustomCardData? cardData;
  final bool isEditing;
  final RowCache rowCache;
  final CardCellBuilder<CustomCardData> cellBuilder;
  final void Function(BuildContext) openCard;
  final VoidCallback onStartEditing;
  final VoidCallback onEndEditing;
  final CardConfiguration<CustomCardData>? configuration;

  const Card({
    required this.row,
    required this.viewId,
    required this.fieldId,
    required this.isEditing,
    required this.rowCache,
    required this.cellBuilder,
    required this.openCard,
    required this.onStartEditing,
    required this.onEndEditing,
    this.cardData,
    this.configuration,
    Key? key,
  }) : super(key: key);

  @override
  State<Card<CustomCardData>> createState() => _CardState<CustomCardData>();
}

class _CardState<T> extends State<Card<T>> {
  late CardBloc _cardBloc;
  late EditableRowNotifier rowNotifier;
  late PopoverController popoverController;
  AccessoryType? accessoryType;

  @override
  void initState() {
    rowNotifier = EditableRowNotifier(isEditing: widget.isEditing);
    _cardBloc = CardBloc(
      viewId: widget.viewId,
      groupFieldId: widget.fieldId,
      isEditing: widget.isEditing,
      row: widget.row,
      rowCache: widget.rowCache,
    )..add(const BoardCardEvent.initial());

    rowNotifier.isEditing.addListener(() {
      if (!mounted) return;
      _cardBloc.add(BoardCardEvent.setIsEditing(rowNotifier.isEditing.value));

      if (rowNotifier.isEditing.value) {
        widget.onStartEditing();
      } else {
        widget.onEndEditing();
      }
    });

    popoverController = PopoverController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cardBloc,
      child: BlocBuilder<CardBloc, BoardCardState>(
        buildWhen: (previous, current) {
          // Rebuild when:
          // 1.If the length of the cells is not the same
          // 2.isEditing changed
          if (previous.cells.length != current.cells.length ||
              previous.isEditing != current.isEditing) {
            return true;
          }

          // 3.Compare the content of the cells. The cells consists of
          // list of [BoardCellEquatable] that extends the [Equatable].
          return !listEquals(previous.cells, current.cells);
        },
        builder: (context, state) {
          return AppFlowyPopover(
            controller: popoverController,
            triggerActions: PopoverTriggerFlags.none,
            constraints: BoxConstraints.loose(const Size(140, 200)),
            margin: const EdgeInsets.all(6),
            direction: PopoverDirection.rightWithCenterAligned,
            popupBuilder: (popoverContext) => _handlePopoverBuilder(
              context,
              popoverContext,
            ),
            child: BoardCardContainer(
              buildAccessoryWhen: () => state.isEditing == false,
              accessoryBuilder: (context) {
                return [
                  _CardEditOption(rowNotifier: rowNotifier),
                  _CardMoreOption(),
                ];
              },
              openAccessory: _handleOpenAccessory,
              openCard: (context) => widget.openCard(context),
              child: _CardContent<T>(
                rowNotifier: rowNotifier,
                cellBuilder: widget.cellBuilder,
                cells: state.cells,
                cardConfiguration: widget.configuration,
                cardData: widget.cardData,
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleOpenAccessory(AccessoryType newAccessoryType) {
    accessoryType = newAccessoryType;
    switch (newAccessoryType) {
      case AccessoryType.edit:
        break;
      case AccessoryType.more:
        popoverController.show();
        break;
    }
  }

  Widget _handlePopoverBuilder(
    BuildContext context,
    BuildContext popoverContext,
  ) {
    switch (accessoryType!) {
      case AccessoryType.edit:
        throw UnimplementedError();
      case AccessoryType.more:
        return RowActions(
          rowData: context.read<CardBloc>().rowInfo(),
        );
    }
  }

  @override
  Future<void> dispose() async {
    rowNotifier.dispose();
    _cardBloc.close();
    super.dispose();
  }
}

class _CardContent<CustomCardData> extends StatelessWidget {
  final CardCellBuilder<CustomCardData> cellBuilder;
  final EditableRowNotifier rowNotifier;
  final List<BoardCellEquatable> cells;
  final CardConfiguration<CustomCardData>? cardConfiguration;
  final CustomCardData? cardData;
  const _CardContent({
    required this.rowNotifier,
    required this.cellBuilder,
    required this.cells,
    required this.cardData,
    this.cardConfiguration,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _makeCells(context, cells),
    );
  }

  List<Widget> _makeCells(
    BuildContext context,
    List<BoardCellEquatable> cells,
  ) {
    final List<Widget> children = [];
    // Remove all the cell listeners.
    rowNotifier.unbind();

    cells.asMap().forEach(
      (int index, BoardCellEquatable cell) {
        final isEditing = index == 0 ? rowNotifier.isEditing.value : false;
        final cellNotifier = EditableCardNotifier(isEditing: isEditing);

        if (index == 0) {
          // Only use the first cell to receive user's input when click the edit
          // button
          rowNotifier.bindCell(cell.identifier, cellNotifier);
        }

        final child = Padding(
          key: cell.identifier.key(),
          padding: const EdgeInsets.only(left: 4, right: 4),
          child: cellBuilder.buildCell(
            cellId: cell.identifier,
            cellNotifier: cellNotifier,
            cardConfiguration: cardConfiguration,
            cardData: cardData,
          ),
        );

        children.add(child);
      },
    );
    return children;
  }
}

class _CardMoreOption extends StatelessWidget with CardAccessory {
  _CardMoreOption({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: svgWidget(
        'grid/details',
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  @override
  AccessoryType get type => AccessoryType.more;
}

class _CardEditOption extends StatelessWidget with CardAccessory {
  final EditableRowNotifier rowNotifier;
  const _CardEditOption({
    required this.rowNotifier,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: svgWidget(
        'editor/edit',
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  @override
  void onTap(BuildContext context) => rowNotifier.becomeFirstResponder();

  @override
  AccessoryType get type => AccessoryType.edit;
}
