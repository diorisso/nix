{ config, pkgs, ... }:

{
  networking = {
    networkmanager.dns = "systemd-resolved";
    hostName = "nixos";
    nameservers = [ "1.1.1.1" "1.0.0.1" "8.8.8.8"];
  };
}
