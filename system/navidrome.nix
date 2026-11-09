# Navidrome music server (replaces Jellyfin for music).
#
# Web UI: http://localhost:4533 — the first visit asks you to create an admin account.
# Clients: Feishin on desktop, any Subsonic app on iOS (Amperfy, play:Sub, ...).
# Metadata comes straight from the file tags, so fix tags with puddletag/Picard/beets.
{ lib, ... }:
{
  services.navidrome = {
    enable = true;
    # Run as fred so it can read the music in /home/fred (which is mode 700).
    user = "fred";
    group = "users";
    settings = {
      MusicFolder = "/home/fred/Media/Music/lib";
      # Listen on all interfaces; the firewall below only lets Tailscale in.
      Address = "0.0.0.0";
      Port = 4533;
    };
  };

  # The module sets ProtectHome=true, which hides /home entirely and drops the
  # music folder bind mount. "tmpfs" hides /home but still allows the bind.
  systemd.services.navidrome.serviceConfig.ProtectHome = lib.mkForce "tmpfs";

  # Reachable from your phone over Tailscale, not from the LAN or internet.
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 4533 ];
}
