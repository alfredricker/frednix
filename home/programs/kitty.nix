{ config, pkgs, lib, ... }:

{
  programs.kitty = {
    enable = true;
    settings = {
      # Glass / transparency
      background_opacity = lib.mkForce "0.88";
      background_blur = 32;
      dynamic_background_color = "yes";

      # Layout
      window_padding_width = 16;
      hide_window_decorations = "yes";

      # Cursor
      cursor_shape = "beam";
      cursor_blink_interval = "0";
      cursor_beam_thickness = "1.8";

      # Tabs
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      tab_bar_min_tabs = 2;

      # Misc
      scrollback_lines = 10000;
      enable_audio_bell = "no";
      confirm_os_window_close = 0;
      copy_on_select = "clipboard";
      strip_trailing_spaces = "smart";
    };
  };
}
