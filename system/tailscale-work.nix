# Second, independent Tailscale instance ("work" tailnet) running alongside
# the default `services.tailscale` daemon. Each instance needs its own state
# file, control socket, UDP port, and tun interface so they don't collide.
#
# First-time login (run once; the authenticated state persists across reboots):
#   tailscale-work up
# Check status / get IP:
#   tailscale-work status
{ pkgs, ... }:

{
  # The "work" tailscaled daemon. Auto-starts at boot via multi-user.target.
  systemd.services.tailscaled-work = {
    description = "Tailscale daemon (work tailnet)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-pre.target" ];
    wants = [ "network-pre.target" ];

    serviceConfig = {
      ExecStart = ''
        ${pkgs.tailscale}/bin/tailscaled \
          --state=/var/lib/tailscale-work/tailscaled.state \
          --socket=/run/tailscale-work/tailscaled.sock \
          --port=41642 --tun=tailscale-work
      '';
      RuntimeDirectory = "tailscale-work";
      StateDirectory = "tailscale-work";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  # Convenience wrapper so `tailscale-work <cmd>` targets the work socket,
  # while plain `tailscale` keeps talking to the default instance.
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "tailscale-work" ''
      exec ${pkgs.tailscale}/bin/tailscale \
        --socket=/run/tailscale-work/tailscaled.sock "$@"
    '')
  ];
}
