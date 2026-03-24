{ config, pkgs, ... }:

let
  c = config.lib.stylix.colors;
  font = config.stylix.fonts.monospace.name;
  theme = pkgs.writeText "rofi-theme.rasi" ''
    * {
      bg:     #${c.base00}e6;
      bg-alt: #${c.base01}99;
      bg-sel: #${c.base02}cc;
      fg:     #${c.base05};
      fg-dim: #${c.base03};
      accent: #${c.base0D};

      background-color: transparent;
      text-color:       @fg;
      font:             "${font} 12";
    }

    window {
      background-color: @bg;
      border:           1px;
      border-color:     #${c.base0D}4d;
      border-radius:    14px;
      width:            620px;
      padding:          10px;
    }

    mainbox {
      background-color: transparent;
      spacing:          8px;
      children:         [inputbar, listview];
    }

    inputbar {
      background-color: @bg-alt;
      border-radius:    9px;
      padding:          10px 14px;
      spacing:          8px;
      children:         [prompt, entry];
    }

    prompt {
      text-color: @accent;
    }

    entry {
      text-color:        @fg;
      placeholder:       "Search...";
      placeholder-color: @fg-dim;
    }

    listview {
      background-color: transparent;
      lines:            8;
      columns:          1;
      spacing:          3px;
      scrollbar:        false;
      fixed-height:     false;
    }

    element {
      background-color: transparent;
      border-radius:    7px;
      padding:          8px 10px;
      spacing:          10px;
      children:         [element-icon, element-text];
    }

    element normal.normal,
    element alternate.normal {
      background-color: transparent;
      text-color:       @fg;
    }

    element selected.normal {
      background-color: @bg-sel;
      text-color:       @accent;
    }

    element-icon {
      size:           22px;
      vertical-align: 0.5;
    }

    element-text {
      vertical-align: 0.5;
      text-color:     inherit;
    }
  '';
in
{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    terminal = "${pkgs.ghostty}/bin/ghostty";
    theme = "${theme}";
    extraConfig = {
      modi = "drun,run";
      show-icons = true;
      drun-display-format = "{name}";
      display-drun = " Apps";
      display-run = " Run";
    };
  };
}
