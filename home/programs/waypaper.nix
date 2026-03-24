{ config, pkgs, ... }:

{
  home.packages = with pkgs; [ swww waypaper ];

  xdg.configFile."waypaper/config.ini".text = ''
    [Settings]
    folder = ${config.home.homeDirectory}/Projects/dotfiles-refs/walls
    backend = swww
    fill = fill
    sort = name
    subfolders = True
    show_hidden = False
    show_keywords = False
  '';
}
