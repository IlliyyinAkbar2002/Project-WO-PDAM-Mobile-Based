import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/profile/profile_view_data.dart';

class PersonalDataPage extends StatelessWidget {
  final PersonalDataViewData? _data;

  const PersonalDataPage({super.key, required PersonalDataViewData data})
      : _data = data;

  factory PersonalDataPage.safe({
    Key? key,
    PersonalDataViewData? data,
  }) {
    return PersonalDataPage(
      key: key,
      data: data ?? ProfileViewDataResolver.defaultPersonalData,
    );
  }

  static const Color _iconColor = Color(0xff2d499b);
  static const Color _bgColor = Color(0xFFF4F6F9);
  static const Color _surfaceColor = Color(0xFFFEFEFE);
  static const Color _labelColor = Color(0xFF475467);
  static const Color _subtitleColor = Color(0xFF667085);
  static const Color _titleColor = Color(0xFF101828);

  PersonalDataViewData get data =>
      _data ?? ProfileViewDataResolver.defaultPersonalData;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _bgColor,
        body: Column(
          children: [
            _PersonalDataHeader(
              topInset: topInset,
              onBackTap: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
                child: Column(
                  children: [
                    _SectionContainer(
                      title: 'My Personal Data',
                      subtitle: 'Details about my personal data',
                      child: Column(
                        children: [
                          const _PhotoPreview(),
                          const SizedBox(height: 14),
                          _ReadOnlyField(
                            label: 'First Name',
                            icon: Icons.person_outline,
                            value: data.firstName,
                          ),
                          _ReadOnlyField(
                            label: 'Last Name',
                            icon: Icons.person_outline,
                            value: data.lastName,
                          ),
                          _ReadOnlyField(
                            label: 'Date of Birth',
                            icon: Icons.calendar_today_outlined,
                            value: data.birthDate,
                          ),
                          _ReadOnlyField(
                            label: 'Position',
                            icon: Icons.badge_outlined,
                            value: data.position,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SectionContainer(
                      title: 'Address',
                      subtitle: 'Your current domicile',
                      child: Column(
                        children: [
                          _ReadOnlyField(
                            label: 'Country',
                            icon: Icons.location_on_outlined,
                            value: data.country,
                          ),
                          _ReadOnlyField(
                            label: 'State',
                            icon: Icons.location_on_outlined,
                            value: data.state,
                          ),
                          _ReadOnlyField(
                            label: 'City',
                            icon: Icons.location_on_outlined,
                            value: data.city,
                          ),
                          _ReadOnlyField(
                            label: 'Full Address',
                            icon: Icons.home_outlined,
                            value: data.address,
                            maxLines: 4,
                            fixedHeight: 102,
                            showLeadingIconInsideField: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _PersonalDataHeader extends StatelessWidget {
  final double topInset;
  final VoidCallback onBackTap;

  const _PersonalDataHeader({required this.topInset, required this.onBackTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14, topInset + 12, 14, 12),
      decoration: const BoxDecoration(
        color: PersonalDataPage._surfaceColor,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEAECF0)),
        ),
      ),
      child: Row(
        children: [
          _CircleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBackTap,
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Personal Data',
                style: TextStyle(
                  color: PersonalDataPage._titleColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _SectionContainer extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionContainer({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PersonalDataPage._surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: PersonalDataPage._titleColor,
              fontSize: 23 / 1.64,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: PersonalDataPage._subtitleColor,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFB6C2EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 62),
            ),
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xff2d499b),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sync,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Upload Photo',
          style: TextStyle(
            color: PersonalDataPage._labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Format should be in .jpeg .png atleast\n800x800px and less than 5MB',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: PersonalDataPage._subtitleColor,
            fontSize: 10,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final int maxLines;
  final double? fixedHeight;
  final bool showLeadingIconInsideField;

  const _ReadOnlyField({
    required this.label,
    required this.icon,
    required this.value,
    this.maxLines = 1,
    this.fixedHeight,
    this.showLeadingIconInsideField = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: PersonalDataPage._labelColor,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            constraints: fixedHeight == null
                ? null
                : BoxConstraints(minHeight: fixedHeight!, maxHeight: fixedHeight!),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: PersonalDataPage._surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF98A2B3)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D101828),
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: maxLines > 1
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                if (showLeadingIconInsideField) ...[
                  Icon(icon, size: 20, color: PersonalDataPage._iconColor),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    value,
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PersonalDataPage._titleColor,
                      fontSize: 22 / 1.57,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF2F4F7),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, color: PersonalDataPage._iconColor, size: 16),
        ),
      ),
    );
  }
}
