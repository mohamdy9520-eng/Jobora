import 'package:flutter/material.dart';

enum CvTipCategory {
  structure,
  summary,
  experience,
  skills,
  ats,
  education,
  projects,
  contact,
  writing,
  design,
  mistakes,
  linkedin,
}

class CvTipMeta {
  final int id;
  final CvTipCategory category;
  final IconData icon;
  const CvTipMeta(this.id, this.category, this.icon);
}

/// Static, offline CV tips. The text lives in ar.json / en.json under
/// cv_tip_<id>_title and cv_tip_<id>_message.
///
/// To add a tip: append ONE entry here (next free id) + two keys in each
/// language file. Never renumber existing ids.
///
/// The order below is deliberately interleaved (consecutive tips come from
/// different categories) so the daily rotation never shows three tips about
/// the same topic.
class CvTipsRepository {
  CvTipsRepository._();

  static const List<CvTipMeta> all = [
    CvTipMeta(1, CvTipCategory.structure, Icons.description_outlined),
    CvTipMeta(2, CvTipCategory.experience, Icons.bar_chart_outlined),
    CvTipMeta(3, CvTipCategory.ats, Icons.manage_search_outlined),
    CvTipMeta(4, CvTipCategory.summary, Icons.person_outline),
    CvTipMeta(5, CvTipCategory.contact, Icons.alternate_email),
    CvTipMeta(6, CvTipCategory.writing, Icons.bolt_outlined),
    CvTipMeta(7, CvTipCategory.skills, Icons.category_outlined),
    CvTipMeta(8, CvTipCategory.design, Icons.text_fields),
    CvTipMeta(9, CvTipCategory.mistakes, Icons.spellcheck),
    CvTipMeta(10, CvTipCategory.structure, Icons.swap_vert),
    CvTipMeta(11, CvTipCategory.experience, Icons.emoji_events_outlined),
    CvTipMeta(12, CvTipCategory.ats, Icons.title),
    CvTipMeta(13, CvTipCategory.education, Icons.school_outlined),
    CvTipMeta(14, CvTipCategory.linkedin, Icons.link),
    CvTipMeta(15, CvTipCategory.projects, Icons.folder_special_outlined),
    CvTipMeta(16, CvTipCategory.writing, Icons.short_text),
    CvTipMeta(17, CvTipCategory.experience, Icons.vertical_align_top),
    CvTipMeta(18, CvTipCategory.skills, Icons.checklist),
    CvTipMeta(19, CvTipCategory.mistakes, Icons.verified_outlined),
    CvTipMeta(20, CvTipCategory.design, Icons.picture_as_pdf_outlined),
    CvTipMeta(21, CvTipCategory.summary, Icons.badge_outlined),
    CvTipMeta(22, CvTipCategory.ats, Icons.grid_off_outlined),
    CvTipMeta(23, CvTipCategory.structure, Icons.date_range_outlined),
    CvTipMeta(24, CvTipCategory.experience, Icons.format_list_bulleted),
    CvTipMeta(25, CvTipCategory.writing, Icons.wrap_text),
    CvTipMeta(26, CvTipCategory.contact, Icons.phone_outlined),
    CvTipMeta(27, CvTipCategory.experience, Icons.build_outlined),
    CvTipMeta(28, CvTipCategory.education, Icons.workspace_premium_outlined),
    CvTipMeta(29, CvTipCategory.projects, Icons.account_tree_outlined),
    CvTipMeta(30, CvTipCategory.summary, Icons.do_not_disturb_alt_outlined),
    CvTipMeta(31, CvTipCategory.skills, Icons.star_outline),
    CvTipMeta(32, CvTipCategory.ats, Icons.abc),
    CvTipMeta(33, CvTipCategory.experience, Icons.volunteer_activism_outlined),
    CvTipMeta(34, CvTipCategory.structure, Icons.vertical_align_top),
    CvTipMeta(35, CvTipCategory.writing, Icons.history_edu_outlined),
    CvTipMeta(36, CvTipCategory.mistakes, Icons.privacy_tip_outlined),
    CvTipMeta(37, CvTipCategory.design, Icons.space_bar),
    CvTipMeta(38, CvTipCategory.experience, Icons.trending_up),
    CvTipMeta(39, CvTipCategory.mistakes, Icons.content_cut),
    CvTipMeta(40, CvTipCategory.writing, Icons.record_voice_over_outlined),
    CvTipMeta(41, CvTipCategory.structure, Icons.timelapse_outlined),
    CvTipMeta(42, CvTipCategory.summary, Icons.edit_note_outlined),
    CvTipMeta(43, CvTipCategory.experience, Icons.trending_up),
    CvTipMeta(44, CvTipCategory.skills, Icons.speed_outlined),
    CvTipMeta(45, CvTipCategory.ats, Icons.picture_as_pdf_outlined),
    CvTipMeta(46, CvTipCategory.education, Icons.menu_book_outlined),
    CvTipMeta(47, CvTipCategory.projects, Icons.link),
    CvTipMeta(48, CvTipCategory.contact, Icons.location_on_outlined),
    CvTipMeta(49, CvTipCategory.writing, Icons.backspace_outlined),
    CvTipMeta(50, CvTipCategory.design, Icons.format_bold),
    CvTipMeta(51, CvTipCategory.mistakes, Icons.remove_circle_outline),
    CvTipMeta(52, CvTipCategory.linkedin, Icons.campaign_outlined),
    CvTipMeta(53, CvTipCategory.education, Icons.pending_actions_outlined),
    CvTipMeta(54, CvTipCategory.projects, Icons.person_pin_outlined),
    CvTipMeta(55, CvTipCategory.contact, Icons.account_circle_outlined),
    CvTipMeta(56, CvTipCategory.writing, Icons.shuffle),
    CvTipMeta(57, CvTipCategory.design, Icons.palette_outlined),
    CvTipMeta(58, CvTipCategory.mistakes, Icons.translate),
    CvTipMeta(59, CvTipCategory.linkedin, Icons.manage_search),
    CvTipMeta(60, CvTipCategory.structure, Icons.title),
    CvTipMeta(61, CvTipCategory.summary, Icons.flag_outlined),
    CvTipMeta(62, CvTipCategory.experience, Icons.groups_outlined),
    CvTipMeta(63, CvTipCategory.skills, Icons.filter_alt_outlined),
    CvTipMeta(64, CvTipCategory.ats, Icons.content_paste_outlined),
    CvTipMeta(65, CvTipCategory.mistakes, Icons.find_replace),
    CvTipMeta(66, CvTipCategory.linkedin, Icons.thumb_up_outlined),
    CvTipMeta(67, CvTipCategory.structure, Icons.star_outline),
    CvTipMeta(68, CvTipCategory.summary, Icons.sync_alt),
    CvTipMeta(69, CvTipCategory.experience, Icons.leaderboard_outlined),
    CvTipMeta(70, CvTipCategory.skills, Icons.history_toggle_off),
    CvTipMeta(71, CvTipCategory.ats, Icons.vertical_align_top),
    CvTipMeta(72, CvTipCategory.education, Icons.emoji_events_outlined),
    CvTipMeta(73, CvTipCategory.projects, Icons.lightbulb_outline),
    CvTipMeta(74, CvTipCategory.contact, Icons.how_to_reg_outlined),
    CvTipMeta(75, CvTipCategory.writing, Icons.pin_outlined),
    CvTipMeta(76, CvTipCategory.design, Icons.smartphone_outlined),
    CvTipMeta(77, CvTipCategory.skills, Icons.code),
    CvTipMeta(78, CvTipCategory.ats, Icons.format_list_bulleted),
    CvTipMeta(79, CvTipCategory.education, Icons.hourglass_bottom_outlined),
    CvTipMeta(80, CvTipCategory.projects, Icons.insights_outlined),
    CvTipMeta(81, CvTipCategory.contact, Icons.chat_outlined),
    CvTipMeta(82, CvTipCategory.writing, Icons.help_outline),
    CvTipMeta(83, CvTipCategory.design, Icons.format_align_left),
    CvTipMeta(84, CvTipCategory.mistakes, Icons.travel_explore),
    CvTipMeta(85, CvTipCategory.linkedin, Icons.work_outline),
    CvTipMeta(86, CvTipCategory.structure, Icons.swap_vert),
    CvTipMeta(87, CvTipCategory.summary, Icons.build_outlined),
    CvTipMeta(88, CvTipCategory.experience, Icons.paid_outlined),
    CvTipMeta(89, CvTipCategory.writing, Icons.compress),
    CvTipMeta(90, CvTipCategory.design, Icons.description_outlined),
    CvTipMeta(91, CvTipCategory.mistakes, Icons.exit_to_app),
    CvTipMeta(92, CvTipCategory.linkedin, Icons.push_pin_outlined),
    CvTipMeta(93, CvTipCategory.structure, Icons.filter_2),
    CvTipMeta(94, CvTipCategory.summary, Icons.domain),
    CvTipMeta(95, CvTipCategory.experience, Icons.apartment_outlined),
    CvTipMeta(96, CvTipCategory.skills, Icons.language),
    CvTipMeta(97, CvTipCategory.ats, Icons.linear_scale),
    CvTipMeta(98, CvTipCategory.education, Icons.public),
    CvTipMeta(99, CvTipCategory.projects, Icons.article_outlined),
    CvTipMeta(100, CvTipCategory.contact, Icons.mail_outline),
  ];

  /// Returns [count] tips that rotate once per day: the same all day,
  /// different tomorrow. Deterministic, so no storage is needed.
  static List<CvTipMeta> tipsOfTheDay({int count = 3, DateTime? now}) {
    if (all.isEmpty || count <= 0) return const [];
    final d = now ?? DateTime.now();
    final dayOfYear = d.difference(DateTime(d.year, 1, 1)).inDays;
    final start = (dayOfYear * count) % all.length;
    final n = count < all.length ? count : all.length;
    return [for (var i = 0; i < n; i++) all[(start + i) % all.length]];
  }
}