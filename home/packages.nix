{ config, pkgs, ... }:

let
  theme-switch = pkgs.writeShellScriptBin "theme-switch" ''
        themes="noctalia
    tokyo-night
    catppuccin-mocha
    gruvbox-dark
    nord"

        choice=$(echo "$themes" | ${pkgs.fzf}/bin/fzf \
          --reverse \
          --prompt="  Theme: " \
          --height=50% \
          --border=rounded \
          --header="Select a color theme" || true)

        [ -z "$choice" ] && exit 0

        printf '"%s"\n' "$choice" | sudo tee /etc/nixos/home/current-theme.nix > /dev/null
        echo "Switching to $choice, rebuilding..."
        sudo nixos-rebuild switch --flake /etc/nixos#nixos
  '';
in
{
  home.packages = with pkgs; [
    # apps
    (pkgs.callPackage ./programs/cider.nix { })
    discord-canary
    feishin # music player
    obsidian # markdown notes
    slack
    claude-code
    tor-browser

    # editors
    zed-editor

    # wayland utilities
    brightnessctl
    cliphist
    wl-clipboard
    wlsunset
    wlr-randr
    # niri doesn't support xwayland -- use xwayland satellite
    xwayland-satellite

    # cli replacements & tools
    bat
    eza
    fd
    ripgrep
    delta
    dust
    duf
    grc
    jq
    zip
    unzip

    # tui tools
    fastfetch
    htop

    # python
    poetry
    python3

    # dev tools
    nodejs
    yarn
    cmake
    gcc
    gnumake
    tree-sitter
    rustup
    trash-cli

    # misc
    fzf
    theme-switch
  ];

  programs.chromium = {
    enable = true;
    extensions = [
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # uBlock Origin
    ];
  };

  programs.git = {
    enable = true;
    delta = {
      enable = true;
      options = {
        navigate = true;
        side-by-side = true;
        line-numbers = true;
        true-color = "always";
      };
    };
    extraConfig = {
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
      pull.ff = "only";
      push.autoSetupRemote = true;
      init.defaultBranch = "main";
    };
  };

  programs.helix = {
    enable = true;
    settings = {
      theme = "autumn_night_transparent";
      editor.cursor-shape = {
        normal = "block";
        insert = "bar";
        select = "underline";
      };
    };
    languages.language = [
      {
        name = "nix";
        auto-format = true;
        formatter.command = "${pkgs.nixfmt}/bin/nixfmt";
      }
    ];
    themes = {
      autumn_night_transparent = {
        "inherits" = "autumn_night";
        "ui.background" = { };
      };
    };
  };
}
