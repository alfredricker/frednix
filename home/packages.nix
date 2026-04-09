{ config, pkgs, ... }:

let
  nixpoetry = pkgs.writeShellScriptBin "nixpoetry" ''
    export PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright-driver.browsers}
    export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
    export PLAYWRIGHT_HOST_PLATFORM_OVERRIDE="ubuntu-24.04"
    exec poetry "$@"
  '';

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
    # APPS
    discord-canary
    monero-gui # cryptocurrency
    obsidian # markdown notes
    slack
    # claude
    claude-code
    poppler-utils # allows claude to read pdf files
    # tor
    tor-browser
    # music
    jellyfin # media server
    feishin # music player
    nicotine-plus # p2p files
    puddletag # edit music metadata
    bitwig-studio # DAW
    # music production - synths
    surge-xt # wavetable/subtractive/FM synth (VST3/CLAP)
    cardinal # VCV Rack as a plugin - modular synthesis (CLAP/VST3/LV2)
    helm # polyphonic wavetable synth (LV2)
    # music production - samplers
    sfizz # SFZ format sampler (VST3/LV2/CLAP)
    fluidsynth # SF2 soundfont player
    qsynth # GUI for fluidsynth
    # music production - effects (LV2/VST3/CLAP)
    lsp-plugins # comprehensive effects suite: reverb, EQ, compressor, etc.
    dragonfly-reverb # quality reverb algorithms
    # music production - utilities
    carla # plugin host; bridges LV2 plugins into Bitwig as VST
    crosspipe # PipeWire patchbay for routing audio/MIDI
    audacity # audio editing and sampling

    # file manager
    nautilus

    # editors
    zed-editor
    gthumb # image editor

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
    ffmpeg
    ripgrep
    delta
    dust
    duf
    grc
    jq
    wl-clipboard
    zip
    unzip

    # tui tools
    fastfetch
    htop
    pulsemixer # pipewire/pulseaudio tui mixer

    # python
    poetry
    python3
    nixpoetry

    # dev tools
    nodejs
    yarn
    cmake
    gcc
    gnumake
    tree-sitter
    rustup
    trash-cli

    # work (bb) tools
    awscli2

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
    settings = {
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
      pull.ff = "only";
      push.autoSetupRemote = true;
      init.defaultBranch = "main";
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      side-by-side = true;
      line-numbers = true;
      true-color = "always";
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
