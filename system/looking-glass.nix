# Looking Glass boot mode.
#
# This defines a NixOS *specialisation* — a second entry in the boot menu that
# overrides part of the default config. You choose the mode at boot; the GPU
# binding cannot be hot-swapped under a running session, so it has to be a
# boot-time choice (a separate kernel cmdline + initrd).
#
#   Default entry      → RTX drives the desktop (nvidia). Monitor on an RTX port.
#   looking-glass entry → RTX handed to the Windows VM (vfio), host desktop falls
#                         back to the AMD iGPU. Monitor on the motherboard port.
#
# See docs/gpu-modes.md for the full mental model, cable setup, and switching steps.
{ lib, ... }:
{
  specialisation.looking-glass.configuration = {
    # Labels the boot-menu entry so it's easy to spot.
    system.nixos.tags = [ "looking-glass" ];

    # Hand the RTX 5070 Ti (video + audio function) to vfio at boot so it can be
    # passed into the Windows VM. ids match win11.xml's hostdev.
    boot.initrd.kernelModules = [ "vfio_pci" "vfio" "vfio_iommu_type1" ];
    boot.kernelParams = [ "vfio-pci.ids=10de:2c05,10de:22e9" ];
    # Make sure vfio-pci grabs the card before the nvidia driver can.
    boot.extraModprobeConfig = "softdep nvidia pre: vfio-pci";

    # In this mode the host desktop runs on the AMD iGPU.
    services.xserver.videoDrivers = lib.mkForce [ "amdgpu" ];

    # Force the desktop / Chromium onto mesa so it never probes the (now passed
    # through) nvidia userspace. The nvidia-first EGL vendor + amdgpu rendering
    # mismatch is what helped wedge the iGPU GFX ring before (signal 6 niri crash
    # + amdgpu ring resets). Pinning mesa removes that mismatch.
    environment.sessionVariables = {
      __EGL_VENDOR_LIBRARY_FILENAMES =
        "/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json";
      __GLX_VENDOR_LIBRARY_NAME = "mesa";
    };
  };
}
