# Required Variables
$DriveLetters = 'C:','D:','F:'
$ServerList = 'DC01','DC02','etc.','etc.'
$EmailTo = ""
$EmailFrom = ""
$EmailSubject = ""
$SmtpServer= ""
$SafeFreeSpaceGB = 10

# Allows script to be run with stored credentials. (Unsecure, stores password in plain text)
$Username = ""
$Password = ""
$secureStringPwd = $Password | ConvertTo-SecureString -AsPlainText -Force 
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $Username, $secureStringPwd

# Initialize variables
$EmailBodyCritical=@()
$EmailBodyCriticalName=@()
$EmailBodyCriticalLetter=@()
$EmailBodyCriticalUsed=@()
$EmailBodySafe=@()
$EmailBodySafeName=@()
$EmailBodySafeLetter=@()
$EmailBodySafeUsed=@()
$EmailBodyFailed=@()
$EmailBodyFailedName=@()
$EmailBodyFailedLetter=@()

#Iterate through each drive on each server
foreach($Server in $ServerList){
    $drive = "$DriveLetter\"
    foreach($DriveLetter in $DriveLetters){
        try{
            
            # Gather Drive Variables
            $Drive = Get-WmiObject Win32_LogicalDisk -ComputerName $Server -Filter "DeviceID='$DriveLetter'" -ErrorAction Stop | Select-Object Size,FreeSpace
            $DriveSize = [Math]::Round($Drive.size / 1GB)
            $DriveFreeSpace = [Math]::Round($Drive.freespace / 1GB)
            
            # Remove unused Drives
            if($DriveSize -eq 0){
                continue
                }
            
            # Determine all Critical drives that are under safe threshold.
            elseif($DriveFreeSpace -lt $SafeFreeSpaceGB){
                $EmailBodyCritical+="
                <tr>
                <td>$Server</td>
                <td>$DriveLetter\</td>
                <td>$DriveFreeSpace/$DriveSize GB</td>
                </tr>
                "
                }
           
            # Mark as safe if not critical
            else{
                $EmailBodySafe+="
                <tr>
                <td>$Server</td>
                <td>$DriveLetter\</td>
                <td>$DriveFreeSpace/$DriveSize GB</td>
                </tr>
                "
                }
            } 
       
       # Catch RPC / failed connection Errors 
        catch{ 
            $EmailBodyFailed+="
            <tr>
            <td>$Server</td>
            <td>$DriveLetter\</td>
            </tr>
            "
        }
    }
}


# Email HTML format
$HTML=@"
<h2 style="font-family: verdana">Daily Server storage report for $Date</h1>
&nbsp
&nbsp
<h3><b style="font-family: verdana;">Servers with critical storage shortage</b></h3>
<table style="font-family: verdana;border: 3px solid #333333;">
    <tr style="background: #eeeeee;border: 3px solid #333333;">
        <th style="padding: 10px;border: 3px solid #333333;"><b>Server Name</b></th>
        <th style="padding: 10px;border: 3px solid #333333;">Drive Letter</th>
        <th style="padding: 10px;border: 3px solid #333333;">Storage Used</th>
    </tr>
    $EmailBodyCritical
</table>
&nbsp
&nbsp
<h3><b style="font-family: verdana;">Servers with safe storage amounts</b></h3>
<table style="border: 3px solid #333333;font-family: verdana;">
    <tr style="background: #eeeeee;border: 3px solid #333333;">
        <th style="padding: 10px;border: 3px solid #333333;"><b>Server Name</b></th>
        <th style="padding: 10px;border: 3px solid #333333;">Drive Letter</th>
        <th style="padding: 10px;border: 3px solid #333333;">Storage Used</th>
    </tr>
    $EmailBodySafe
</table>
&nbsp
&nbsp
<h3><b style="font-family: verdana;">Servers that failed to provide storage</b></h3>
<table style="font-family: verdana;border: 3px solid #333333;">
    <tr style="background: #eeeeee;border: 3px solid #333333;">
        <th style="padding: 10px;border: 3px solid #333333;"><b>Server Name</b></th>
        <th style="padding: 10px;border: 3px solid #333333;">Drive Letter</th>
    </tr>
    $EmailBodyFailed
</table>
<p></p>
"@

# for testing, you can use:
# $HTML > c:\Storage-Report.html
# c:\Storage-Report.html


# Send Email
$Date = get-date
Send-MailMessage -credential $Credentials -To $EmailTo -From $EmailFrom -SmtpServer $SmtpServer -Priority High -Subject $EmailSubject -Body $HTML -BodyAsHtml