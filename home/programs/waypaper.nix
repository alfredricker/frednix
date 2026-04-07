{ config, pkgs, ... }:

{
  home.packages = with pkgs; [ awww waypaper ];

  xdg.configFile."waypaper/config.ini".text = ''
    [Settings]
    folder = ${config.home.homeDirectory}/Projects/dotfiles-refs/walls
    backend = awww
    fill = fill
    sort = name
    subfolders = True
    show_hidden = False
    show_keywords = False
  '';
}
