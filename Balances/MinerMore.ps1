﻿param(
    $Config
)

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Request = [PSCustomObject]@{}

$Payout_Currencies = $Config.Pools.$Name.Wallets.PSObject.Properties | Where-Object Value | Select-Object Name,Value -Unique | Sort-Object Name,Value

if (-not $Payout_Currencies) {
    Write-Log -Level Verbose "Cannot get balance on pool ($Name) - no wallet address specified. "
    return
}

$PoolCoins_Request = [PSCustomObject]@{}
try {
    $PoolCoins_Request = Invoke-RestMethodAsync "https://minermore.com/api/currencies" -tag $Name -cycletime 120
}
catch {
    if ($Error.Count){$Error.RemoveAt(0)}
    Write-Log -Level Warn "Pool API ($Name) has failed. "
    return
}

$Count = 0
$Payout_Currencies | Where-Object {@($PoolCoins_Request.PSObject.Properties.Name -replace '-.+' | Select-Object -Unique) -icontains $_.Name} | Foreach-Object {
    try {
        $Request = Invoke-RestMethodAsync "https://minermore.com/api/wallet?address=$($_.Value)" -delay $(if ($Count){500} else {0}) -cycletime ($Config.BalanceUpdateMinutes*60)
        $Count++
        if (($Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) {
            Write-Log -Level Info "Pool Balance API ($Name) for $($_.Name) returned nothing. "
        } else {
            [PSCustomObject]@{
                Caption     = "$($Name) ($($Request.currency))"
				BaseName    = $Name
                Currency    = $Request.currency
                Balance     = [Decimal]$Request.balance
                Pending     = [Decimal]0
                Total       = [Decimal]$Request.balance
                Paid        = [Decimal]$Request.total_paid
                Payouts     = @()
                LastUpdated = (Get-Date).ToUniversalTime()
            }
        }
    }
    catch {
        if ($Error.Count){$Error.RemoveAt(0)}
        Write-Log -Level Verbose "Pool Balance API ($Name) for $($_.Name) has failed. "
    }
}
