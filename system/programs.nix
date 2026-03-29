{ pkgs, ... }:

{
  # --- PROGRAMS ---
  programs = {
    niri.enable = true;
    fish.enable = true; # needed to add fish to /etc/shells
    # browsers
    firefox.enable = true;
    # Some programs need SUID wrappers, can be configured further or are
    # started in user sessions.
    mtr.enable = true;
    # allow dynamically linked libraries (for poetry to run smoothly)
    nix-ld.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    config.common.default = "gnome";
  };
}
