param location string = resourceGroup().location

param name string

param adminUsername string
@secure()
param adminPublicSshKey string

@allowed(['Ubuntu-2204'])
param ubuntuOSVersion string
param size string

param virtualNetworkName string
param virtualNetworkSubnetName string
param virtualNetworkResourceGroupName string

param firewallIpsForSsh array

var imageReference = {
  'Ubuntu-2204': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-jammy'
    sku: '22_04-lts-gen2'
    version: 'latest'
  }
}
var networkSecurityGroupName = '${name}-nsg'
var publicIPAddressName = '${name}-public-ip'
var networkInterfaceName = '${name}-net-int'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-01-01' existing = {
  name: virtualNetworkName
  scope: resourceGroup(virtualNetworkResourceGroupName)
}
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-01-01' existing = {
  name: virtualNetworkSubnetName
  parent: virtualNetwork
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddress.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
  }
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [for ip in firewallIpsForSsh: {
        name: 'SSH'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: ip
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: publicIPAddressName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: size
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      imageReference: imageReference[ubuntuOSVersion]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    osProfile: {
      computerName: name
      adminUsername: adminUsername
      adminPassword: adminPublicSshKey
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: adminPublicSshKey
            }
          ]
        }
      }
    }
    securityProfile: {
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
      securityType: 'TrustedLaunch'
    }
  }

  resource guestAttestationExtension 'extensions' = {
    name: 'GuestAttestation'
    location: location
    properties: {
      publisher: 'Microsoft.Azure.Security.LinuxAttestation'
      type: 'GuestAttestation'
      typeHandlerVersion: '1.0'
      autoUpgradeMinorVersion: true
      enableAutomaticUpgrade: true
      settings: {
        AttestationConfig: {
          MaaSettings: {
            maaEndpoint: substring('emptystring', 0, 0)
            maaTenantName: 'GuestAttestation'
          }
        }
      }
    }
  }
}
