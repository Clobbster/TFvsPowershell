#############################################
# Resource Group
#############################################
resource "azurerm_resource_group" "RG-DDoA" {
  name     = "RG-DDoA"
  location = "SouthCentralUS"
}

#############################################
# Storage Account
#############################################
resource "azurerm_storage_account" "ddoastrg" {
  name                     = "ddoastrg"
  resource_group_name      = "${azurerm_resource_group.RG-DDoA.name}"
  location                 = "${azurerm_resource_group.RG-DDoA.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

#############################################
# Availability Set
#############################################
resource "azurerm_availability_set" "TCAvailabilitySet1" {
  name                = "TCAvailabilitySet1"
  location            = "${azurerm_resource_group.RG-DDoA.location}"
  resource_group_name = "${azurerm_resource_group.RG-DDoA.name}"
  managed             = true
}

#############################################
# Load Balancer
#############################################
resource "azurerm_public_ip" "TCLBpip" {
  name                = "TCLBpip"
  location            = "${azurerm_resource_group.RG-DDoA.location}"
  resource_group_name = "${azurerm_resource_group.RG-DDoA.name}"
  allocation_method   = "Static"
}

resource "azurerm_lb" "TCLB" {
  name                = "TCLB"
  location            = "${azurerm_resource_group.RG-DDoA.location}"
  resource_group_name = "${azurerm_resource_group.RG-DDoA.name}"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.TCLBpip.id}"
  }
}

resource "azurerm_lb_probe" "TCLBprobe" {
  resource_group_name = "${azurerm_resource_group.RG-DDoA.name}"
  loadbalancer_id     = "${azurerm_lb.TCLB.id}"
  name                = "TCLBprobe"
  port                = 80
}

resource "azurerm_lb_backend_address_pool" "TCLBbep" {
  resource_group_name = "${azurerm_resource_group.RG-DDoA.name}"
  loadbalancer_id     = "${azurerm_lb.TCLB.id}"
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_rule" "LBRule80" {
  resource_group_name            = "${azurerm_resource_group.RG-DDoA.name}"
  loadbalancer_id                = "${azurerm_lb.TCLB.id}"
  name                           = "LBRule80"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.TCLBbep.id}"
  probe_id                       = "${azurerm_lb_probe.TCLBprobe.id}"
}

#############################################
# Pull subnet information from Azure
#############################################
data "azurerm_subnet" "default" {
  name                 = "default"
  virtual_network_name = "NON-PROD-NETWORK-vnet"
  resource_group_name  = "NON-PROD-NETWORK"
}

output "subnet_id" {
  value = "${data.azurerm_subnet.default.id}"
}

#############################################
# NICs
#############################################

# TC1 Nic
resource "azurerm_public_ip" "TC1pip" {
  name                = "TC1pip"
  location            = "${azurerm_resource_group.RG-DDoA.location}"
  resource_group_name = "${azurerm_resource_group.RG-DDoA.name}"
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "TC1Nic" {
  name                = "TC1Nic"
  location            = "${azurerm_resource_group.RG-DDoA.location}"
  resource_group_name = "${azurerm_resource_group.RG-DDoA.name}"

  ip_configuration {
    name                                    = "tc-ip-config"
    subnet_id                               = "${data.azurerm_subnet.default.id}"
    public_ip_address_id                    = "${azurerm_public_ip.TC1pip.id}"
    private_ip_address_allocation           = "Dynamic"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.TCLBbep.id}"]
  }
}

# TC2 Nic 
resource "azurerm_public_ip" "TC2pip" {
  name                = "TC2pip"
  location            = "${azurerm_resource_group.RG-DDoA.location}"
  resource_group_name = "${azurerm_resource_group.RG-DDoA.name}"
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "TC2Nic" {
  name                = "TC2Nic"
  location            = "${azurerm_resource_group.RG-DDoA.location}"
  resource_group_name = "${azurerm_resource_group.RG-DDoA.name}"

  ip_configuration {
    name                                    = "tc-ip-config"
    subnet_id                               = "${data.azurerm_subnet.default.id}"
    public_ip_address_id                    = "${azurerm_public_ip.TC2pip.id}"
    private_ip_address_allocation           = "Dynamic"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.TCLBbep.id}"]
  }
}

# TC3 Nic 
resource "azurerm_public_ip" "TC3pip" {
  name                = "TC3pip"
  location            = "${azurerm_resource_group.RG-DDoA.location}"
  resource_group_name = "${azurerm_resource_group.RG-DDoA.name}"
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "TC3Nic" {
  name                = "TC3Nic"
  location            = "${azurerm_resource_group.RG-DDoA.location}"
  resource_group_name = "${azurerm_resource_group.RG-DDoA.name}"

  ip_configuration {
    name                                    = "tc-ip-config"
    subnet_id                               = "${data.azurerm_subnet.default.id}"
    public_ip_address_id                    = "${azurerm_public_ip.TC2pip.id}"
    private_ip_address_allocation           = "Dynamic"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.TCLBbep.id}"]
  }
}

#############################################
# VMs
#############################################

# TC1
resource "azurerm_virtual_machine" "TC1" {
  name                  = "TC1"
  location              = "${azurerm_resource_group.RG-DDoA.location}"
  resource_group_name   = "${azurerm_resource_group.RG-DDoA.name}"
  network_interface_ids = ["${azurerm_network_interface.TC1Nic.id}"]
  vm_size               = "Standard_DS1_v2"
  availability_set_id   = "${azurerm_availability_set.TCAvailabilitySet1.id}"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "TC1disk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "TC1"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

# TC2
resource "azurerm_virtual_machine" "TC2" {
  name                  = "TC2"
  location              = "${azurerm_resource_group.RG-DDoA.location}"
  resource_group_name   = "${azurerm_resource_group.RG-DDoA.name}"
  network_interface_ids = ["${azurerm_network_interface.TC2Nic.id}"]
  vm_size               = "Standard_DS1_v2"
  availability_set_id   = "${azurerm_availability_set.TCAvailabilitySet1.id}"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "TC2disk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "TC2"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

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

