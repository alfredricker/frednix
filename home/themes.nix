{ pkgs }:

let
  mkWallpaper = color: pkgs.runCommand "wallpaper.png" {
    nativeBuildInputs = [ pkgs.imagemagick ];
  } ''magick -size 2560x1440 xc:"#${color}" "$out"'';
in
{
  noctalia = {
    wallpaper = mkWallpaper "070722";
    base16Scheme = {
      scheme = "Noctalia";
      author = "noctalia";
      base00 = "070722"; # background
      base01 = "11112d"; # darker surface
      base02 = "21215F"; # selection / highlight bg
      base03 = "7c80b4"; # muted / comments
      base04 = "b8bfe8"; # light muted fg
      base05 = "f3edf7"; # main foreground
      base06 = "eff0ff"; # lighter fg
      base07 = "ffffff"; # brightest
      base08 = "FD4663"; # red / error
      base09 = "ffb86c"; # orange
      base0A = "fff59b"; # yellow accent
      base0B = "9BFECE"; # cyan / green
      base0C = "9BFECE"; # cyan
      base0D = "a9aefe"; # lavender / blue (primary accent)
      base0E = "c4a7ff"; # purple
      base0F = "FD4663"; # dark red
    };
  };

  tokyo-night = {
    wallpaper = mkWallpaper "1a1b26";
    base16Scheme = {
      scheme = "Tokyo Night";
      author = "enkia";
      base00 = "1a1b26";
      base01 = "16161e";
      base02 = "2f3549";
      base03 = "444b6a";
      base04 = "787c99";
      base05 = "a9b1d6";
      base06 = "cbccd1";
      base07 = "d5d6db";
      base08 = "f7768e";
      base09 = "ff9e64";
      base0A = "e0af68";
      base0B = "9ece6a";
      base0C = "b4f9f8";
      base0D = "7aa2f7";
      base0E = "bb9af7";
      base0F = "f7768e";
    };
  };

  catppuccin-mocha = {
    wallpaper = mkWallpaper "1e1e2e";
    base16Scheme = {
      scheme = "Catppuccin Mocha";
      author = "catppuccin";
      base00 = "1e1e2e";
      base01 = "181825";
      base02 = "313244";
      base03 = "45475a";
      base04 = "585b70";
      base05 = "cdd6f4";
      base06 = "f5c2e7";
      base07 = "b4befe";
      base08 = "f38ba8";
      base09 = "fab387";
      base0A = "f9e2af";
      base0B = "a6e3a1";
      base0C = "94e2d5";
      base0D = "89b4fa";
      base0E = "cba6f7";
      base0F = "f38ba8";
    };
  };

  gruvbox-dark = {
    wallpaper = mkWallpaper "282828";
    base16Scheme = {
      scheme = "Gruvbox Dark";
      author = "morhetz";
      base00 = "282828";
      base01 = "3c3836";
      base02 = "504945";
      base03 = "665c54";
      base04 = "bdae93";
      base05 = "d5c4a1";
      base06 = "ebdbb2";
      base07 = "fbf1c7";
      base08 = "fb4934";
      base09 = "fe8019";
      base0A = "fabd2f";
      base0B = "b8bb26";
      base0C = "8ec07c";
      base0D = "83a598";
      base0E = "d3869b";
      base0F = "d65d0e";
    };
  };

  nord = {
    wallpaper = mkWallpaper "2e3440";
    base16Scheme = {
      scheme = "Nord";
      author = "arcticicestudio";
      base00 = "2e3440";
      base01 = "3b4252";
      base02 = "434c5e";
      base03 = "4c566a";
      base04 = "d8dee9";
      base05 = "e5e9f0";
      base06 = "eceff4";
      base07 = "8fbcbb";
      base08 = "bf616a";
      base09 = "d08770";
      base0A = "ebcb8b";
      base0B = "a3be8c";
      base0C = "88c0d0";
      base0D = "81a1c1";
      base0E = "b48ead";
      base0F = "bf616a";
    };
  };
}
