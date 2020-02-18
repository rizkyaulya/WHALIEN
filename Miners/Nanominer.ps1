﻿using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [Bool]$InfoOnly
)

if (-not $IsWindows -and -not $IsLinux) {return}

if ($IsLinux) {
    $Path = ".\Bin\ANY-Nanominer\nanominer"
    $URI = "https://github.com/RainbowMiner/miner-binaries/releases/download/v1.8.1-nanominer/nanominer-linux-1.8.1.tar.gz"
} else {
    $Path = ".\Bin\ANY-Nanominer\nanominer.exe"
    $URI = "https://github.com/RainbowMiner/miner-binaries/releases/download/v1.8.1-nanominer/nanominer-windows-1.8.1.zip"
}
$ManualURI = "https://github.com/nanopool/nanominer/releases"
$Port = "534{0:d2}"
$Cuda = "8.0"
$DevFee = 3.0
$Version = "1.8.1"

if (-not $Global:DeviceCache.DevicesByTypes.AMD -and -not $Global:DeviceCache.DevicesByTypes.CPU -and -not $Global:DeviceCache.DevicesByTypes.NVIDIA -and -not $InfoOnly) {return} # No GPU present in system

$Commands = [PSCustomObject[]]@(
    #[PSCustomObject]@{MainAlgorithm = "Cuckaroo29";              Params = ""; MinMemGb = 6;    Vendor = @("AMD");          NH = $true; ExtendInterval = 2; DevFee = 2.0} #Cuckaroo29
    #[PSCustomObject]@{MainAlgorithm = "Cuckarood29";             Params = ""; MinMemGb = 6;    Vendor = @("AMD");          NH = $true; ExtendInterval = 2; DevFee = 2.0} #Cuckarood29
    [PSCustomObject]@{MainAlgorithm = "Cuckaroo30";              Params = ""; MinMemGb = 14; Vendor = @("AMD");          NH = $true; ExtendInterval = 2; DevFee = 5.0} #Cuckaroo30/Cortex
    [PSCustomObject]@{MainAlgorithm = "Ethash";                  Params = ""; MinMemGb = 3;  Vendor = @("AMD");          NH = $true; ExtendInterval = 2; DevFee = 1.0} #Ethash
    [PSCustomObject]@{MainAlgorithm = "RandomHash2";             Params = ""; MinMemGb = 3;  Vendor = @("CPU");          NH = $true; ExtendInterval = 2; DevFee = 5.0} #RandomHash2/PASCcoin, RHminerCpu is more than 350% faster
    [PSCustomObject]@{MainAlgorithm = "RandomX";                 Params = ""; MinMemGb = 3;  Vendor = @("CPU");          NH = $true; ExtendInterval = 2; DevFee = 2.0} #RandomX
    [PSCustomObject]@{MainAlgorithm = "UbqHash";                 Params = ""; MinMemGb = 3;  Vendor = @("AMD","NVIDIA"); NH = $true; ExtendInterval = 2; DevFee = 1.0} #UbqHash
)

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

if ($InfoOnly) {
    [PSCustomObject]@{
        Type      = @("AMD","CPU","NVIDIA")
        Name      = $Name
        Path      = $Path
        Port      = $Miner_Port
        Uri       = $Uri
        DevFee    = $DevFee
        ManualUri = $ManualUri
        Commands  = $Commands
    }
    return
}

if ($Global:DeviceCache.DevicesByTypes.NVIDIA) {$Cuda = Confirm-Cuda -ActualVersion $Session.Config.CUDAVersion -RequiredVersion $Cuda -Warning $Name}

