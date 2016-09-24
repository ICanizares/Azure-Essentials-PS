#
# Script.ps1
#

# $cred = Get-Credential
# Login-AzureRmAccount -Credential $cred
Import-m

$TenantID="350d072b-d849-4df7-93bf-d5593556851d"

Login-AzureRmAccount -TenantId $TenantId

Get-AzureRmSubscription –SubscriptionName “My Subscription” | Select-AzureRmSubscription
Get-AzureRmContext
Set-AzureRmCurrentStorageAccount –ResourceGroupName “AzureICR” –StorageAccountName “icrstorage01”
Get-AzureRmStorageAccount | Get-AzureStorageContainer | Get-AzureStorageBlob

# Obtener una lista de las ubicaciones
Get-AzureRmLocation | sort Location | Select Location
$locName = "westeurope"

# Crear un nuevo grupo de recursos en Azure
$rgName = "testgroup1"
New-AzureRmResourceGroup -Name $rgName -Location $locName

# Crear una cuenta de almacenamiento
$stName = "icrstorage02"
Get-AzureRmStorageAccountNameAvailability $stName
$storageAcc = New-AzureRmStorageAccount -ResourceGroupName $rgName -Name $stName -SkuName "Standard_LRS" -Kind "Storage" -Location $locName

# Crear una red virtual
$subnetName = "icrsubnet02"
$singleSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.0.0/24

$vnetName = "icrvnet02"
$vnet = New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -Location $locName -AddressPrefix 10.0.0.0/16 -Subnet $singleSubnet

# Crear una IP publica y una interfaz de red
$ipName = "icrIPaddress02"
$pip = New-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $rgName -Location $locName -AllocationMethod Dynamic

$nicName = "icrnic02"
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id

# Crear una maquina virtual
$cred = Get-Credential -Message "Introducir la clave de administrador local."
$vmName = "icrvm02"
$vm = New-AzureRmVMConfig -VMName $vmName -VMSize "Standard_A1"
$compName = "icrvm02"
$vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $compName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate

$vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2012-R2-Datacenter -Version "latest"
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

$blobPath = "vhds/ICRvm02WindowsVMosDisk.vhd"
$osDiskUri = $storageAcc.PrimaryEndpoints.Blob.ToString() + $blobPath

$diskName = "icrvm02windowsvmosdisk"
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $diskName -VhdUri $osDiskUri -CreateOption fromImage

New-AzureRmVM -ResourceGroupName $rgName -Location $locName -VM $vm