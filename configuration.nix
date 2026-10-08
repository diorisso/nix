{
  config,
  pkgs,
  inputs,
  ...
}:
let
  dwm-custom = pkgs.dwm.override {
    conf = ./dwm/config.h;
    patches = [ ./dwm/gaps.patch ];
  };
in {
  imports = [
    ./hardware-configuration.nix
    ./modules/networking.nix
  ];

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

virtualisation.docker.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  time.timeZone = "America/Sao_Paulo";

  location = {
    provider = "manual";
    latitude = -23.55;
    longitude = -46.63;
  };

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.desktopManager.gnome.enable = true;

  services.xserver.windowManager.dwm = {
    enable = true;
    package = dwm-custom;
    extraSessionCommands = ''
      ${pkgs.feh}/bin/feh --bg-fill /home/dio/Wallpapers/694117.png &
      ${pkgs.picom}/bin/picom --backend xrender --daemon >/dev/null 2>&1 || true
      ${pkgs.redshift}/bin/redshift -O 4500 -m randr >/dev/null 2>&1 || true
      while true; do
        ${pkgs.xorg.xsetroot}/bin/xsetroot -name "$(${pkgs.coreutils}/bin/date '+%a %d/%m %H:%M')"
        ${pkgs.coreutils}/bin/sleep 30
      done &
    '';
  };

  services.xserver.xkb = {
    layout = "br";
    variant = "abnt2";
  };

  services.picom = {
    enable = true;
    backend = "xrender";
  };

  services.redshift = {
    enable = false;
    temperature = {
      day = 6500;
      night = 4500;
    };
  };

  services.xserver.displayManager.sessionCommands = ''
    ${pkgs.xorg.xset}/bin/xset -dpms
    ${pkgs.xorg.xset}/bin/xset s off
    ${pkgs.xorg.xset}/bin/xset s noblank
    for output in $(${pkgs.xorg.xrandr}/bin/xrandr | ${pkgs.gawk}/bin/awk '/ connected/{print $1}'); do
      ${pkgs.xorg.xrandr}/bin/xrandr --output "$output" --rate 120 >/dev/null 2>&1 || true
    done
  '';

  console.keyMap = "br-abnt2";

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.dio = {
    isNormalUser = true;
    description = "dio";
    extraGroups = ["networkmanager" "wheel" "docker"];
    shell = pkgs.zsh;
    packages = with pkgs; [];
  };

  programs.hyprland.enable = true;
  programs.steam.enable = true;
  programs.zsh.enable = true;
  programs.nix-ld.enable = true;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {inherit inputs;};
    users = {
      "dio" = import ./home.nix;
    };
  };

  nixpkgs.config.allowUnfree = true;

  nixpkgs.config.permittedInsecurePackages = [
    "qtwebengine-5.15.19"
  ];

  environment.systemPackages = with pkgs; [
    vim
    neovim
    dwm-custom
    dmenu
    redshift
    feh
    ghostty
    steam
    yt-dlp
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  system.stateVersion = "25.11";
}