foreach ($Miner_Vendor in @("AMD","CPU","NVIDIA")) {
    $Global:DeviceCache.DevicesByTypes.$Miner_Vendor | Where-Object {$_.Vendor -ne "NVIDIA" -or $Cuda} | Select-Object Vendor, Model -Unique | ForEach-Object {
        $Device = $Global:DeviceCache.DevicesByTypes.$Miner_Vendor | Where-Object Model -EQ $_.Model
        $Miner_Model = $_.Model

        $Commands |  Where-Object {$_.Vendor -icontains $Miner_Vendor} | ForEach-Object {
            $First = $true
            $Algorithm_Norm_0 = Get-Algorithm $_.MainAlgorithm

            if ($Miner_Vendor -eq "CPU") {
                $CPUThreads = if ($Session.Config.Miners."$Name-CPU-$Algorithm_Norm_0".Threads)  {$Session.Config.Miners."$Name-CPU-$Algorithm_Norm_0".Threads}  elseif ($Session.Config.Miners."$Name-CPU".Threads)  {$Session.Config.Miners."$Name-CPU".Threads}  elseif ($Session.Config.CPUMiningThreads)  {$Session.Config.CPUMiningThreads}
                $CPUAffinity= if ($Session.Config.Miners."$Name-CPU-$Algorithm_Norm_0".Affinity) {$Session.Config.Miners."$Name-CPU-$Algorithm_Norm_0".Affinity} elseif ($Session.Config.Miners."$Name-CPU".Affinity) {$Session.Config.Miners."$Name-CPU".Affinity} elseif ($Session.Config.CPUMiningAffinity) {$Session.Config.CPUMiningAffinity}
            }

            $MinMemGB = if ($_.MainAlgorithm -eq "Ethash") {Get-EthDAGSize $Pools.$Algorithm_Norm_0.CoinSymbol} else {$_.MinMemGb}

            $Miner_Device = $Device | Where-Object {$Miner_Vendor -eq "CPU" -or (($Algorithm_Norm_0 -ne "Cuckaroo30" -or $_.Model -eq "RX57016GB") -and (Test-VRAM $_ $MinMemGb))}

		    foreach($Algorithm_Norm in @($Algorithm_Norm_0,"$($Algorithm_Norm_0)-$($Miner_Model)")) {
			    if ($Pools.$Algorithm_Norm.Host -and $Miner_Device -and ($_.NH -or $Pools.$Algorithm_Norm.Name -notmatch "Nicehash") -and ($Algorithm_Norm -ne "Ethash" -or $Pools.$Algorithm_Norm.Name -notmatch "F2Pool")) {
                    if ($First) {
                        $Miner_Port = $Port -f ($Miner_Device | Select-Object -First 1 -ExpandProperty Index)
                        $Miner_Name = (@($Name) + @($Miner_Device.Name | Sort-Object) | Select-Object) -join '-'
                        $First = $false
                    }
					$Pool_Port = if ($Miner_Vendor -ne "CPU" -and $Pools.$Algorithm_Norm.Ports -ne $null -and $Pools.$Algorithm_Norm.Ports.GPU) {$Pools.$Algorithm_Norm.Ports.GPU} else {$Pools.$Algorithm_Norm.Port}
                    $Wallet    = if ($Pools.$Algorithm_Norm.Wallet) {$Pools.$Algorithm_Norm.Wallet} else {$Pools.$Algorithm_Norm.User}
                    $PaymentId = $null
                    if ($Algorithm_Norm -match "^RandomHash" -or $Algorithm_Norm -match "^Cryptonight") {
                        if ($Wallet -match "^(.+?)[\.\+]([0-9a-f]{16,})") {
                            $Wallet    = $Matches[1]
                            $PaymentId = $Matches[2]
                        } elseif ($Algorithm_Norm -match "^RandomHash") {
                            $PaymentId = "0"
                        }
                    }

				    $Arguments = [PSCustomObject]@{
                        Algo      = $_.MainAlgorithm
					    Host      = $Pools.$Algorithm_Norm.Host
					    Port      = $Pools.$Algorithm_Norm.Port
					    SSL       = $Pools.$Algorithm_Norm.SSL
					    Wallet    = $Wallet
                        PaymentId = $PaymentId
                        Worker    = "{workername:$($Pools.$Algorithm_Norm.Worker)}"
                        Pass      = $Pools.$Algorithm_Norm.Pass
                        Email     = $Pools.$Algorithm_Norm.Email
                        Threads   = if ($Miner_Vendor -eq "CPU") {$CPUThreads} else {$null}
                        Devices   = if ($Miner_Vendor -ne "CPU") {$Miner_Device.Type_Mineable_Index} else {$null} 
				    }

				    [PSCustomObject]@{
					    Name           = $Miner_Name
					    DeviceName     = $Miner_Device.Name
					    DeviceModel    = $Miner_Model
					    Path           = $Path
					    Arguments      = $Arguments
					    HashRates      = [PSCustomObject]@{$Algorithm_Norm = $Global:StatsCache."$($Miner_Name)_$($Algorithm_Norm_0)_HashRate".Week}
					    API            = "Nanominer"
					    Port           = $Miner_Port
					    Uri            = $Uri
					    FaultTolerance = $_.FaultTolerance
					    ExtendInterval = $_.ExtendInterval
                        Penalty        = 0
					    DevFee         = $_.DevFee
					    ManualUri      = $ManualUri
                        MiningAffinity = if ($Miner_Vendor -eq "CPU") {$CPUAffinity} else {$null}
                        Version        = $Version
                        PowerDraw      = 0
                        BaseName       = $Name
                        BaseAlgorithm  = $Algorithm_Norm_0
				    }
			    }
		    }
        }
    }
}