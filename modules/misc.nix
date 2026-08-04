{ pkgs, ... }:
{
  home.packages = with pkgs; [
    libayatana-appindicator
    libGLX
    appimage-run
    (texlive.combine { inherit (texlive) scheme-basic titlesec; })
  ];
}
