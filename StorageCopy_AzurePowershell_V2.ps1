param(
 
    [Parameter (Mandatory = $false)]
    [string]$AppId = '84af1d64-e5d3-46df-af8d-b62eefb2c494',
 
    [Parameter (Mandatory = $false)]
    [string]$PWord = 'af56f44c-b1a4-4422-8453-d7e2bb4cbddd',
 
    [Parameter (Mandatory = $false)]
    [string]$TenantId = '5b973f99-77df-4beb-b27d-aa0c70b8482c',
 
    [Parameter (Mandatory = $false)]
    [string]$subscriptionID = '879ec86a-0a85-42f3-9b9a-4d1cdfa07053',

    [Parameter (Mandatory = $false)]
    [string]$ResourceGroup = 'storagepoc'
)

$SPWord = ConvertTo-SecureString $PWord -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential($AppId, $SPWord)
Write-Host "Trying to login to Azure using SPN"
Connect-AzAccount -ServicePrincipal -Credential $Credential -TenantId $TenantId -SubscriptionId $subscriptionID
Write-Output "Login Successful"


#Connect to the AZure Subscription
Set-AzContext -SubscriptionId "879ec86a-0a85-42f3-9b9a-4d1cdfa07053"


#Generate Start and End Time
#$StartTime = Get-Date
#$EndTime = $startTime.AddHours(2.0)


#Set Context for Primary Storage Account
$primstorekey = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroup -Name "primstore").Value[0]
$primstoragecontext = New-AzStorageContext -StorageAccountName "primstore" -StorageAccountKey $primstorekey

#Write-Host "Generating SAS Token for Primary Storage Account"
#$sasprimary = $(New-AzStorageAccountSASToken -Context $primstoragecontext -Service Blob, File, Table, Queue -ResourceType Service, Container, Object -Permission "racwdlup" -StartTime $StartTime -ExpiryTime $EndTime)
#Write-Host $sasprimary


#Set Context for Secondary Storage Account
$secostorekey = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroup -Name "secostore").Value[0]
$seconstorgecontext = New-AzStorageContext -StorageAccountName "secostore" -StorageAccountKey $secostorekey


#Write-Host "Generating SAS Token for Secondary Storage Account"
#$sassecondary = $(New-AzStorageAccountSASToken -Context $seconstorgecontext -Service Blob, File, Table, Queue -ResourceType Service, Container, Object -Permission "racwdlup" -StartTime $StartTime -ExpiryTime $EndTime)
#Write-Host $sassecondary

#Get Container List
$containerlist = (Get-AzStorageContainer -Context $primstoragecontext).Name

#Select the Documents folder which is to be copied

foreach ($c in $containerlist) {
    if ($c -eq 'documents') {
        $lm = $(Get-AzStorageBlob -Container $c -Context $primstoragecontext).Name
        $c
        foreach ($l in $lm) {
            #$fprimary ="https://primstore.blob.core.windows.net/$c"+"?"+"$sasprimary"
            #$fsecondary ="https://secostore.blob.core.windows.net/$c"+"?"+"$sassecondary"
            #azcopy copy  $fprimary $fsecondary --recursive --s2s-preserve-access-tier=false
       
            Start-AzStorageBlobCopy -Context $primstoragecontext -SrcContainer $c -SrcBlob $l -DestContext $seconstorgecontext -DestContainer $c -Force
        }
    }
}

