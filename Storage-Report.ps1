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
$TD=@"
<td style="border: 3px solid  #333333; padding: 4px;">
"@

#Iterate through each drive on each server
foreach($Server in $ServerList){
    $drive = "$DriveLetter\"
    foreach($DriveLetter in $DriveLetters){
        try{
            $Drive = Get-WmiObject Win32_LogicalDisk -ComputerName $Server -Filter "DeviceID='$DriveLetter'" -ErrorAction Stop | Select-Object Size,FreeSpace
            $DriveSize = [Math]::Round($Drive.size / 1GB)
            $DriveFreeSpace = [Math]::Round($Drive.freespace / 1GB)
            # Remove unused Drives
            if($DriveSize -eq 0){
            
                continue
                }

            # Determine all other Safe drives, which is more than 10GB Free. If it is less than 10gb, mark for safe
            elseif($DriveFreeSpace -lt 5){
                $EmailBodyCriticalName="$TD$Server</td>"
                $EmailBodyCriticalLetter="$TD$DriveLetter\</td>"
                $EmailBodyCriticalUsed=("$TD$DriveFreeSpace/$DriveSize GB</td>")
                
                $EmailBodyCritical=$EmailBodyCritical+"
                <tr>
                $EmailBodyCriticalName
                $EmailBodyCriticalLetter
                $EmailBodyCriticalUsed
                </tr>

                "
                }
            else{
                $EmailBodySafeName="$TD$Server</td>"
                $EmailBodySafeLetter="$TD$DriveLetter\</td>"
                $EmailBodySafeUsed="$TD$DriveFreeSpace/$DriveSize GB</td>"
                
                $EmailBodySafe=$EmailBodySafe+"
                <tr>
                $EmailBodySafeName
                $EmailBodySafeLetter
                $EmailBodySafeUsed
                </tr>
                "
                }
            } 
        catch{ 
                $EmailBodyFailedName="$TD$Server</td>"
                $EmailBodyFailedLetter="$TD$DriveLetter</td>"
                
                $EmailBodyFailed=$EmailBodyFailed+"
                <tr>
                $EmailBodyFailedName
                $EmailBodyFailedLetter
                </tr>
                "
        }
    }
}


$HTML=@"
<h2 style="font-family: verdana">Daily Server storage report for $Date</h2>
&nbsp
&nbsp
<h3><b style="font-family: verdana;">Servers with critical storage shortage</b></h3>
<table style="border-collapse: collapse; border: 3px solid #333333; font-family: verdana; border-color: #333;">
    <tr style="background: #eeeeee;border: 3px solid #333333;"><b>
        <th style="padding: 10px;border: 3px solid #333333;">Server Name</th>
        <th style="padding: 10px;border: 3px solid #333333;">Drive Letter</th>
        <th style="padding: 10px;border: 3px solid #333333;">Storage Left</th>
        </b>
    </tr>
    $EmailBodyCritical
</table>
&nbsp
&nbsp
<h3><b style="font-family: verdana;">Servers with safe storage amounts</b></h3>
<table style="border-collapse: collapse; border: 3px solid #333333; font-family: verdana; border-color: #333;">
    <tr style="background: #eeeeee;border: 3px solid #333333;"><b>
        <th style="padding: 10px;border: 3px solid #333333;">Server Name</th>
        <th style="padding: 10px;border: 3px solid #333333;">Drive Letter</th>
        <th style="padding: 10px;border: 3px solid #333333;">Storage Left</th>
        </b>
    </tr>
    $EmailBodySafe
</table>
&nbsp
&nbsp
<h3><b style="font-family: verdana;">Servers with failed RPC connections</b></h3>
<table style="border-collapse: collapse; border: 3px solid #333333; font-family: verdana; border-color: #333;">
    <tr style="background: #eeeeee;border: 3px solid #333333;"><b>
        <th style="padding: 10px;border: 3px solid #333333;">Server Name</th>
        <th style="padding: 10px;border: 3px solid #333333;">Drive Letter</th>
        </b>
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
