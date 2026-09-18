class DesktopBreakpoints {
  static const double mobileMax = 600;
  static const double sidebarExpandedMin = 1100;

  static bool isMobile(double width) => width < mobileMax;

  static bool isSidebarCollapsed(double width) =>
      width >= mobileMax && width < sidebarExpandedMin;
}
