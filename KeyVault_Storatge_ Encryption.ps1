param(
    [Parameter(Mandatory= $false)]
    [string]$storageAccountName = "storcodevdd12345",
  
    [Parameter (Mandatory= $false)]
    [string]$KeyVaultName = 'kvcodevdd12345678916',

    [Parameter (Mandatory= $false)]
    [string]$keyName = 'codevkey',
  
    [Parameter (Mandatory = $false)]
    [string]$location = 'westeurope',

    [Parameter (Mandatory = $false)]
    [string]$ResourceGroupName = 'CoDevDD',

    [Parameter (Mandatory = $false)]
    [string]$skuName = "Standard_LRS"

)

$keyVaultAdminUsers = @('dinesh.sonawane@globant.com')

$keyVaultSPs = @('dinocodevsp')

$ResourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $location

# Create storage account and enable customer-managed keys for your storage account.
$storageAccount = New-AzStorageAccount -ResourceGroupName $ResourceGroup.ResourceGroupName -Name $storageAccountName -Location $location -SkuName $skuName
$storageAccount = Set-AzStorageAccount -ResourceGroupName $ResourceGroup.ResourceGroupName -Name $storageAccountName  -AssignIdentity

# Create Key Vault
$keyVault = New-AzKeyVault -Name $KeyVaultName -ResourceGroupName $ResourceGroup.ResourceGroupName -Location $Location -EnableSoftDelete  -EnablePurgeProtection

# foreach ($keyVaultAdminUser in $keyVaultAdminUsers) {
#     $UserObjectId = (Get-AzureRmADUser -SearchString $keyVaultAdminUser).ObjectId
#     Set-AzureRmKeyVaultAccessPolicy -VaultName $keyVault.VaultName -ResourceGroupName $ResourceGroup.ResourceGroupName -ObjectId $UserObjectId -PermissionsToKeys all -PermissionsToSecrets all -PermissionsToCertificates all
# }

foreach ($keyVaultAdminUser in $keyVaultAdminUsers) {
    $UserObjectId = (Get-AzureADUser -ObjectId $keyVaultAdminUser).ObjectId
    Set-AzureRmKeyVaultAccessPolicy -VaultName $keyVault.VaultName -ResourceGroupName $ResourceGroup.ResourceGroupName -ObjectId $UserObjectId -PermissionsToKeys Decrypt,Encrypt,UnwrapKey,List,Get,Update,WrapKey,Create,Delete -PermissionsToSecrets Get,List,Set,Delete,Backup -PermissionsToCertificates List
}

foreach ($keyVaultSP in $keyVaultSPs) {
    $SPId =  (Get-AzureADServicePrincipal -SearchString $keyVaultSP).ObjectId
    Set-AzureRmKeyVaultAccessPolicy -VaultName $keyVault.VaultName -ObjectId $SPId -PermissionsToKeys Decrypt,Encrypt,UnwrapKey,List,Get,Update,WrapKey,Create,Delete -PermissionsToSecrets Get,List,Set,Delete,Backup -PermissionsToCertificates List
}

# Provide access to the storage account to access the key from key vault.
Set-AzKeyVaultAccessPolicy -VaultName $keyVault.VaultName -ObjectId $storageAccount.Identity.PrincipalId -PermissionsToKeys wrapkey,unwrapkey,get,recover

# Add the Administrator policies to the Key Vault.


# Add key in Key Vault.
$key = Add-AzKeyVaultKey -VaultName $keyVault.VaultName -Name $keyName -Destination 'Software'

# Use above generated key for encryption of storage account
Set-AzStorageAccount -ResourceGroupName $storageAccount.ResourceGroupName -AccountName $storageAccount.StorageAccountName -KeyvaultEncryption -KeyName $key.Name -KeyVersion $key.Version -KeyVaultUri $keyVault.VaultUri

# Add Secret to Key Vault.
$secretvalueSendgrid = ConvertTo-SecureString 'abcdefghijk1234567' -AsPlainText -Force
$secretSendgrid = Set-AzKeyVaultSecret -VaultName $keyVault.VaultName -Name 'CodevSecretv' -SecretValue $secretvalueSendgrid

# Add Secret for SQL Admin Password and USername.
$secretvalueSQLUser = ConvertTo-SecureString 'SQLAdminuser' -AsPlainText -Force
$secretSQLUser = Set-AzKeyVaultSecret -VaultName $keyVault.VaultName -Name 'CodevSecretv2' -SecretValue $secretvalueSQLUser

$secretvalueSQLPassword = ConvertTo-SecureString 'Password@1234567' -AsPlainText -Force
$secretSQLPassword = Set-AzKeyVaultSecret -VaultName $keyVault.VaultName -Name 'CodevSecretv3' -SecretValue $secretvalueSQLPassword



