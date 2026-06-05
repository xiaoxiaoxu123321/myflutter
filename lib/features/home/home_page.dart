import 'package:flutter/material.dart';
import '../../shared/bottom_tabs.dart';
import '../../shared/track_card.dart';
import '../assets/asset_page.dart';
import '../gift/gift_page.dart';
import '../nfc/hero_panel.dart';
import '../plaza/plaza_page.dart';
import '../profile/profile_page.dart';
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: const [
          Image(
            image: AssetImage('assets/images/backages.png'),
            fit: BoxFit.cover,
          ),
          ColoredBox(color: Color(0x44050611)),
          SafeArea(child: HomeShell()),
        ],
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth > 520 ? 420.0 : double.infinity;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                children: [
                  Expanded(
                    child: switch (_selectedIndex) {
                      1 => const AssetPageBody(),
                      2 => const GiftPageBody(),
                      3 => PlazaPageBody(
                        onOpenGift: () => setState(() => _selectedIndex = 2),
                      ),
                      4 => const ProfilePageBody(),
                      _ => const HeroPanel(),
                    },
                  ),
                  if (_selectedIndex == 0) ...[
                    const SizedBox(height: 10),
                    const TrackCard(),
                  ],
                  const SizedBox(height: 10),
                  BottomTabs(
                    selectedIndex: _selectedIndex,
                    onSelected: (index) => setState(() {
                      _selectedIndex = index;
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
