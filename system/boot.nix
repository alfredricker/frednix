{ config, pkgs, lib, ... }:
{ 
 # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
      # do NOT remove this
      efi.canTouchEfiVariables = true;
      # can change to GRUB
      systemd-boot.enable = true;
    };
    #
    plymouth = {
      enable = true;
      theme = "rings";
      themePackages = with pkgs; [
        # install all themes
        (adi1090x-plymouth-themes.override {
          selected_themes = [ "rings" ];
        })
      ];
    };
    # enable silent boot
    consoleLogLevel = 3;
    # rd shiz
    initrd = {
      verbose = false;
      systemd.enable = true;
      # iGPU is available in both boot modes. vfio modules + the RTX→vfio binding
      # live in the `looking-glass` specialisation (see system/looking-glass.nix),
      # so by default nvidia claims the RTX and drives the display.
      kernelModules = [ "amdgpu" ];
    };
    kernelModules = [ "kvm-amd" ];
    kernelParams = [
      "quiet" "udev.log_level=3" "systemd.show_status=auto"
      "boot.shell_on_fail"
      # Keep IOMMU on so the looking-glass specialisation can pass the RTX through.
      "amd_iommu=on" "iommu=pt"
    ];
  };

  # --- Greetd Boot ---
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "niri-session";
        user = "fred";
      };
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session";
        user = "greeter";
      };
    };
  };
}
