import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Keep in sync with `version:` in pubspec.yaml.
const String kAppVersionName = '1.0.0';
const String kAppBuildNumber = '1';
const String kAppName = 'Holy Bible';

/// Settings > About Us. Everything here is static and works offline.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Widget _card(String title, Widget child) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: ReaderPalette.card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: ReaderPalette.cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: ReaderPalette.inkSoft)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  static TextStyle get _body =>
      TextStyle(fontSize: 15, height: 1.6, color: ReaderPalette.ink);

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 9, right: 10),
              child: Icon(Icons.circle, size: 5, color: ReaderPalette.gold),
            ),
            Expanded(child: Text(text, style: _body)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReaderPalette.canvas,
      appBar: AppBar(
        backgroundColor: ReaderPalette.canvas,
        foregroundColor: ReaderPalette.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('About Us',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              decoration: BoxDecoration(
                color: ReaderPalette.chipSelected,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: ReaderPalette.pulseBorder),
              ),
              child: Column(
                children: [
                  Icon(Icons.menu_book_rounded,
                      size: 34, color: ReaderPalette.medallionInk),
                  SizedBox(height: 10),
                  Text(kAppName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: ReaderPalette.ink)),
                  SizedBox(height: 4),
                  Text('Version $kAppVersionName ($kAppBuildNumber)',
                      style: TextStyle(
                          fontSize: 13, color: ReaderPalette.inkSoft)),
                ],
              ),
            ),
            _card(
              'Our mission',
              Text('Distraction-free Word for Believers.',
                  style: TextStyle(
                      fontSize: 17,
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                      color: ReaderPalette.ink)),
            ),
            _card(
              'What you get',
              Column(
                children: [
                  _bullet(
                      'The Bible in Telugu, English and Hindi, side by side or one at a time.'),
                  _bullet(
                      'Sermon notes for live services, saved on your device.'),
                  _bullet('A calm parchment page made for long reading.'),
                ],
              ),
            ),
            _card(
              'Privacy summary',
              Column(
                children: [
                  _bullet(
                      'No account, no sign-in, no ads and no analytics or tracking.'),
                  _bullet(
                      'The app does not use the internet. It requests no Android permissions.'),
                  _bullet(
                      'Your sermon notes and reflections stay in a private database on your phone and are never uploaded.'),
                  _bullet(
                      'Uninstalling the app deletes your notes. There is no cloud copy.'),
                ],
              ),
            ),
            _card(
              'Open-source licenses',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'This app is built with Flutter and open-source packages. View their licenses.',
                      style: _body),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => showLicensePage(
                      context: context,
                      applicationName: kAppName,
                      applicationVersion: kAppVersionName,
                    ),
                    icon: Icon(Icons.description_outlined,
                        size: 18, color: ReaderPalette.gold),
                    label: Text('View licenses',
                        style: TextStyle(color: ReaderPalette.gold)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: ReaderPalette.pulseBorder),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
