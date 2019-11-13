param(
 
   [Parameter (Mandatory = $false)]
   [string]$AppId = '84af1d64-e5d3-46df-af8d-b62eefb2c494',
 
   [Parameter (Mandatory = $false)]
   [string]$PWord = 'af56f44c-b1a4-4422-8453-d7e2bb4cbddd',
 
   [Parameter (Mandatory = $false)]
   [string]$TenantId = '5b973f99-77df-4beb-b27d-aa0c70b8482c',
 
   [Parameter (Mandatory = $false)]
   [string]$subscriptionID = '879ec86a-0a85-42f3-9b9a-4d1cdfa07053'
)

$SPWord = ConvertTo-SecureString $PWord -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential($AppId, $SPWord)
Write-Host "Trying to login to Azure using SPN"
Connect-AzAccount -ServicePrincipal -Credential $Credential -TenantId $TenantId -SubscriptionId $subscriptionID
Write-Output "Login Successful"


#Connect to the AZure Subscription
az account set --subscription "879ec86a-0a85-42f3-9b9a-4d1cdfa07053"

#get the timing of 60 mins where the SAS token is valid
$end =$((Get-Date).AddMinutes(60).ToString("yyyy-MM-dTH:m:sZ"))

#Provide the Name of the Storage account 
#$primarystorage="https://auedtasdidsta01.blob.core.windows.net"
#$secondarystorage="https://auedtasdidsta02.blob.core.windows.net"



#get the SAS Token for all Storage account
Write-Host "Generating SAS Token for Storage Account"
$sasprimary=$(az storage account generate-sas --permissions cdlruwap --account-name "primstore" --services bfqt --resource-types sco --expiry $end --https-only -o tsv)
Write-Host $sasprimary

$sassecondary=$(az storage account generate-sas --permissions cdlruwap --account-name "secostore" --services bfqt --resource-types sco --expiry $end --https-only -o tsv)
Write-Host $sassecondary

#get the Storage Account Key

#$primstakey= (az storage account keys list -g storagepoc -n primstore --subscription "879ec86a-0a85-42f3-9b9a-4d1cdfa07053" --query [0].value -o tsv)
#Write-Host $primstakey 

#get the Container name of the Storage account which needs to be copied
#$containerlist=$(az storage container list --account-name "primstore" --sas-token $sasprimary  --query "[].{name:name}" --output tsv)

$containerlist=$(az storage container list --account-name primstore --sas-token $sasprimary --query "[].{name:name}" --output tsv)

Write-Host $containerlist

#Select the Documents folder which is to be copied
foreach($c in $containerlist)
{
if($c -eq 'documents')
{
	$lm=$(az storage blob list --container-name $c --account-name primstore --sas-token $sasprimary --output tsv) 
	$c
	foreach($l in $lm)
	{
	$l
		$fprimary ="https://primstore.blob.core.windows.net/$c"+"?"+"$sasprimary"
		$fsecondary ="https://secostore.blob.core.windows.net/$c"+"?"+"$sassecondary"
        #azcopy copy  $fprimary $fsecondary --recursive --s2s-preserve-access-tier=false
        azcopy sync  $fprimary $fsecondary --recursive=true
	}
}
}