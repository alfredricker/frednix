{ config, pkgs, lib, ... }:

{
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      # Vi keybindings
      fish_vi_key_bindings

      # Cursor shapes per vi mode
      set fish_cursor_default block
      set fish_cursor_insert line
      set fish_cursor_replace_one underscore
      set fish_cursor_visual block

      # Syntax colors
      set -g fish_color_autosuggestion brblack
      set -g fish_color_command blue
      set -g fish_color_error red
      set -g fish_color_param normal

      # Suppress greeting
      set -g fish_greeting

      # C++ stdlib for Python native extensions (numpy, etc.) on NixOS
      set -gx LD_LIBRARY_PATH ${pkgs.stdenv.cc.cc.lib}/lib $LD_LIBRARY_PATH

      # FZF defaults
      set -gx FZF_DEFAULT_OPTS "--reverse --height 40% --border"

      # grc colorization
      if type -q grc
        source ${pkgs.grc}/etc/grc.fish
      end
    '';

    functions = {
      fish_user_key_bindings = {
        description = "Custom key bindings";
        body = ''
          for mode in insert default
            bind -M $mode ctrl-backspace backward-kill-word
            bind -M $mode ctrl-z undo
            bind -M $mode ctrl-b beginning-of-line
            bind -M $mode ctrl-e end-of-line
          end

          bind -M insert up history-prefix-search-backward
          bind -M insert down history-prefix-search-forward
          bind -M default up history-prefix-search-backward
          bind -M default down history-prefix-search-forward
        '';
      };

      # Fuzzy cd into any directory
      fcd = {
        description = "Fuzzy find and cd into a directory";
        body = ''
          set -l dir (${pkgs.fd}/bin/fd --type d | ${pkgs.fzf}/bin/fzf | string trim)
          if test -n "$dir"
            z $dir
          end
        '';
      };

      # Search installed nix packages
      installed = {
        description = "Fuzzy search installed nix packages";
        body = ''
          nix-store --query --requisites /run/current-system/ \
            | string replace -r '.*?-(.*)' '$1' \
            | sort | uniq \
            | ${pkgs.fzf}/bin/fzf
        '';
      };

      # Search all nix store paths and copy to clipboard
      installedall = {
        description = "Search all nix store paths, copy selected to clipboard";
        body = ''
          nix-store --query --requisites /run/current-system/ \
            | ${pkgs.fzf}/bin/fzf \
            | ${pkgs.wl-clipboard}/bin/wl-copy
        '';
      };

      # Grep through git-tracked files
      gitgrep = {
        description = "Grep through git-tracked files";
        body = ''
          git ls-files | ${pkgs.ripgrep}/bin/rg $argv
        '';
      };

    };

    shellAliases = {
      # Shell
      c        = "clear";
      q        = "exit";
      temp     = "cd /tmp/";
      # Nix
      cleanup  = "sudo nix-collect-garbage --delete-older-than 1d";
      listgen  = "sudo nix-env -p /nix/var/nix/profiles/system --list-generations";
      nixremove = "nix-store --gc";
      bloat    = "nix path-info -Sh /run/current-system";
      cleanram = "sudo sh -c 'sync; echo 3 > /proc/sys/vm/drop_caches'";
      trimall  = "sudo fstrim -va";
      rebuild  = "sudo nixos-rebuild switch --flake /etc/nixos#nixos";
      # CLI replacements
      ls       = "eza --icons";
      l        = "eza -lF --time-style=long-iso --icons";
      ll       = "eza -h --git --icons --color=auto --group-directories-first -s extension";
      tree     = "eza --tree --icons";
      cat      = "bat --paging=never";
      find     = "fd";
      grep     = "rg";
      # Git
      add      = "git add .";
      commit   = "git commit";
      push     = "git push";
      pull     = "git pull";
      diff     = "git diff --staged";
      gcld     = "git clone --depth 1";
      # Systemd
      us       = "systemctl --user";
      rs       = "sudo systemctl";
      # Fun
      weather  = "curl -s wttr.in";
      moon     = "curl -s wttr.in/Moon";
    };
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      auto_sync = false;
      update_check = false;
      style = "compact";
      inline_height = 7;
      show_help = false;
      enter_accept = true;
      keymap_mode = "vim-normal";
      filter_mode = "host";
      filter_mode_shell_up_key_binding = "session";
    };
  };

  programs.carapace = {
    enable = true;
    enableFishIntegration = true;
  };
}
