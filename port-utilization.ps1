<##
    .DESCRIPTION
    This script will execute an SQL query to get the port utilization of faxback server.  It is going to log the failed report for logDNA.  LogDNA will get the updated logs

    .AUTHOR
    John de Guerto

    .EXAMPLE
    Task Scheduler Command argument or to execute the script, we set MaxPort to 24 (1-24).  Max port is the Faxback port license we're allowed
    C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -Command "& 'C:\oit\port-utilization-script\port-utilization.ps1' -MaxPort 24"
#>

param(
    ## The SQL file which will only query the current hour when the script is executed
    $SQLFile = 'HourlySQLReportQuery.sql',

    ## The max port is the license of allowed port on faxback
    $MaxPort = 24,

    ## Working Directory of the script
    $WorkingDir = 'C:\oit\port-utilization-script\',

    ## Log Directory for saving failed logs
    $LogDir = 'C:\oit\LogDNA\Logs'
)

$Hostname = $env:COMPUTERNAME
$LogDT = $((get-date).ToLocalTime()).ToString("yyyy-MM-dd HH:mm:ss")

$CurrentDateTimeHour = $((get-date).ToLocalTime()).ToString("yyyy-MM-dd HH")
$StartTime = "$($CurrentDateTimeHour):00:00"
$EndTime =  "$($CurrentDateTimeHour):59:59"

## *** TEST *** 
# This is the expected value, and you can adjust and uncomment this value to test the script
#$StartTime = "2021-10-28 8:00:00"
#$EndTime =  "2021-10-28 8:59:59"


## Script variables
## SQLServerName is the DB connection name
$SQLServerName = '(local)\NETSATISFAXTION'

## Full path of the SQL File based on the working directory
$SQLInputFile = Join-Path $WorkingDir $SQLFile

## Full path of the failed log based on the working directory
$FailLog = join-path $LogDir "$($Hostname)-Port-Exceeded.log"

## Full path of the error log based on the working directory
$ErrorLog = join-path $LogDir "$($Hostname)-PortUtilization-Error.log"

function Invoke-Report{
<##
    .DESCRIPTION
    Read the SQL file, change start date time and end date time then execute the query using invoke-sqlcmd.  Filter out any 0 values.

    .EXAMPLE
    invoke-report -SQLInFile 'c:\query.sql' -ReportDateTimeStart '2021-10-18 15:00:00' -ReportDateTimeEnd '2021-10-18 15:59:59'
#>

    param(
        $ServerName = '(local)\NETSATISFAXTION',
        $SQLInFile = '',
        $ReportDateTimeStart = '', # format 9/21/2021 or 2021-09-21 00:00:00.000
        $ReportDateTimeEnd = '' # format 9/21/2021 or 2021-09-21 00:00:00.000
    )

    # A file where we are saving the modified SQL Input
    $TempOutFile = join-path $WorkingDir 'ransqlquery.sql'


    ## We are replcing report-time-start and report-time-end in the sql file as a keyword placehold
    ## Then we are saving the faile to TempOutFile
    $SqlFileContent = (Get-Content -Path $SQLInFile -Raw) -replace 'report-time-start', $ReportDateTimeStart 
    $SqlFileContent = $SqlFileContent -replace 'report-time-end', $ReportDateTimeEnd
    $SqlFileContent | Out-File $TempOutFile -Encoding 'utf8'

    ## We then invoke the Temp SQL file that we modified using the Server Instance defined as $ServerName parameter
    $RawReport = Invoke-Sqlcmd -InputFile $TempOutFile -ServerInstance $ServerName #| Export-Csv -NoTypeInformation -Path $SQLOutFile -Encoding "UTF8"

    ## Just basic output for the variables used in this function
    $ServerName
    $SQLInFile
    $ReportDateTimeStart
    $ReportDateTimeEnd
    $TempOutFile
    $RawReport
    $RawReport |  Where-Object { $_.Total -ne 0} 
}

## We end the script and throw an exception error if the SQL file doesn't exists
if( -not (Test-Path $SQLInputFile) ){
    $message = "[$($LogDT)] - $SQLInputFile does not exists!"
    $message | Out-File $ErrorLog -Append
    throw $message
} else {
    "$SQLInputFile found! Continuing..."
}


## We invoke the report function and we pass the SQLInputFile, DatetimeStart and DateTimeEnd as defined above
$Report = invoke-report -SQLInFile $SQLInputFile -ReportDateTimeStart $StartTime -ReportDateTimeEnd $EndTime

## We then check if any of the report the last hour has exceeded our Max Port value
$FailedReport = $Report | Where-Object { $_.Total -gt $MaxPort }

## We then create a log of this failed report which LogDNA will pickup as saved in the LogDir
# $FailedReport

if( $FailedReport.Length -gt 0){
    $report = ""
    $FailedReport | ForEach-Object {
        $report += "Date=$($_.Minute) Port=$($_.Total)`r`n" 
    }
    $Report | Out-File -FilePath $FailLog -Encoding utf8 -Append
    ## Now check the log file it generated
}


## MY TEAMS GENERAL Channel email address
#5afeaf16.oit.co@amer.teams.ms