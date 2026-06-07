# GPU modes: RTX desktop vs. Looking Glass

This machine has two GPUs:

| GPU | PCI | Role |
| --- | --- | --- |
| NVIDIA RTX 5070 Ti (GB203) | `01:00.0` (+ `01:00.1` audio) | Desktop **or** passed to the Windows VM |
| AMD Granite Ridge iGPU | `0d:00.0` | Desktop fallback for Looking Glass mode |

Only one GPU can drive a given role at a time — a card is either the host's or
passed to the guest, never both at once. Looking Glass works by giving the VM a
GPU, letting it render, and copying frames back into a window on the host
desktop, so the host needs its *own* separate GPU. That's why the two GPUs swap
roles between the two boot modes.

## The two boot modes

Defined as a NixOS specialisation in [`system/looking-glass.nix`](../system/looking-glass.nix).
You pick the mode from the systemd-boot menu at startup.

| | Default entry | `looking-glass` entry |
| --- | --- | --- |
| Desktop GPU | RTX (nvidia) | iGPU (amdgpu) |
| RTX bound to | nvidia driver | vfio-pci (→ VM) |
| Monitor cable | **RTX port** | **motherboard / iGPU port** |
| `videoDrivers` | `nvidia` (base config) | `amdgpu` (mkForce) |
| EGL / GLX | nvidia (correct — display is nvidia) | pinned to mesa |
| Use it for | everyday use, ffmpeg/CUDA natively | running the Windows VM |

The driver binding and the physical cable must agree. Booting the default entry
with the cable in the motherboard port (or vice-versa) leaves that monitor dark
— the machine is still up and reachable over SSH/Tailscale, it's just driving an
output you're not plugged into.

## Why it's built this way

The GPU binding (vfio vs. nvidia) is set by kernel cmdline + initrd, which is
fixed at boot — it cannot be hot-swapped under a running compositor. So mode
selection has to be a boot-time choice, i.e. a specialisation, not a runtime
script. (`system/gpu-switch.nix` rebinds the RTX at runtime for *headless
compute* like ffmpeg/CUDA — that works because compute talks to libcuda/nvcuvid
directly and doesn't involve the compositor. It cannot move a live desktop
between GPUs.)

The default used to be the inverse (RTX permanently on vfio, desktop on the
iGPU). That left the desktop on a tiny ~2-CU iGPU, and Chromium's GPU
rasterisation repeatedly wedged the amdgpu GFX ring (`ring gfx_0.0.0 timeout`,
`device wedged`), once taking the niri compositor down with it (SIGABRT → dropped
to the login screen). Flipping the default to the RTX removes that failure mode;
the iGPU is now only used in the rare Looking Glass sessions, where the desktop
is light (just the LG window) and EGL is pinned to mesa to avoid the
nvidia-userspace/amdgpu mismatch.

## Recommended monitor wiring

Use **two cables** and switch the monitor's input source — no re-plugging:

- DisplayPort from the **RTX** → monitor input A (default mode)
- HDMI from the **motherboard** (iGPU) → monitor input B (looking-glass mode)

Single-cable also works; you just move it between the RTX and the motherboard
port when switching modes.

## Switching modes

1. Make sure the monitor is showing the GPU for the mode you're about to boot
   (switch input, or move the cable) — do this *before* the boot menu so you can
   see it.
2. Reboot. At the systemd-boot menu pick **`looking-glass`** for VM mode, or the
   plain entry for the RTX desktop. (A reboot is required — the GPU binding is a
   kernel-cmdline change.)
3. In looking-glass mode, start the VM as usual: run `windows start`
   (see [`scripts/windows`](../scripts/windows)).

## Recovery

The previous generation stays in the boot menu, and SSH/Tailscale run regardless
of which display is live — so if the nvidia desktop ever fails to come up, boot
the previous generation or SSH in.

## Files

- [`system/boot.nix`](../system/boot.nix) — base boot config; keeps IOMMU on, no
  longer binds the RTX to vfio by default.
- [`system/looking-glass.nix`](../system/looking-glass.nix) — the specialisation.
- [`system/configuration.nix`](../system/configuration.nix) — sets
  `services.xserver.videoDrivers = [ "nvidia" ]` (the default-mode display).
- [`system/virt/virt.nix`](../system/virt/virt.nix),
  [`system/virt/win11.xml`](../system/virt/win11.xml) — the VM + Looking Glass
  shared-memory setup. `win11.xml` passes through `01:00.0`.
- [`system/gpu-switch.nix`](../system/gpu-switch.nix) — runtime RTX rebind for
  headless compute (not for switching the desktop).
