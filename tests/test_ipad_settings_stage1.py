#!/usr/bin/env python3
"""Source regression checks only. These do NOT execute UIKit or prove iPad compatibility.
Run: python3 tests/test_ipad_settings_stage1.py
"""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(name):
    return (ROOT / name).read_text(encoding="utf-8-sig")


def between(text, begin, end):
    start = text.index(begin)
    return text[start:text.index(end, start + len(begin))]


class IPadSettingsSourceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.main = read("DYYY.xm")
        cls.settings = read("DYYYSettingViewController.m")
        cls.native = read("DYYYSettings.xm")
        cls.helper = read("DYYYSettingsHelper.m")

    def test_retired_preferences_have_no_live_references(self):
        for key in ("DYYYScheduleStyle", "DYYYHideVideoProgress", "DYYYFilterTimeLimit"):
            for name, source in (("main", self.main), ("settings", self.settings),
                                 ("native", self.native), ("helper", self.helper)):
                with self.subTest(key=key, source=name):
                    self.assertNotIn(key, source)

    def test_duration_display_and_offset_are_retained(self):
        for source in (self.main, self.settings, self.native, self.helper):
            self.assertIn('DYYYShowScheduleDisplay', source)
            self.assertIn('DYYYTimelineVerticalPosition', source)
        self.assertIn('NSString *newLeftText = [self formatTimeFromSeconds:arg1];', self.main)
        self.assertIn('NSString *newRightText = [self formatTimeFromSeconds:arg2];', self.main)

    def test_settings_gesture_is_two_finger_double_tap(self):
        group = between(self.main, '%group DYYYSettingsGesture', '%hook AWEBaseListViewController')
        self.assertIn('UITapGestureRecognizer', group)
        self.assertNotIn('UILongPressGestureRecognizer', group)
        self.assertIn('gesture.numberOfTouchesRequired = 2;', group)
        self.assertIn('gesture.numberOfTapsRequired = 2;', group)
        self.assertIn('UIGestureRecognizerStateRecognized', group)
        self.assertIn('gesture.cancelsTouchesInView = NO;', group)
        self.assertIn('gesture.delaysTouchesEnded = NO;', group)
        self.assertIn('initWithWindowScene:', group)
        self.assertIn('objc_getAssociatedObject(self, &kDYYYSettingsDoubleTapGestureKey)', group)
        self.assertEqual(group.count('[window dyyy_installSettingsDoubleTapGesture];'), 2)
        self.assertIn('[self dyyy_installSettingsDoubleTapGesture];', group)

    def test_gesture_preserves_disable_switch_and_prevents_duplicate_settings(self):
        self.assertIn('if (!DYYYGetBool(@"DYYYDisableSettingsGesture"))', self.main)
        self.assertIn('禁用双指双击入口', self.native)
        self.assertNotIn('禁用双指长按入口', self.native)
        handler = between(self.main, '- (void)dyyy_handleSettingsDoubleTap:', '%new\n- (void)closeSettings:')
        self.assertIn('while (rootViewController)', handler)
        self.assertIn('[visibleController isKindOfClass:DYYYSettingViewController.class]', handler)
        self.assertIn('rootViewController.isBeingPresented', handler)

    def test_single_accordion_path_preserves_search_and_preferences(self):
        toggle = between(self.settings, '- (void)toggleSection:', '- (UITableViewCell *)tableView:')
        header = between(self.settings, '- (void)headerTapped:', '\n@end')
        self.assertIn('[self toggleSection:sender];', header)
        self.assertIn('self.isSearching', toggle)
        self.assertIn('[self.view endEditing:YES];', toggle)
        self.assertIn('[self.expandedSections removeAllObjects];', toggle)
        self.assertIn('if (!wasExpanded)', toggle)
        self.assertIn('reloadSections:changedSections', toggle)
        self.assertNotIn('NSUserDefaults', toggle)
        self.assertNotIn('setBool:', toggle)
        self.assertNotIn('expandedSections', header)
        rows = between(self.settings, '- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:', '- (void)toggleSection:')
        self.assertIn('if (self.isSearching)', rows)
        self.assertIn('return self.settingSections[section].count;', rows)

    def test_other_filters_and_color_integration_remain(self):
        for token in ('shouldFilterKeywords', 'shouldFilterProp', 'shouldFilterUser',
                      'shouldFilterHDR', 'shouldFilterLowLikes'):
            self.assertIn(token, self.main)
        self.assertNotIn('shouldFilterTime', self.main)
        self.assertIn('[DYYYAwemeXColors applyTimestampColorToLabel:label];', self.main)
        self.assertIn('[DYYYAwemeXColors refreshTimestampLabels];', self.settings)
        self.assertIn('DYYYAwemeXColors.m', read('Makefile'))

    def test_both_modern_style_hooks_have_conservative_fallback(self):
        for name in ('AWELongPressPanelABSettings', 'AWEModernLongPressPanelUIConfig'):
            hook = between(self.main, '%hook ' + name, '%end')
            self.assertIn('if (!DYYYGetBool(@"DYYYEnableModernPanel"))', hook)
            self.assertIn('if (forceBlur && forceDark)', hook)
            self.assertIn('else if (!forceBlur && !forceDark)', hook)
            self.assertTrue(hook.rstrip().endswith('return %orig;\n}'))

    def test_only_three_settings_rows_removed_against_local_backup(self):
        backup = ROOT / 'DYYYSettingViewController.m.20260924-ipad1.bak'
        if not backup.exists():
            self.skipTest('Local pre-edit backup absent; optional row comparison skipped')
        pattern = r'itemWithTitle:@"[^"]+" key:@"([^"]+)"'
        before = re.findall(pattern, backup.read_text(encoding='utf-8-sig'))
        after = re.findall(pattern, self.settings)
        removed = {'DYYYScheduleStyle', 'DYYYHideVideoProgress', 'DYYYFilterTimeLimit'}
        self.assertEqual(after, [key for key in before if key not in removed])


if __name__ == '__main__':
    unittest.main(verbosity=2)
