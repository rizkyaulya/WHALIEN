﻿using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [Bool]$InfoOnly
)

if (-not $IsWindows) {return}

$Path = ".\Bin\NVIDIA-Zjazz\zjazz_cuda.exe"
$ManualUri = "https://github.com/zjazz/zjazz_cuda_miner/releases"
$Port = "324{0:d2}"
$DevFee = 2.0
$Version = "1.2"

$UriCuda = @(
    [PSCustomObject]@{
        Uri = "https://github.com/RainbowMiner/miner-binaries/releases/download/v1.2-zjazz/zjazz_cuda_win64_1.2.zip"
        Cuda = "9.1"
    }
)

if (-not $Global:DeviceCache.DevicesByTypes.NVIDIA -and -not $InfoOnly) {return} # No NVIDIA present in system

$Commands = [PSCustomObject[]]@(
    #[PSCustomObject]@{MainAlgorithm = "bitcash"; CoinSymbol = "BITC";  Params = ""; ExtendInterval = 2; FaultTolerance = 0.5} #Cuckoo/Bitcash
    [PSCustomObject]@{MainAlgorithm = "merit";   CoinSymbol = "MERIT"; Params = ""; ExtendInterval = 2; FaultTolerance = 0.5} #Cuckoo/Merit
    #[PSCustomObject]@{MainAlgorithm = "x22i";    CoinSymbol = "";      Params = ""} #X22i
)

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

if ($InfoOnly) {
    [PSCustomObject]@{
        Type      = @("NVIDIA")
        Name      = $Name
        Path      = $Path
        Port      = $Miner_Port
        Uri       = $UriCuda[0].Uri
        DevFee    = $DevFee
        ManualUri = $ManualUri
        Commands  = $Commands
    }
    return
}

$Uri = ""
for($i=0;$i -le $UriCuda.Count -and -not $Uri;$i++) {
    if (Confirm-Cuda -ActualVersion $Session.Config.CUDAVersion -RequiredVersion $UriCuda[$i].Cuda -Warning $(if ($i -lt $UriCuda.Count-1) {""}else{$Name})) {
        $Uri = $UriCuda[$i].Uri
        $Cuda= $UriCuda[$i].Cuda
    }
}
if (-not $Uri) {return}

$Global:DeviceCache.DevicesByTypes.NVIDIA | Select-Object Vendor, Model -Unique | ForEach-Object {
    $First = $true
    $Miner_Model = $_.Model
    $Miner_Device = $Global:DeviceCache.DevicesByTypes."$($_.Vendor)" | Where-Object Model -EQ $_.Model

    $Commands | ForEach-Object {

        $Algorithm_Norm_0 = Get-Algorithm $_.MainAlgorithm

        foreach($Algorithm_Norm in @($Algorithm_Norm_0,"$($Algorithm_Norm_0)-$($Miner_Model)")) {
            if ($Pools.$Algorithm_Norm.Host -and $Miner_Device -and ($_.CoinSymbol -eq "" -or $_.CoinSymbol -eq $Pools.$Algorithm_Norm.CoinSymbol)) {
                if ($First) {
                    $Miner_Port = $Port -f ($Miner_Device | Select-Object -First 1 -ExpandProperty Index)
                    $Miner_Name = (@($Name) + @($Miner_Device.Name | Sort-Object) | Select-Object) -join '-'
                    $DeviceIDsAll = $Miner_Device.Type_Vendor_Index -join ' -d '
                    $First = $false
                }
                $Pool_Port = if ($Pools.$Algorithm_Norm.Ports -ne $null -and $Pools.$Algorithm_Norm.Ports.GPU) {$Pools.$Algorithm_Norm.Ports.GPU} else {$Pools.$Algorithm_Norm.Port}
                [PSCustomObject]@{
					Name           = $Miner_Name
                    DeviceName     = $Miner_Device.Name
                    DeviceModel    = $Miner_Model
                    Path           = $Path
                    Arguments      = "-b `$mport -d $($DeviceIDsAll) -a $($_.MainAlgorithm) -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pool_Port) -u $($Pools.$Algorithm_Norm.User)$(if ($Pools.$Algorithm_Norm.Pass) {" -p $($Pools.$Algorithm_Norm.Pass)"}) -R 5 --hide-hashrate-per-gpu $($_.Params)"
                    HashRates      = [PSCustomObject]@{$Algorithm_Norm = $Global:StatsCache."$($Miner_Name)_$($Algorithm_Norm_0)_HashRate".Week}
                    API            = "Ccminer"
                    Port           = $Miner_Port
                    Uri            = $Uri
                    FaultTolerance = $_.FaultTolerance
                    ExtendInterval = $_.ExtendInterval
                    Penalty        = 0
                    DevFee         = $DevFee
                    ManualUri      = $ManualUri
                    Version        = $Version
                    PowerDraw      = 0
                    BaseName       = $Name
                    BaseAlgorithm  = $Algorithm_Norm_0
                }
            }
        }
    }
}