## INTRODUCTION

GPU/CPU Mining script with intelligent auto-switching between different miningpools, algorithm, miner programs using all possible combinations of devices (NVIDIA, AMD and CPU), optionally including cost of electricity into profit calculations and  stop mining, if no longer profitable.
Features: easy setup wizard with adhoc working default (no editing of files needed), GUI-webinterface, selection of devices to be used, very low CPU usage.


![alt text](https://raw.githubusercontent.com/RainbowMiner/miner-binaries/master/rainbowminerhome.png "RainbowMiner Web GUI")


## FEATURE SUMMARY

- **Multi-Platform (AMD, NVIDIA, CPU) on Windows and Linux**
- **Profit auto-switch between mining programs and algorithm for GPUs & CPUs (optimized one for each vendor vs. one for each possible device combination)**
- **Profit auto-switch between pools (2Miners, 6Block, AHashPool, BaikalMiner, BeePool, BlazePool, BlockCruncher, BlockMasters, Bsod, BtcPrivate, Cortexmint, EthashPool, Ethermine, F2pool, FairPool, FlyPool, GosCx, GrinMint, Hashcryptos, Hashpool, HashVault, HeroMiners, Icemining, LeafPool, LuckPool, LuckyPool, MinerMore, MinerRocks, MiningDutch, MiningPoolHub, MiningPoolOvh, MiningRigRentals, Mintpond, MoneroOcean, Nanopool, Nicehash, Poolin, Poolium, Ravenminer, SparkPool, SuprNova, UUpool, Zergpool and Zpool)**
- **Profit calculation, including real cost of electricity per miner**
- **Uses the top actual available miner programs (Bminer, Ccminer, Claymore, CryptoDredge, Dstm, EnemyZ, Ewbf, Gminer, NBminer, Sgminer, SrbMiner, T-Rex, Xmrig and many more)**
- **Easy setup wizard with adhoc working default - click Start.bat and off you go (RainbowMiner will ask for your credentials, no hassle with editing configuration files)**
- **CLient/Server networking for multiple rigs, to minimize internet traffic and avoid pool bans**
- **Scheduler for different power prices and/or pause during specific timespans**
- **Build-in automatic update**
- **Mining devices freely selectable**
- **Finetune miner- and pool-configuration during runtime**
- **Bind/exclude devices to/from specific algorithm and miners**
- **Define pool's algorithms and coins**
- **Use unlimited custom overclocking profiles per miner/algorithm**
- **Easy overclocking of gpus (memory, core, powerlimit and voltage)**
- **Switch MSI Afterburner profiles per miner/algorithm**
- **Includes OhGodAnETHlargementPill**
- **Very low CPU usage to increase CPU mining profit**
- **Pause mining without exiting the RainbowMiner**
- **Full automatic update**

## REQUIRED PRE-REQUESITES

### Windows 7/8.1/10 pre-requesites

1. Install PowerShell 6: [Download Installer for version 6.2.4](https://github.com/PowerShell/PowerShell/releases/download/v6.2.4/PowerShell-6.2.4-win-x64.msi)
2. Install Microsoft .NET Framework 4.5.1 or later: [Web Installer](https://www.microsoft.com/net/download/dotnet-framework-runtime)
3. Update GPU drivers: [Nvidia 431.68](https://www.nvidia.com/Download/index.aspx) and [AMD Adrenalin 2019 Edition 19.5.2](https://support.amd.com/en-us/download/desktop?os=Windows+10+-+64)
4. If your rig contains AMD graphic cards, RainbowMiner's overclocking features rely on MSI Afterburner, you should install and run it: [Download](http://download.msi.com/uti_exe//vga/MSIAfterburnerSetup.zip)
5. If you plan on using [GrinGoldMiner](https://github.com/mozkomor/GrinGoldMiner): Install Microsoft [.NET Core 2.2 Runtime](https://dotnet.microsoft.com/download) - download and install "Run Apps .NET Core Runtime", click the button "** Download .NET Core Runtime (see here: https://github.com/RainbowMiner/RainbowMiner/issues/441#issuecomment-465932125) **"

Finally: check, if Powershell 6 is in your PATH, because RainbowMiner will not run correctly, if the path to powershell is missing. Sometimes "C:\Program Files\PowerShell\6" has to be added manually to the PATH environement variable after installing Powershell 6. Here is a nice tutorial, how to add to PATH environment variable https://www.howtogeek.com/118594/how-to-edit-your-system-path-for-easy-command-line-access/amp/

A note on Windows Nvidia drivers. Recommended lite-packed versions are available for direct download:
[Windows 10 / Nvidia 431.68](https://international.download.nvidia.com/Windows/431.68hf/431.68-desktop-notebook-win10-64bit-international.hf.exe)
[Windows 10 / Nvidia 431.68 DCH](https://international.download.nvidia.com/Windows/431.68hf/431.68-desktop-notebook-win10-64bit-international-dch.hf.exe)
[Windows 7,8,8.1 / Nvidia 431.60](http://us.download.nvidia.com/Windows/431.60/431.60-desktop-win8-win7-64bit-international-whql.exe)

### Ubuntu 18.x Pre-requesites
(This section is WIP! Want to help? Make an [issue](https://github.com/RainbowMiner/RainbowMiner/issues) or a [PR](https://github.com/RainbowMiner/RainbowMiner/pulls)))

Debian-based distros will be more-or-less the same as these instructions.

Other distros will have settings in different places (hugepages) and the software install commands will be differen (dnf, yum, pacman, nix, pkg, etc.) It is assumed you are clever enough to sort out the differences on your own if you choose a different distribution. BUT! As noted above, feel free to edit this page and make a pull request.

###### Huge Pages
By default, linux sets memory-chunk size fairly small. This is to save RAM useage for low-requirement sofware (ie: most programs running in system-space, rather than user-space.) Scrypt^N (Verium) and the CryptoNight family (Monero, etc.) algorithms *need* a large memory-chunk allocation, and many benefit from it even if they don't need it. In linux, this is call 'hugepages'. For Ubuntu-based distributions, you can set this manually on each boot with `sudo sysctl -w vm.nr_hugepages=XXX` where XXX is a how many megabytes to assign per page-chunk.  This can be made persistent across reboots by editing the value in `/proc/sys/vm/nr_hugepages` and you need to be root do it (ie: `sudo emacs -wm /proc/sys/vm/nr_hugepages` (substitue 'emacs -wm' with your editor of choice - nano, vi, joe, etc.)

On my system (@ParalegicRacehorse), xmr-stak will not run with hugepages<1024. Setting it to 2048 did gain me anything more than 1024, but experience in the verium/vericoin community have shown hugepages as large as 4096 can be beneficial. YMMV. Tuning is left to the rig operator, but I recommend keeping it as low as you can get away with so your other programs can run lean.

#### Video Cards

##### Nvidia
Nvidia has kindly supplied a ppa for their official drivers.

```
sudo add-apt-repository ppa:graphics-drivers/ppa
sudo apt -y install dkms build-essential
sudo apt update
sudo apt -y install nvidia-headless-430 nvidia-driver-430 nvidia-compute-utils-430 nvidia-cuda-toolkit

```
Reboot after the driver have been installed.

**Important: check which version of the Nvidia driver you need (i.e. which is compatible with your graphics card)** You can check on the Nvidia website which products are supported by each driver (the latest one is usually the best if you have a recent graphics card). Not doing so can cause black screen on reboot. Only the main version is needed (don't bother about the number after the point, so if latest driver is 430.24, just write 430).

###### Optional Overclocking for Nvidia:

```
sudo nvidia-xconfig -a --cool-bits=31 --allow-empty-initial-configuration
```
Reboot after setting cool bits.

##### AMD Drivers
Download and extract the latest driver for your cards from the [AMD support site](https://www.amd.com/en/support)

After the archive is downloaded, extract the contents to a temporary location from which you can install it. 

Run the following to install it "headless" (this is nessecary for Ubuntu Desktop installations and possibly some other configurations. [Read more here](https://amdgpu-install.readthedocs.io/en/latest/install-installing.html#installing-the-pro-variant)) and with ROCm support.

```
./amdgpu-pro-install -y --opencl=pal,legacy,rocm --headless

```
Reboot and you should be good to go! 

**Important:** Some algorithms, on some miner-software, will not hash with a kernel version greater than 4.2. You may have to downgrade your OS to Ubuntu 16.04 since more recent editions will not run kernel numbers lower than 4.8. This has everything to do with a mismatch between OpenCL versions provided by recent drivers and those supported by the mining software. Yes, that means you will be running older drivers. If you want the newer drivers, with newer versions of OpenCL to work, feel free to provide assistance to the affected mining softwares by fixing their code and sending pull-requests.

## RECOMMENDATIONS & HELPERS

- Set your Windows virtual memory size to a fixed size, to the sum of your GPU memories x 1.1, e.g. if you have 6x GTX1070 8GB installed, use at least 53000 (Computer Properties->Advanced System Settings->Performance->Advanced->Virtual Memory)
- if mining on GeForce GTX 1070/GTX 1070Ti/GTX 1080/GTX 1080Ti, it is recommended to set "Force P2-State" to "Off", so that the card will always operate in P0 state. 
  
## CREDITS

The miner script has initially been forked from MultiPoolMiner, for my private use, only.
Since I changed and optimized the script a lot to suit my needs, I decided to make the source code public, so that others can profit from my optimizations.

**If you are happy with the script, bitcoin donations are greatly appreciated:**

**The RainbowMiner author**
  - BTC: 3P7pVVNpExuuHL9wjWKAo7jzQsb9ZziUFC
  - BCH: 1MGRzyaLjQ67ZwwL9QTbXzwLxa8x1qSTBD
  - ETH: 0x3084A8657ccF9d21575e5dD8357A2DEAf1904ef6

**The MultiPoolMiner author**
  - BTC: 1Q24z7gHPDbedkaWDTFqhMF8g7iHMehsCb
