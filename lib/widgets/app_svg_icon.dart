import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Centralized, high-precision SVG Vector Icon system for the entire application.
/// Provides theme-adaptive, scalable, crisp vector graphics with 100% offline support.
class AppSvgIcon extends StatelessWidget {
  final String svgData;
  final double size;
  final Color? color;
  final String? semanticLabel;

  const AppSvgIcon({
    super.key,
    required this.svgData,
    this.size = 20.0,
    this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? IconTheme.of(context).color ?? Colors.black87;
    return SvgPicture.string(
      svgData,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
    );
  }

  // ==========================================
  // NAVIGATION & CORE SCREENS ICONS
  // ==========================================

  /// Dashboard Overview (4-grid interactive cards)
  static Widget dashboard({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'Dashboard',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <rect x="3" y="3" width="8" height="8" rx="2"/>
        <rect x="13" y="3" width="8" height="5" rx="2"/>
        <rect x="13" y="10" width="8" height="11" rx="2"/>
        <rect x="3" y="13" width="8" height="8" rx="2"/>
      </svg>''',
    );
  }

  /// Production Entry (Stitch needle, cloth & thread)
  static Widget production({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'Production Entry',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8l-6-6zm1 7V3.5L18.5 7H15zM8 12h8v2H8v-2zm0 4h8v2H8v-2zm-1-7h4v2H7V9z"/>
      </svg>''',
    );
  }

  /// Employees & Upad (Factory workers & team)
  static Widget employees({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'Employees',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5s-3 1.34-3 3 1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z"/>
      </svg>''',
    );
  }

  /// Accounts / Khata (Financial ledger & wallet)
  static Widget accounts({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'Accounts',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M21 18v1c0 1.1-.9 2-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h14c1.1 0 2 .9 2 2v1h-9a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h9zm-9-2h10V8H12v8zm4-2.5c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5z"/>
      </svg>''',
    );
  }

  /// Materials Entry (Raw material inventory, threads & spools)
  static Widget materials({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'Materials',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M12 2l9 4.5v11L12 22l-9-4.5v-11L12 2zm0 2.24L5.48 7.5 12 10.76l6.52-3.26L12 4.24zM4.5 9.07v6.69l7 3.5V12.57l-7-3.5zm9 10.19l7-3.5V9.07l-7 3.5v6.69z"/>
      </svg>''',
    );
  }

  /// Analytics & Charts (Live production trends)
  static Widget analytics({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'Analytics',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-7 14h-2v-4h2v4zm0-6h-2V7h2v4zm4 6h-2V9h2v8zm-8 0H6v-2h2v2z"/>
      </svg>''',
    );
  }

  /// Excel Export / Import (Spreadsheet sheets)
  static Widget excel({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'Excel',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M19 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V5a2 2 0 0 0-2-2zM9 17H6v-3h3v3zm0-5H6V9h3v3zm0-5H6V5h3v2zm5 10h-3v-3h3v3zm0-5h-3V9h3v3zm0-5h-3V5h3v2zm5 10h-3v-3h3v3zm0-5h-3V9h3v3zm0-5h-3V5h3v2z"/>
      </svg>''',
    );
  }

  /// Machines (Industrial multi-head embroidery machine)
  static Widget machines({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'Machines',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M20 6h-4V4c0-1.11-.89-2-2-2h-4c-1.11 0-2 .89-2 2v2H4c-1.11 0-1.99.89-1.99 2L2 19c0 1.11.89 2 2 2h16c1.11 0 2-.89 2-2V8c0-1.11-.89-2-2-2zm-6 0h-4V4h4v2zm-2 9c-1.66 0-3-1.34-3-3s1.34-3 3-3 3 1.34 3 3-1.34 3-3 3z"/>
      </svg>''',
    );
  }

  /// Rates & Heads (Currency rupee & tariff pricing)
  static Widget rates({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'Rates and Heads',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M13.66 7C13.1 5.82 11.9 5 10.5 5H6V3h12v2h-3.26c.48.58.81 1.26.96 2H18v2h-2.12c-.68 2.36-2.84 4-5.38 4H9.09l5.66 6H12l-6-6.38V9h4.5c1.38 0 2.5-1.12 2.5-2H6V7h7.66z"/>
      </svg>''',
    );
  }

  /// Recycle Bin (Safe soft deletion & recovery)
  static Widget recycleBin({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'Recycle Bin',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M16 9v10H8V9h8m-1.5-6h-5l-1 1H5v2h14V4h-3.5l-1-1zM18 7H6v12c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7z"/>
      </svg>''',
    );
  }

  /// Deep Archive Safe Vault (Permanent Non-destructive Storage)
  static Widget vault({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'Safe Vault',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm-6 9c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm3.1-9H8.9V6c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2z"/>
      </svg>''',
    );
  }

  /// Settings (Gear cog)
  static Widget settings({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'Settings',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.09.63-.09.94s.02.64.07.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z"/>
      </svg>''',
    );
  }

  // ==========================================
  // UTILITY & ACTION ICONS
  // ==========================================

  /// Collapse Sidebar (Panel layout with left sidebar indicator)
  static Widget collapse({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'Collapse Sidebar',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2zm0 4v10h5V8H4zm7 10h9V8h-9v10zm-4-6l-2 2 2 2v-4z"/>
      </svg>''',
    );
  }

  /// Expand Sidebar (Panel layout with open indicator)
  static Widget expand({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'Expand Sidebar',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2zm0 4v10h2V8H4zm4 10h12V8H8v10zm2-5h3V7l4 4-4 4v-2h-3v-2z"/>
      </svg>''',
    );
  }

  /// Real Screen Back Icon (Clean universally recognized Arrow Back, no text needed)
  static Widget back({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'Back',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z"/>
      </svg>''',
    );
  }

  /// Light Mode (Sun)
  static Widget sun({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'Light Mode',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M12 7c-2.76 0-5 2.24-5 5s2.24 5 5 5 5-2.24 5-5-2.24-5-5-5zM2 13h2c.55 0 1-.45 1-1s-.45-1-1-1H2c-.55 0-1 .45-1 1s.45 1 1 1zm18 0h2c.55 0 1-.45 1-1s-.45-1-1-1h-2c-.55 0-1 .45-1 1s.45 1 1 1zM11 2v2c0 .55.45 1 1 1s1-.45 1-1V2c0-.55-.45-1-1-1s-1 .45-1 1zm0 18v2c0 .55.45 1 1 1s1-.45 1-1v-2c0-.55-.45-1-1-1s-1 .45-1 1zM5.99 4.58a.996.996 0 0 0-1.41 0 .996.996 0 0 0 0 1.41l1.06 1.06c.39.39 1.03.39 1.41 0s.39-1.03 0-1.41L5.99 4.58zm12.37 12.37a.996.996 0 0 0-1.41 0 .996.996 0 0 0 0 1.41l1.06 1.06c.39.39 1.03.39 1.41 0a.996.996 0 0 0 0-1.41l-1.06-1.06zm1.06-10.96a.996.996 0 0 0 0-1.41.996.996 0 0 0-1.41 0l-1.06 1.06c-.39.39-.39 1.03 0 1.41s1.03.39 1.41 0l1.06-1.06zM7.05 18.36a.996.996 0 0 0 0-1.41.996.996 0 0 0-1.41 0l-1.06 1.06c-.39.39-.39 1.03 0 1.41s1.03.39 1.41 0l1.06-1.06z"/>
      </svg>''',
    );
  }

  /// Dark Mode (Moon)
  static Widget moon({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'Dark Mode',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M12.3 2a10 10 0 0 0-1.9 19.8 10 10 0 0 0 11.6-11.6A10 10 0 0 1 12.3 2z"/>
      </svg>''',
    );
  }

  /// Calendar / Date
  static Widget calendar({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'Calendar',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M19 4h-1V2h-2v2H8V2H6v2H5c-1.11 0-1.99.9-1.99 2L3 20a2 2 0 0 0 2 2h14c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 16H5V10h14v10zm0-12H5V6h14v2zm-7 5h5v5h-5v-5z"/>
      </svg>''',
    );
  }

  /// Operator / Person
  static Widget user({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'User',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/>
      </svg>''',
    );
  }

  /// Add / Plus
  static Widget add({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'Add',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z"/>
      </svg>''',
    );
  }

  /// Edit / Pencil
  static Widget edit({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'Edit',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04c.39-.39.39-1.02 0-1.41l-2.34-2.34c-.39-.39-1.02-.39-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z"/>
      </svg>''',
    );
  }

  /// Delete / Trash
  static Widget delete({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'Delete',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z"/>
      </svg>''',
    );
  }

  /// Restore / Undo
  static Widget restore({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'Restore',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M13 3a9 9 0 0 0-9 9H1l3.89 3.89.07.14L9 12H6c0-3.87 3.13-7 7-7s7 3.13 7 7-3.13 7-7 7c-1.93 0-3.68-.79-4.94-2.06l-1.42 1.42A8.954 8.954 0 0 0 13 21a9 9 0 0 0 9-9 9 9 0 0 0-9-9zm-1 5v5l4.28 2.54.72-1.21-3.5-2.08V8H12z"/>
      </svg>''',
    );
  }

  /// Search / Magnifying Glass
  static Widget search({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'Search',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M15.5 14h-.79l-.28-.27A6.471 6.471 0 0 0 16 9.5 6.5 6.5 0 1 0 9.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z"/>
      </svg>''',
    );
  }

  /// Filter / Funnel
  static Widget filter({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'Filter',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M10 18h4v-2h-4v2zM3 6v2h18V6H3zm3 7h12v-2H6v2z"/>
      </svg>''',
    );
  }

  /// Download / Export
  static Widget exportIcon({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'Export',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M19 9h-4V3H9v6H5l7 7 7-7zM5 18v2h14v-2H5z"/>
      </svg>''',
    );
  }

  /// Upload / Import
  static Widget importIcon({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'Import',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M9 16h6v-6h4l-7-7-7 7h4zm-4 2h14v2H5z"/>
      </svg>''',
    );
  }

  /// Print / Slip / Voucher
  static Widget printIcon({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'Print Receipt',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M19 8H5c-1.66 0-3 1.34-3 3v6h4v4h12v-4h4v-6c0-1.66-1.34-3-3-3zm-3 11H8v-5h8v5zm3-7c-.55 0-1-.45-1-1s.45-1 1-1 1 .45 1 1-.45 1-1 1zm-1-9H6v4h12V3z"/>
      </svg>''',
    );
  }

  /// Check / Verified
  static Widget check({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'Check',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/>
      </svg>''',
    );
  }

  /// Info / Guide
  static Widget info({double size = 20, Color? color}) {
    return AppSvgIcon(
      size: size,
      color: color,
      semanticLabel: 'Information',
      svgData: '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z"/>
      </svg>''',
    );
  }
}
