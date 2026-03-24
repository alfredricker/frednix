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
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  # --- FLATPAK ---
  services.flatpak.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };
}
