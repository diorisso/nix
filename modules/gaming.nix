{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ppsspp
    pcsx2
    libretro.swanstation
  ];
}
