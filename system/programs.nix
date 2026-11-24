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
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        # OpenGL loader; the actual NVIDIA/Mesa drivers come from hardware.graphics
        libGL

        # Wayland backend for GLFW (what you'll use under niri)
        wayland # libwayland-client, -cursor, -egl
        libxkbcommon
        libdecor # optional: window decorations

        # X11 backend (optional fallback via Xwayland, PYGLFW_LIBRARY_VARIANT=x11)
        libx11
        libxcursor
        libxrandr
        libxi
        libxinerama
        libxext
        libxrender
        libxxf86vm
      ];
    };
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
