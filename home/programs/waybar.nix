{ config, pkgs, lib, ... }:

let
  c = config.lib.stylix.colors;
  font = config.stylix.fonts.monospace.name;
  weatherScript = pkgs.writeShellScript "waybar-weather" ''
    ${pkgs.curl}/bin/curl -sf "https://wttr.in/?format=%c+%t" 2>/dev/null || echo "?"
  '';
in
{
  programs.waybar = {
    enable = true;

    settings = [{
      layer = "top";
      position = "top";
      margin-top = 8;
      margin-left = 10;
      margin-right = 10;
      spacing = 4;

      modules-left = [ "niri/workspaces" "niri/window" ];
      modules-center = [ "clock" ];
      modules-right = [ "custom/weather" "temperature" "cpu" "memory" "bluetooth" "network" "pulseaudio" "tray" ];

      "niri/workspaces" = {
        format = "{icon}";
        format-icons = {
          active = "●";
          default = "○";
        };
      };

      "niri/window" = {
        max-length = 60;
      };

      clock = {
        format = " {:%H:%M}";
        format-alt = " {:%A, %B %d}";
        tooltip-format = "<tt><small>{calendar}</small></tt>";
      };

      "custom/weather" = {
        exec = "${weatherScript}";
        interval = 1800;
        format = "{}";
        tooltip = false;
      };

      temperature = {
        hwmon-path = "/sys/class/hwmon/hwmon1/temp1_input";
        format = " {temperatureC}°C";
        critical-threshold = 80;
        format-critical = " {temperatureC}°C";
        tooltip = false;
      };

      cpu = {
        format = " {usage}%";
        interval = 2;
        tooltip = false;
      };

      memory = {
        format = " {percentage}%";
        interval = 5;
        tooltip-format = "{used:0.1f}G / {total:0.1f}G";
      };

      bluetooth = {
        format = " {status}";
        format-connected = " {device_alias}";
        format-disabled = "";
        tooltip-format = "{controller_alias} — {controller_address}";
        tooltip-format-connected = "{controller_alias}\n\n{device_enumerate}";
        tooltip-format-enumerate-connected = "{device_alias}  {device_address}";
        on-click = "blueman-manager";
      };

      network = {
        format-wifi = " {essid}";
        format-ethernet = "󰈀 {ipaddr}";
        format-disconnected = "󰖪";
        tooltip-format-wifi = "{essid} ({signalStrength}%)\n{ipaddr}";
        tooltip-format-ethernet = "{ifname}: {ipaddr}/{cidr}";
        on-click = "nm-connection-editor";
      };

      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = "󰝟";
        format-icons.default = [ "󰕿" "󰖀" "󰕾" ];
        on-click = "pavucontrol";
        tooltip = false;
      };

      tray = {
        spacing = 8;
        icon-size = 16;
      };
    }];

    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: "${font}";
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background-color: alpha(#${c.base00}, 0.83);
        color: #${c.base05};
        border-radius: 12px;
        border: 1px solid alpha(#${c.base0D}, 0.19);
        box-shadow: 0 4px 24px rgba(0, 0, 0, 0.38), inset 0 1px 0 rgba(255, 255, 255, 0.04);
      }

      .modules-left,
      .modules-center,
      .modules-right {
        margin: 3px 4px;
      }

      #workspaces {
        background: transparent;
        margin-right: 4px;
      }

      #workspaces button {
        padding: 2px 10px;
        background: transparent;
        color: #${c.base03};
        border-radius: 6px;
        margin: 2px 1px;
        transition: all 0.15s ease;
      }

      #workspaces button.active {
        background: alpha(#${c.base0D}, 0.20);
        color: #${c.base0D};
        border: 1px solid alpha(#${c.base0D}, 0.38);
      }

      #workspaces button:hover {
        background: #${c.base02};
        color: #${c.base05};
      }

      #window {
        color: #${c.base04};
        padding: 0 10px;
        font-style: italic;
      }

      #clock {
        color: #${c.base0A};
        font-weight: bold;
        padding: 0 14px;
        letter-spacing: 0.5px;
      }

      #custom-weather {
        color: #${c.base0C};
        padding: 0 10px;
      }

      #temperature {
        color: #${c.base0B};
        padding: 0 8px;
      }

      #temperature.critical {
        color: #${c.base08};
        animation: blink 1s linear infinite;
      }

      #cpu {
        color: #${c.base0B};
        padding: 0 8px;
      }

      #memory {
        color: #${c.base0C};
        padding: 0 8px;
      }

      #bluetooth {
        color: #${c.base0D};
        padding: 0 8px;
      }

      #bluetooth.connected {
        color: #${c.base0B};
      }

      #bluetooth.disabled {
        padding: 0;
      }

      #network {
        color: #${c.base0D};
        padding: 0 8px;
      }

      #network.disconnected {
        color: #${c.base08};
      }

      #pulseaudio {
        color: #${c.base0E};
        padding: 0 8px;
      }

      #pulseaudio.muted {
        color: #${c.base03};
      }

      #tray {
        padding: 0 8px;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      @keyframes blink {
        to { color: #${c.base00}; background-color: #${c.base08}; }
      }
    '';
  };
}
