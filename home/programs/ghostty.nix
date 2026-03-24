{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.ghostty = {
    enable = true;
    settings = {
      # Layout & window
      window-padding-x = 15;
      window-padding-y = 8;
      window-decoration = "none";
      background-opacity = 0.85;
      window-inherit-working-directory = true;
      gtk-single-instance = true;
      quit-after-last-window-closed = false;
      resize-overlay = "never";

      # Font
      font-size = 10;

      # Cursor
      cursor-style = "bar";
      cursor-style-blink = true;

      # Misc
      scrollback-limit = 10000;
      desktop-notifications = true;
      confirm-close-surface = false;
      bell-features = "audio";
      "keybind" = [
        "alt+v=new_split:right"
        "alt+s=new_split:down"
        "alt+h=goto_split:left"
        "alt+l=goto_split:right"
        "alt+j=goto_split:bottom"
        "alt+k=goto_split:top"
        "alt+n=new_tab"
        "ctrl+shift+r=reload_config"
      ];
    };
  };
}
