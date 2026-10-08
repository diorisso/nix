{ pkgs, ... }:
{
  home.packages = with pkgs; [
    libayatana-appindicator
    libGLX
    woeusb
    zenity
    appimage-run
    fuse
    libusb1
    (texlive.combine { inherit (texlive) scheme-basic titlesec; })
  ];
}
