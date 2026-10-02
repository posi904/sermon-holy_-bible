import 'package:flutter/material.dart';

import '../core/mock_data.dart';
import '../core/theme/app_theme.dart';

/// Signature golden-amber + warm-paper design tokens for the Prayer Journal UI.
/// Local mirror of the unified palette used by the other screens.
class _JournalGold {
  _JournalGold._();

  /// Warm paper surface (#FBF9F5) — matches AppColors.sepia.
  static const Color warmPaper = Color(0xFFFBF9F5);

  /// Crisp solid golden amber border used for cards and the Export button.
  static const BorderSide amberSide =
      BorderSide(color: AppColors.amber, width: 1.2);
}

/// Screen 3 — Dummy PDF / Journal preview.
///
/// Shows an A4-proportioned church-letterhead preview card (mocking the
/// exported sermon PDF) plus a spiritual streak tracker and a prayer
/// request journal — all backed by static mock data.
class DummyPdfJournalScreen extends StatelessWidget {
  const DummyPdfJournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sepia,
      // No app bar: the journal begins immediately beneath the safe area so all
      // three main screens share one consistent top rhythm.
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const Text(
              'Prayer Journal & Export',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal),
            ),
            const SizedBox(height: 16),
            const Text('PDF Preview', style: AppTextStyles.sectionLabel),
            const SizedBox(height: 8),
            const _A4LetterheadCard(),
            const SizedBox(height: 12),
            _buildExportRow(context),
            const SizedBox(height: 24),
            const Text('Bible Reading Streak',
                style: AppTextStyles.sectionLabel),
            const SizedBox(height: 8),
            const _StreakTrackerCard(),
            const SizedBox(height: 24),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('My Prayers', style: AppTextStyles.sectionLabel),
                Text('12 Total  •  8 Answered',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.charcoalMuted)),
              ],
            ),
            const SizedBox(height: 8),
            const _PrayerList(),
          ],
        ),
      ),
    );
  }

  Widget _buildExportRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            // Export stays secondary: warm paper face with a crisp 1.2px golden
            // amber outline and an amber label/icon.
            style: OutlinedButton.styleFrom(
              backgroundColor: _JournalGold.warmPaper,
              foregroundColor: AppColors.amber,
              side: _JournalGold.amberSide,
            ),
            onPressed: () {},
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: const Text('Export PDF'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            // The primary PDF action is now Share, painted in solid golden amber.
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: Colors.white,
            ),
            onPressed: () {},
            icon: const Icon(Icons.ios_share, size: 18),
            label: const Text('Share PDF'),
          ),
        ),
      ],
    );
  }
}

/// A visual mock of the exported A4 church-letterhead PDF page.
class _A4LetterheadCard extends StatelessWidget {
  const _A4LetterheadCard();

  @override
  Widget build(BuildContext context) {
    // A4 aspect ratio (210mm x 297mm) ≈ 0.707
    return AspectRatio(
      aspectRatio: 210 / 297,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.divider),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Letterhead header
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      color: AppColors.blue, shape: BoxShape.circle),
                  child:
                      const Icon(Icons.church, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        MockJournal.letterheadChurchName,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppColors.charcoal),
                      ),
                      Text(
                        MockJournal.letterheadSubtitle,
                        style: TextStyle(
                            fontSize: 9.5, color: AppColors.charcoalMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 12),
            const Text(
              MockJournal.sermonTitle,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.charcoal),
            ),
            const SizedBox(height: 4),
            const Text(
              '${MockJournal.serviceLine}  ·  ${MockJournal.dateLine}',
              style: TextStyle(fontSize: 10, color: AppColors.charcoalMuted),
            ),
            const SizedBox(height: 14),
            const Text('Key Points',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: AppColors.amber)),
            const SizedBox(height: 6),
            ...MockJournal.keyPoints.map(
              (point) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  ',
                        style:
                            TextStyle(fontSize: 11, color: AppColors.charcoal)),
                    Expanded(
                      child: Text(point,
                          style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.charcoal,
                              height: 1.3)),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.sepia,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    MockJournal.closingQuote,
                    style: TextStyle(
                        fontSize: 9.5,
                        fontStyle: FontStyle.italic,
                        color: AppColors.charcoal,
                        height: 1.4),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '— ${MockJournal.closingReference}',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerRight,
              child: Text('Page 1 of 1',
                  style:
                      TextStyle(fontSize: 8, color: AppColors.charcoalMuted)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakTrackerCard extends StatelessWidget {
  const _StreakTrackerCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: _JournalGold.amberSide,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_fire_department,
                      color: AppColors.amber),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${MockJournal.streakDays} Day Streak',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.charcoal),
                    ),
                    Text(
                      "Keep it going — read today's chapter",
                      style: TextStyle(
                          fontSize: 12, color: AppColors.charcoalMuted),
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(MockJournal.weekLabels.length, (i) {
                final done = MockJournal.weekCompletion[i];
                return Column(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: done ? AppColors.amber : AppColors.creamDark,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        done
                            ? Icons.local_fire_department
                            : Icons.circle_outlined,
                        size: 15,
                        color: done ? Colors.white : AppColors.charcoalMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(MockJournal.weekLabels[i],
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.charcoalMuted)),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerList extends StatefulWidget {
  const _PrayerList();

  @override
  State<_PrayerList> createState() => _PrayerListState();
}

class _PrayerListState extends State<_PrayerList> {
  // Local mutable copy so the "Answered" toggle actually reacts in the UI.
  late List<PrayerRequest> _prayers;

  @override
  void initState() {
    super.initState();
    _prayers = List.of(MockJournal.prayers);
  }

  void _toggleAnswered(int index) {
    setState(() {
      final p = _prayers[index];
      _prayers[index] = PrayerRequest(
        title: p.title,
        dateAdded: p.dateAdded,
        answered: !p.answered,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < _prayers.length; i++) ...[
          _buildPrayerTile(_prayers[i], i),
          if (i != _prayers.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildPrayerTile(PrayerRequest prayer, int index) {
    final bool answered = prayer.answered;
    return Card(
      // Each prayer row keeps a crisp 1.2px golden amber border so the journal
      // reads as one continuous set of warm amber frames.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: _JournalGold.amberSide,
      ),
      child: ListTile(
        leading: Icon(
          prayer.answered ? Icons.check_circle : Icons.hourglass_bottom,
          color: answered ? AppColors.amber : AppColors.charcoalMuted,
        ),
        title: Text(
          prayer.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text('Added ${prayer.dateAdded}',
            style: const TextStyle(fontSize: 11.5)),
        trailing: FilterChip(
          label: Text(answered ? 'Answered' : 'Waiting'),
          selected: answered,
          onSelected: (_) => _toggleAnswered(index),
          // Both badges use soft amber highlights: a stronger fill when the
          // prayer is answered, a gentle tint + hairline while waiting.
          backgroundColor: AppColors.amber.withValues(alpha: 0.08),
          selectedColor: AppColors.amber.withValues(alpha: 0.18),
          side: BorderSide(color: AppColors.amber.withValues(alpha: 0.4)),
          checkmarkColor: AppColors.amber,
          labelStyle: TextStyle(
            fontSize: 11.5,
            color: answered
                ? AppColors.amber
                : AppColors.amber.withValues(alpha: 0.72),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
