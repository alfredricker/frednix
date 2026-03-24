{ config, pkgs, lib, ... }:

let
  c = config.lib.stylix.colors;
in
{
  programs.niri.package = pkgs.niri;

  programs.niri.settings = {
    prefer-no-csd = true;

    layout = {
      gaps = 8;
      center-focused-column = "on-overflow";
      default-column-width = { proportion = 0.5; };

      border = {
        enable = true;
        width = 1;
        active.color = "#${c.base0D}80";
        inactive.color = "#${c.base01}";
        urgent.color = "#${c.base08}";
      };

      focus-ring.enable = false;

      shadow = {
        enable = true;
        spread = 4;
        color = "#00000070";
        inactive-color = "#00000040";
      };
    };

    window-rules = [
      {
        geometry-corner-radius = {
          top-left = 10.0;
          top-right = 10.0;
          bottom-left = 10.0;
          bottom-right = 10.0;
        };
        clip-to-geometry = true;
      }
      {
        matches = [{ app-id = "^chromium-browser$"; }];
        default-column-width = { proportion = 1.0; };
        opacity = 0.93;
      }
    ];

    spawn-at-startup = [
      { command = [ "swww-daemon" ]; }
      { command = [ "waybar" ]; }
    ];

    binds = with config.lib.niri.actions; {
        # Mod key is usually Super (Windows key)
        "Mod+Return".action = spawn "ghostty";
	"Mod+B".action = spawn "chromium";
	"Mod+O".action = spawn "obsidian";
	"Mod+P".action = spawn "pycharm";                                                            
        "Mod+W".action = close-window;
        "Mod+Shift+W".action = spawn "waypaper";
        "Mod+Shift+Space".action = spawn "sh" "-c" "pkill waybar || waybar";
        "Mod+Space".action = spawn "rofi" "-show" "drun";
        "Mod+plus".action = set-column-width "+10%";
        "Mod+minus".action = set-column-width "-10%";
        "Mod+Shift+E".action = quit;                                                                    
                                                                                                        
        # Focus windows
        "Mod+WheelScrollUp".action = focus-column-left;                                                             
        "Mod+WheelScrollDown".action = focus-column-right;                                                            
        "Mod+Up".action = focus-window-down;                                                             
        "Mod+Down".action = focus-window-up;                                                               
                                                                                                        
        # Move windows
        "Mod+Shift+H".action = move-column-left;                                                        
        "Mod+Shift+L".action = move-column-right;
                                                                                                        
        # Workspaces
        "Mod+1".action = focus-workspace 1;                                                             
        "Mod+2".action = focus-workspace 2;
	"Mod+3".action = focus-workspace 3;
      };
    };
}
