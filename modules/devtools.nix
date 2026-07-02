{ pkgs, ... }:
{
  home.packages = with pkgs; [
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
    bruno
    bun
  ];
}
