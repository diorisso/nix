{ pkgs, ... }:
{
  home.packages = with pkgs; [
    go
    ruby
    nodejs
    libpq
    libyaml
    docker
    docker-compose
    nodejs
    pnpm
    vscode
    dbeaver-bin
    jetbrains.rider
    jetbrains.ruby-mine
    dotnet-sdk
    csharp-ls
    alacritty
    nerd-fonts.jetbrains-mono
    bruno
    bun
    openjdk
    tmux
  ];
}
