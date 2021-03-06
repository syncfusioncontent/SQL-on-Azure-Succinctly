# The original script for Provisioning of SQL Server Azure VM was created by Sourabh Agrawal and Amit Banerjee
# The script is modified by Parikshit Savjani to suit the readers of the book SQL on Azure Succintly

Add-AzureAccount | out-null
# Make sure the Authentication Succeeded.
If ($?)
{
	Write-Host "`tSuccess"
}
Else
{
	Write-Host "`tFailed authentication" -ForegroundColor Red
	Exit
}

#Select the desired Azure Subscription
[array] $AllSubs = Get-AzureSubscription 
If ($AllSubs)
{
        Write-Host "`tSuccess"
}
Else
{
        Write-Host "`tNo subscriptions found. Exiting." -ForegroundColor Red
        Exit
}
#Write-Host "`n[Select Option] - Select a Subscription to Work With" -ForegroundColor Yellow
$count = 1
ForEach ($Sub in $AllSubs)
{
   $SubName = $Sub.SubscriptionName
   Write-host "`n$count - $SubName"  -ForegroundColor Green
   $count = $count+1
}
$SubscriptionNumber = Read-Host "`n[SELECTION] - Select a Subscription to Provision the VM"
If($SubscriptionNumber -gt $count)
{
    Write-Host "`Invalid Subscription Entry - Existing" -ForegroundColor Red
    Exit
}
$SelectedSub = Get-AzureSubscription -SubscriptionName $AllSubs[$SubscriptionNumber - 1].SubscriptionName 3>$null 
$SubName = $SelectedSub.SubscriptionName
Write-Host "`n Selected Subscription - $SubName" -ForegroundColor Green 
$SelectedSub | Select-AzureSubscription | out-Null

#Identify the Azure Storage Account to be used to provision the VM
$StorAccName = Read-Host "`nEnter Azure Storage Account Name"
if(Get-AzureStorageAccount -StorageAccountName $StorAccName)
{
    Write-Host "`n[INFO] - Using Storage Account - $StorAccName" -ForegroundColor Yellow
}
else
{
    Write-Host "Storage Account $StorAccName does not Exists - Please Create it" -ForegroundColor Red
    Exit
}

# Identify the Cloud Service to Use to Provision the VM
$ServiceName = Read-Host "`nEnter your Cloud Service Name for VM"
if(Get-AzureService -ServiceName $ServiceName)
{
Write-Host "`n [INFO] - Cloud Service $ServiceName already exists, using the same..." -ForegroundColor Yellow
} 
else
{
$Location = (Get-AzureStorageAccount -StorageAccountName $StorAccName).Location.ToString() 3>$null 
New-AzureService -ServiceName $ServiceName -Location $Location|Out-Null
Write-Host "`n [INFO] - Cloud Service $ServiceName created..." -ForegroundColor Yellow
}
$azureService = Get-AzureService -ServiceName $ServiceName

#Get the name for the Azure VM
$VMName = Read-Host "`n Enter the name for the Azure VM" 
$VMName = $VMName.ToLower()

#Using PreConfigured Values for VM Size
$VmSize = "Standard_D11"

[array] $AllImageFamily = get-azurevmimage |where {$_.os -eq "Windows" -and $_.ImageFamily -like "*SQL*2014*" } | Sort-Object -Property PublishedDate -Descending
$cnt = 1
ForEach ($ImgFamily in $AllImageFamily)
{
   $ImgName = $ImgFamily.Label
   Write-host "`n$cnt - $ImgName"  -ForegroundColor Green
   $cnt = $cnt+1
}
$ImageNo = Read-Host "`n[SELECTION] - Select the Image to install"
If($ImageNo -gt $cnt)
{
    Write-Host "`Invalid Subscription Entry - Existing" -ForegroundColor Red
    Exit
}

$ImgName =$AllImageFamily[$ImageNo - 1].Label

Write-Host "`nCreating a VM of size $VMSize, with $ImgName " -ForegroundColor Green

#Identify the Admin Account and Password to be used for VM
$AdminAccount = Read-Host "`n Enter the Admin account name" 
$password = Read-Host "`n Enter the password" 

#Select the Storage to be used and Create the VM.
Set-AzureSubscription -SubscriptionName $SubName -CurrentStorageAccountName $StorAccName

Write-Host "`n[INFO] - Script is creating a $ImgName image, Please wait...." -ForegroundColor Yellow
New-AzureQuickVM -Windows -ServiceName $ServiceName -Name $VMName -ImageName $AllImageFamily[$ImageNo - 1].imagename -Password $password -AdminUsername $AdminAccount -InstanceSize $VmSize -EnableWinRMHttp | out-null

#Check to make sure that vm wac created
$CreatedVM = Get-AzureVM -ServiceName $ServiceName -Name $VMName -ErrorAction SilentlyContinue
If ($CreatedVM)
{
	Write-Host "`tVM Created Successfully"
}
Else
{
	Write-Host "`tFailed to create VM" -ForegroundColor Red
	Exit
}
