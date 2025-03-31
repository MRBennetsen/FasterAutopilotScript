# Define variables
$Name = @("localhost") # List of computers to query
$OutputFile = ".\AutopilotDevices.csv" # Output file path

# Initialize an empty array to store computer details
$computers = @()

foreach ($comp in $Name) {
    try {
        # Create a CIM session
        $session = if ($comp -eq "localhost") {
            New-CimSession
        } else {
            New-CimSession -ComputerName $comp
        }

        # Get the serial number
        $serial = (Get-CimInstance -CimSession $session -Class Win32_BIOS).SerialNumber

        # Get the hardware hash
        $devDetail = Get-CimInstance -CimSession $session -Namespace root/cimv2/mdm/dmmap -Class MDM_DevDetail_Ext01 -Filter "InstanceID='Ext' AND ParentID='./DevDetail'"
        $hash = $devDetail.DeviceHardwareData

        # Create a pipeline object
        $computers += [PSCustomObject]@{
            "Device Serial Number" = $serial
            "Hardware Hash"        = $hash
        }

        Write-Host "Gathered details for device with serial number: $serial"
    } catch {
        Write-Error "Failed to retrieve details for $comp : $_"
    } finally {
        if ($session) {
            Remove-CimSession $session
        }
    }
}

# Export the collected data to a CSV file
$computers | Export-Csv -Path $OutputFile -NoTypeInformation -Force
Write-Host "Device details saved to $OutputFile"