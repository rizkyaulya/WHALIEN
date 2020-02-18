﻿param(
    $Config
)

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Pools_Data = @(
    [PSCustomObject]@{symbol = "AEON";  port = 5555;  fee = 0.9; rpc = "aeon"; regions = @("eu")}
    [PSCustomObject]@{symbol = "TUBE";  port = 5555;  fee = 0.9; rpc = "bittube"; regions = @("eu","ca","sg")}
    [PSCustomObject]@{symbol = "BBR";   port = 5555;  fee = 0.9; rpc = "boolberry"; regions = @("eu"); scratchpad = "http://boolberry.miner.rocks:8008/scratchpad.bin"}
    [PSCustomObject]@{symbol = "CCX";   port = 10126; fee = 0.9; rpc = "conceal"; regions = @("eu")}
    [PSCustomObject]@{symbol = "GRFT";  port = 5005;  fee = 0.9; rpc = "graft"; regions = @("eu")}
    [PSCustomObject]@{symbol = "XHV";   port = 4005;  fee = 0.9; rpc = "haven"; regions = @("eu","ca","sg")}
    [PSCustomObject]@{symbol = "XTA";   port = 30042; fee = 0.9; rpc = "italo"; regions = @("eu")}
    [PSCustomObject]@{symbol = "LOKI";  port = 5005;  fee = 0.9; rpc = "loki"; regions = @("eu")}
    [PSCustomObject]@{symbol = "MSR";   port = 5005;  fee = 0.9; rpc = "masari";   regions = @("eu","sg")}
    [PSCustomObject]@{symbol = "XMR";   port = 5555;  fee = 0.9; rpc = "monero"; regions = @("eu")}
    [PSCustomObject]@{symbol = "RYO";   port = 5555;  fee = 1.2; rpc = "ryo"; regions = @("eu")}
    [PSCustomObject]@{symbol = "XLA";   port = 5005;  fee = 0.9; rpc = "stellite"; regions = @("eu","sg")}
    [PSCustomObject]@{symbol = "SUMO";  port = 4005;  fee = 0.9; rpc = "sumokoin"; regions = @("eu")}
    [PSCustomObject]@{symbol = "TRTL";  port = 5005;  fee = 0.9; rpc = "turtle"; regions = @("eu")}
    [PSCustomObject]@{symbol = "UPX";   port = 30022; fee = 0.9; rpc = "uplexa"; regions = @("eu")}
    [PSCustomObject]@{symbol = "XCASH"; port = 30062;  fee = 0.9; rpc = "xcash"; regions = @("eu")}
)

$Pools_Data | Where-Object {$Config.Pools.$Name.Wallets."$($_.symbol)"} | Foreach-Object {
    $Pool_Currency = $_.symbol
    $Pool_RpcPath = $_.rpc

    $Pool_Request = [PSCustomObject]@{}
    $Request = [PSCustomObject]@{}
    try {
        $Pool_Request = Invoke-RestMethodAsync "https://$($Pool_RpcPath).miner.rocks/api/stats" -tag $Name
        $coinUnits = [Decimal]$Pool_Request.config.coinUnits

        $Request = Invoke-RestMethodAsync "https://$($Pool_RpcPath).miner.rocks/api/stats_address?address=$(Get-WalletWithPaymentId $Config.Pools.$Name.Wallets.$Pool_Currency -pidchar '.')" -delay 100 -cycletime ($Config.BalanceUpdateMinutes*60)
        if ($Request -is [string] -and $Request -match "{.+}") {
            try {
                $Request = $Request -replace '"workers":{".+}}','"workers":{ }' -replace '"charts":{".+]]}','"charts":{ }' | ConvertFrom-Json -ErrorAction Ignore
            } catch {
                if ($Error.Count){$Error.RemoveAt(0)}
            }
        }
        if (-not $Request.stats -or -not $coinUnits) {
            Write-Log -Level Info "Pool Balance API ($Name) for $($_.Name) returned nothing. "
        } else {
			$Payouts = @($i=0;$Request.payments | Where-Object {$_ -match "^(.+?):(\d+?):"} | Foreach-Object {[PSCustomObject]@{time=$Request.payments[$i+1];amount=[Decimal]$Matches[2] / $coinUnits;txid=$Matches[1]};$i+=2})
            [PSCustomObject]@{
                Caption     = "$($Name) ($Pool_Currency)"
				BaseName    = $Name
                Currency    = $Pool_Currency
                Balance     = [Decimal]$Request.stats.balance / $coinUnits
                Pending     = [Decimal]$Request.stats.pendingIncome / $coinUnits
                Total       = [Decimal]$Request.stats.balance / $coinUnits + [Decimal]$Request.stats.pendingIncome / $coinUnits
                Paid        = [Decimal]$Request.stats.paid / $coinUnits
                Paid24h     = [Decimal]$Request.stats.paid24h / $coinUnits
                Payouts     = @(Get-BalancesPayouts $Payouts | Select-Object)
                LastUpdated = (Get-Date).ToUniversalTime()
            }
			Remove-Variable "Payouts"
        }
    }
    catch {
        if ($Error.Count){$Error.RemoveAt(0)}
        Write-Log -Level Verbose "Pool Balance API ($Name) for $($_.Name) has failed. "
    }
}
