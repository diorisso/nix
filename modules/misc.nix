{ pkgs, ... }:
{
  home.packages = with pkgs; [
    libayatana-appindicator
    libGLX
    appimage-run
  ];
}
