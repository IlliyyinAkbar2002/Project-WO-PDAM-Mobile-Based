part of '../landing/landing_page.dart';

/// Navigation list shown for regular users
/// Displays menu items in a vertical list format
class _NavigationList extends StatelessWidget {
  final int? selectedPicId;
  final int? selectedUserId;

  const _NavigationList({
    required this.selectedPicId,
    required this.selectedUserId,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColor>()!;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7), // background color from Figma
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC7C7C7), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grabber handle
          Container(
            width: 36,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x4D3C3C43), // rgba(60,60,67,0.3)
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 8),

          // Menu Items
          _NavigationListItem(
            label: 'Jurnal',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Jurnal coming soon'),
                  backgroundColor: colors.primary[600],
                ),
              );
            },
          ),
          const SizedBox(height: 15),
          _NavigationListItem(
            label: 'Work Order',
            onTap: () {
              if (selectedUserId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Please select User ID first'),
                    backgroundColor: colors.warning,
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AssigneeWorkOrderPage(userId: selectedUserId!),
                ),
              );
            },
            isHighlighted: true,
          ),
          const SizedBox(height: 15),
          _NavigationListItem(
            label: 'IT Support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('IT Support coming soon'),
                  backgroundColor: colors.primary[600],
                ),
              );
            },
          ),
          const SizedBox(height: 15),
          _NavigationListItem(
            label: 'Kupon E-BBM',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Kupon E-BBM coming soon'),
                  backgroundColor: colors.primary[600],
                ),
              );
            },
          ),
          const SizedBox(height: 15),
          _NavigationListItem(
            label: 'SPPD',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('SPPD coming soon'),
                  backgroundColor: colors.primary[600],
                ),
              );
            },
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }
}

class _NavigationListItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isHighlighted;

  const _NavigationListItem({
    required this.label,
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFC7C7C7), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Roboto Condensed',
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: isHighlighted
                        ? const Color(0xFF2D499B)
                        : const Color(0xFF000000),
                    height: 1.33, // line-height: 24px / font-size: 18px
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isHighlighted
                      ? const Color(0xFF2D499B)
                      : const Color(0xFF000000),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
