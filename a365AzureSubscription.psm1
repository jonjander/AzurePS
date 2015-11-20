function Confirm-a365AzureDefaultSubscription {
<#
.DESCRIPTION
   Confirms that you have selected the right azure subscription
.EXAMPLE
   PS C:>Confirm-a365AzureDefaultSubscription
.NOTE
#>
    [CmdletBinding()]
    Param
    ()

    Get-AzureSubscription -Default | select "SubscriptionName","Environment","DefaultAccount","CurrentStorageAccountName" | Format-List
    $title = "Use subscription"
    $message = "Do you want to use this subscription?"
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
        "Continue using this subscription."

    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
        "Change subscription."

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

    $result = $host.ui.PromptForChoice($title, $message, $options, 0) 

    switch ($result) {
        0 {
            Write-Verbose "Using default subscription"
        }
        1 {
        $newSub=$false
            Write-Verbose "Query subscriptions"
            [object[]]$subbisar=Get-AzureSubscription
            $subi=0
            $choices1=@()
            $subbisar.ForEach({
                write-host ("{0} : " -f $subi) -ForegroundColor White -NoNewline
                write-host ("{0} : " -f $PSItem.SubscriptionId) -ForegroundColor DarkCyan -NoNewline
                write-host ("{0} : " -f $PSItem.SubscriptionName) -ForegroundColor Magenta -NoNewline
                write-host ("{0}" -f $PSItem.DefaultAccount) -ForegroundColor Cyan
                $choices1+=New-Object System.Management.Automation.Host.ChoiceDescription ("&"+"$subi"),"$subi"
                $subi++
            })
            $title = "Use subscription"
            $message = "Select your subscription?"
            $choices1+=New-Object System.Management.Automation.Host.ChoiceDescription "N&ot in the list", "Add azure account."
            $options = [System.Management.Automation.Host.ChoiceDescription[]]($choices1)
            $result = $host.ui.PromptForChoice($title, $message, $options, 0) 
            $i
            if ($result -eq $subbisar.Count) {
                Write-Verbose "Not in the list adding azure account"
                $acureAcc = Add-AzureAccount -ErrorAction Stop -WarningAction Stop
                $acureAcc.Subscriptions.Split("`n") | % {Get-AzureSubscription -SubscriptionId $_} | select "SubscriptionId","SubscriptionName","Environment","DefaultAccount","CurrentStorageAccountName"
                $acureAccSubId=$acureAcc.Subscriptions.Split("`n")

                $title = "Use subscription"
                $message = "Select your subscription?"
                $choices1=@()
                $i=0
                foreach ($item in $acureAccSubId)
                {
                    $subName=(Get-AzureSubscription -SubscriptionId $item).SubscriptionName
                    [string]("$i : $item : $subName")
                    $choices1+=New-Object System.Management.Automation.Host.ChoiceDescription ("&"+"$i"),"$i"
                    $i++
                }
                $options = [System.Management.Automation.Host.ChoiceDescription[]]($choices1)
                $result = $host.ui.PromptForChoice($title, $message, $options, 0) 
                write-host $acureAccSubId[$result]
                Select-AzureSubscription -SubscriptionId $acureAccSubId[$result]
            } else {
                write-host ($subbisar[$result]).SubscriptionId
                Select-AzureSubscription -SubscriptionId ($subbisar[$result]).SubscriptionId
            }
        }
    }
    try {
        Get-AzureVM -ErrorAction Stop | select -First 1 | Out-Null
    } 
    catch {
        Write-Host "Session expired" -ForegroundColor Red
        $ac=Add-AzureAccount
    }
    Write-host "Current and default subscription" -ForegroundColor Green
    Get-AzureSubscription | ? {$_.IsDefault -eq $true -and $_.IsCurrent -eq $true}
}