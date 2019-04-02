###########################################################
# Subscription
###########################################################
$subscription = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

az account set --subscription $subscription

###########################################################
# Resource Group
###########################################################
$rgName   = "RG-DDoA"
$location = "SouthCentralUS"

$resourceGroup = az group create --name $rgName --location $location

###########################################################
# Storage Account
###########################################################
$storageAcctName = ”ddoastrg”
$storageAcctType = “Standard_LRS”

$storageAcct = az storage account create --name $storageAcctName --resource-group $rgName --location $location

###########################################################
# Availability Set
###########################################################
az vm availability-set create --name "TCAvailabilitySet1" --resource-group $rgName --location $location

###########################################################
# Load Balancer
###########################################################

# Public IP
az network public-ip create --name "TCLBpip" --location $location --resource-group $rgName --allocation-method Static

# Load Balancer
az network lb create --name "TCLB" --location $location --resource-group $rgName --public-ip-address "TCLBpip"

# Probe
az network lb probe create --lb-name "TCLB" --name "TCLBprobe" --resource-group $rgName --port 80 --protocol "Tcp"

# Backend Address Pool
az network lb address-pool create --lb-name "TCLB" --name "BackEndAddressPool" --resource-group $rgName
 
# LB Rule: Port 80
az network lb rule create --frontend-port 80 --backend-port 80 --lb-name "TCLB" --name "LBRule80" --protocol "Tcp" --resource-group $rgName --frontend-ip-name "LoadBalancerFrontEnd" --backend-pool-name "BackEndAddressPool" --probe-name "TCLBprobe"

###########################################################
# NICs
###########################################################

# TC1 PIP
az network public-ip create --name "TC1pip" --location $location --resource-group $rgName --allocation-method Static

# TC1 NIC
$TC1NIC = az network nic create --name "TC1Nic" --resource-group $rgName --location $location --subnet "/subscriptions/68cf210d-efb0-4615-8b0f-20ae6c9ff0c3/resourceGroups/NON-PROD-NETWORK/providers/Microsoft.Network/virtualNetworks/NON-PROD-NETWORK-vnet/subnets/default" `
        --lb-address-pools "BackEndAddressPool" --lb-name "TCLB" --public-ip-address "TC1pip"

# TC2 PIP
az network public-ip create --name "TC2pip" --location $location --resource-group $rgName --allocation-method Static

# TC2 NIC
$TC2NIC = az network nic create --name "TC2Nic" --resource-group $rgName --location $location --subnet "/subscriptions/68cf210d-efb0-4615-8b0f-20ae6c9ff0c3/resourceGroups/NON-PROD-NETWORK/providers/Microsoft.Network/virtualNetworks/NON-PROD-NETWORK-vnet/subnets/default" `
        --lb-address-pools "BackEndAddressPool" --lb-name "TCLB" --public-ip-address "TC2pip"

###########################################################
# VMs
###########################################################
# Update for your admin password
$AdminPassword = "Password1234!"

# TC1
$VM1 = az vm create --resource-group $rgName --name "TC1" --location $location --nics "TC1Nic" --size Standard_D1_v2 --image UbuntuLTS --admin-username testadmin --admin-password $AdminPassword --availability-set "TCAvailabilitySet1"

# TC2
$VM1 = az vm create --resource-group $rgName --name "TC2" --location $location --nics "TC2Nic" --size Standard_D1_v2 --image UbuntuLTS --admin-username testadmin --admin-password $AdminPassword --availability-set "TCAvailabilitySet1"


# Future Goals: Custom Script on provision that installs Apache2 and modifies the files to display DDoA default site. 


#ssh adminaccount@ipofhost
#sudo apt-get update
#sudo apt-get install apache2
#sudo systemctl start apache2
#cd /var/www/html
#sudo chmod 777 index.html
#Add text to denote TC1 and TC2
#
#Browse to public ip of TC1 and TC2: Apache2 Ubuntu Default Page should be displayed and denoted
#
#Browse to public ip of TCLB: Apache2 Ubuntu Default Page should be displayed denoting which server you've connected to
#Turn off the server that you've connected to and refresh the Apache2 Ubuntu Default Page which should now denote the second server
