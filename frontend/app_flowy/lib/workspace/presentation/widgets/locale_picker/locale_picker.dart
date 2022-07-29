import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:app_flowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/language.dart';
import 'package:flowy_infra_ui/flowy_infra_ui_web.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LocaleActionItem extends ActionItem {
  Locale given;

  LocaleActionItem(this.given);
  @override
  Widget? get icon => null;

  @override
  String get name => languageFromLocale(given);

  Locale get locale => given;
}

class LocalePickerActionSheet extends ActionList<LocaleActionItem> with FlowyOverlayDelegate {
  late final List<Locale> _items;
  final Function(dartz.Option<LocaleActionItem>) onSelected;
  final BuildContext context;

  LocalePickerActionSheet({Key? key, required this.onSelected, required this.context});

  @override
  FlowyOverlayDelegate? get delegate => this;

  @override
  List<LocaleActionItem> get items => _items.map((curr) => LocaleActionItem(curr)).toList();

  @override
  void Function(dartz.Option<LocaleActionItem> p1) get selectCallback => (result) {
        result.fold(() => onSelected(dartz.none()), (a) => onSelected(dartz.some(a)));
      };

  LocalePickerActionSheet buildLocaleList() {
    _items = EasyLocalization.of(context)!.supportedLocales.map((e) => e).toList();
    return this;
  }
}

class LocalePicker extends StatelessWidget {
  const LocalePicker({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (dialogContext) {
      return TextButton(
        onPressed: () {
          final actionSheet = LocalePickerActionSheet(
                  onSelected: (given) {
                    final getLocale = given.fold(() => null, (a) => a);
                    context.read<AppearanceSettingModel>().setLocale(context, getLocale!.given);
                  },
                  context: context)
              .buildLocaleList();
          actionSheet.show(context, anchorContext: dialogContext);
        },
        child: Text(languageFromLocale(context.read<AppearanceSettingModel>().locale)),
      );
    });
  }
}
