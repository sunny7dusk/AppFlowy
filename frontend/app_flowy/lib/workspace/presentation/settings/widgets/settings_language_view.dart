import 'package:app_flowy/workspace/presentation/widgets/locale_picker/locale_picker.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsLanguageView extends StatelessWidget {
  const SettingsLanguageView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: Provider.of<AppearanceSettingModel>(context, listen: true),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  LocaleKeys.settings_menu_language.tr(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const LanguageSelectorDropdown(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LanguageSelectorDropdown extends StatefulWidget {
  const LanguageSelectorDropdown({
    Key? key,
  }) : super(key: key);

  @override
  State<LanguageSelectorDropdown> createState() => _LanguageSelectorDropdownState();
}

class _LanguageSelectorDropdownState extends State<LanguageSelectorDropdown> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8, right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: const LocalePicker(),
    );
  }
}
