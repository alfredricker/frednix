{ config, pkgs, ... }:

{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = true;
      scan_timeout = 5;
      command_timeout = 500;

      format = "$status$directory$git_branch$git_status$cmd_duration$nix_shell\n$character";

      status = {
        disabled = false;
        format = "[$symbol]($style) ";
        symbol = "│";
        success_symbol = "[│](bold white)";
        style = "red";
      };

      character = {
        success_symbol = "[❯](bold white)";
        error_symbol = "[❯](bold red)";
        vicmd_symbol = "[❮](bold green)";
      };

      directory = {
        style = "cyan";
        truncation_length = 3;
        home_symbol = "~";
        repo_root_style = "bold white";
        read_only = " 󰌾";
      };

      git_branch = {
        format = " [$branch]($style)";
        style = "green";
        symbol = "";
      };

      git_status = {
        format = "[$all_status$ahead_behind]($style) ";
        style = "yellow";
        untracked = "?";
        modified = "!";
        staged = "+";
        deleted = "✘";
        renamed = "»";
        ahead = "⇡";
        behind = "⇣";
        diverged = "⇕";
      };

      cmd_duration = {
        format = " [$duration]($style)";
        style = "yellow";
        min_time = 2000;
        show_milliseconds = true;
      };

      nix_shell = {
        disabled = false;
        format = " [nix]($style)";
        style = "bold blue";
        impure_msg = "";
        pure_msg = " pure";
      };

      username = { disabled = true; };
      hostname = { disabled = true; };
    };
  };
}
