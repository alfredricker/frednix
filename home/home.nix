{ config, pkgs, ... }:

let
  allThemes = import ./themes.nix { inherit pkgs; };
  currentThemeName = import ./current-theme.nix;
  theme = allThemes.${currentThemeName};
in
{
  imports = [
    ./packages.nix
    ./programs/niri.nix
    ./programs/waybar.nix
    ./programs/ghostty.nix
    ./programs/bottom.nix
    ./programs/fish.nix
    ./programs/starship.nix
    ./programs/waypaper.nix
    ./programs/rofi.nix
    ./programs/nvim.nix
    ./programs/vscode.nix
  ];

  home.username = "fred";
  home.homeDirectory = "/home/fred";
  home.stateVersion = "25.11";

  home.shellAliases = {
    rmf = "command rm -rfI";
    rm = "trash-put";
    setmeta = "/home/fred/Media/Music/scripts/set_metadata.py";
    randomizetracks = "/home/fred/Media/Music/scripts/randomize_tracks.py";
  };

  programs.home-manager.enable = true;

  stylix = {
    enable = true;
    image = theme.wallpaper;
    base16Scheme = theme.base16Scheme;
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
      serif = {
        package = pkgs.liberation_ttf;
        name = "Liberation Serif";
      };
      sizes = {
        terminal = 13;
        applications = 12;
        desktop = 12;
        popups = 12;
      };
    };
    targets = {
      waybar.enable = false; # manual CSS
      rofi.enable = false; # manual rasi theme
      helix.enable = false; # manual theme in packages.nix
      ghostty.enable = true;
      gtk.enable = true;
    };
  };
}
