{ pkgs, ... }:

{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      swtpm.enable = true;  # TPM 2.0 emulation — required for Windows 11
      runAsRoot = false;
    };
  };

  users.users.fred.extraGroups = [ "libvirtd" ];

  environment.systemPackages = with pkgs; [
    looking-glass-client
    virtiofsd
  ];

  # Sync ~/virt/win11.xml → /var/lib/libvirt/qemu/win11.xml on any save.
  systemd.services.sync-win11-xml = {
    description = "Sync win11.xml into libvirt";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/cp /home/fred/virt/win11.xml /var/lib/libvirt/qemu/win11.xml";
    };
  };

  systemd.paths.sync-win11-xml = {
    description = "Watch ~/virt/win11.xml for changes";
    wantedBy = [ "multi-user.target" ];
    pathConfig.PathChanged = "/home/fred/virt/win11.xml";
  };

  # virtiofsd daemon sharing ~/Media/Music into the VM.
  # Socket at /run/virtiofsd/music.sock — reference this in the VM XML.
  systemd.services.virtiofsd-music = {
    description = "virtiofsd share: Music";
    after = [ "local-fs.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      # --shared-dir: share the whole Music tree so projects + presets are visible
      ExecStart = "${pkgs.virtiofsd}/bin/virtiofsd --socket-path=/run/virtiofsd/music.sock --shared-dir=/home/fred/Media/Music --sandbox=namespace";
      # Poll until the socket appears, then open permissions so libvirtd can connect
      ExecStartPost = pkgs.writeShellScript "virtiofsd-chmod" ''
        for i in $(seq 1 50); do
          [ -S /run/virtiofsd/music.sock ] && exec ${pkgs.coreutils}/bin/chmod 0777 /run/virtiofsd/music.sock
          sleep 0.1
        done
        echo "virtiofsd socket did not appear" >&2; exit 1
      '';
      RuntimeDirectory = "virtiofsd";
      RuntimeDirectoryMode = "0755";
      UMask = "0000";
      User = "fred";
      Group = "users";
      Restart = "on-failure";
    };
  };
}
