# Install NVIDIA Drivers on Fedora

These instructions install the NVIDIA proprietary driver through RPM Fusion and configure `nvidia-smi`.

## 1. Enable RPM Fusion repositories

```bash
sudo dnf upgrade --refresh

sudo dnf install \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
```

## 2. Install the NVIDIA driver and utilities

```bash
sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda
```

`akmod-nvidia` builds the NVIDIA kernel module.  
`xorg-x11-drv-nvidia-cuda` provides NVIDIA utilities, including `nvidia-smi`.

For 32-bit gaming libraries, also install:

```bash
sudo dnf install xorg-x11-drv-nvidia-libs.i686
```

## 3. Ensure the kernel build dependencies are installed

```bash
sudo dnf install kernel-devel-matched kernel-headers gcc make
```

## 4. Build the NVIDIA kernel module

```bash
sudo akmods --force
sudo depmod -a
```

Check whether the module was built:

```bash
modinfo -F version nvidia
```

A version number indicates that the module is available.

## 5. Reboot

```bash
sudo reboot
```

## 6. Verify the driver

After logging back in, run:

```bash
nvidia-smi
```

A successful installation displays the GPU model, driver version, CUDA version, and running processes.

## Troubleshooting

### `nvidia-smi: command not found`

Install the package that provides the command:

```bash
sudo dnf install xorg-x11-drv-nvidia-cuda
```

Then reboot:

```bash
sudo reboot
```

### The NVIDIA module is missing

Run:

```bash
sudo akmods --force
sudo depmod -a
sudo reboot
```

If it still does not work, inspect the akmods status:

```bash
sudo akmods --status
```

Check the current kernel:

```bash
uname -r
```

Check whether the NVIDIA module exists:

```bash
modinfo nvidia
```

### Secure Boot prevents the driver from loading

Check Secure Boot status:

```bash
mokutil --sb-state
```

If it reports `SecureBoot enabled`, enroll the akmods signing key:

```bash
sudo dnf install mokutil
sudo mokutil --import /etc/pki/akmods/certs/public_key.der
```

Reboot:

```bash
sudo reboot
```

During startup, select **Enroll MOK** and follow the prompts. After Fedora starts, verify the driver:

```bash
nvidia-smi
```

Alternatively, disable Secure Boot in the computer's UEFI/BIOS settings.

## Optional: install the CUDA toolkit

The NVIDIA driver is sufficient for graphics and most games. Install the CUDA toolkit only if you need to compile or run CUDA applications:

```bash
sudo dnf install cuda-toolkit
```

Verify CUDA compiler availability:

```bash
nvcc --version
```

## Useful diagnostic commands

```bash
nvidia-smi
lsmod | grep nvidia
modinfo nvidia
sudo akmods --status
journalctl -k -b | grep -i nvidia
```

