Param(
	[Parameter(Mandatory)][string]$sqlServerInstance,
    [Parameter(Mandatory)][string]$sqlDatabase,
    [Parameter()][bool]$autoCreateDatabase
)

Clear

#$bcp = "C:\Program Files (x86)\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\bcp.exe"
$bcp = "bcp.exe"

Set-Location $PSScriptRoot;

function InitDatabase{
    Param(
        [string]$sqlServerInstance,
        [string]$sqlDatabase    
    )

    $sqlText = "
        USE $($sqlDatabase);
        IF OBJECT_ID('[dbo].[__DbVersion]') IS NULL BEGIN
            CREATE TABLE [dbo].[__DbVersion](
                [Id] [int] IDENTITY(1,1) NOT NULL,
                [Version] [varchar](10) NOT NULL,
                [Created] [datetime] NOT NULL,
                [CreatedBy] [varchar](200) NULL,
            CONSTRAINT [PK___DbVersion] PRIMARY KEY CLUSTERED 
            (
                [Id] ASC
            )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
            ) ON [PRIMARY]
            ALTER TABLE [dbo].[__DbVersion] ADD  CONSTRAINT [DF___DbVersion_Created]  DEFAULT (getdate()) FOR [Created]
            ALTER TABLE [dbo].[__DbVersion] ADD  CONSTRAINT [DF___DbVersion_CreatedBy]  DEFAULT (suser_sname()) FOR [CreatedBy]
            
            INSERT INTO [dbo].[__DbVersion] (Version) VALUES ('v0_00');
        END
    " 
    ExecuteScalar -sqlServerInstance $sqlServerInstance -sqlDatabase $sqlDatabase -sqlText $sqlText
}

function ExecuteNonQuery {
    Param (
        [string]$sqlServerInstance,
        [string]$sqlDatabase, 
        [string]$sqlText
    )

    $sqlConnectionString = 'Data Source=' + $sqlServerInstance + ';Integrated Security=SSPI;Initial Catalog=' + $sqlDatabase 
    $sqlConnection = new-object System.Data.SqlClient.SqlConnection($sqlConnectionString)
    $sqlConnection.Open()

    $sqlCommand = new-object System.Data.SqlClient.SqlCommand
    $sqlCommand.CommandTimeout = 0
    $sqlCommand.Connection = $sqlConnection

    $sqlCommand.CommandText = $sqlText
    $sqlCommand.ExecuteNonQuery()
            
    $sqlConnection.Close()
}

function ExecuteScalar {
    Param (
        [string]$sqlServerInstance,
        [string]$sqlDatabase, 
        [string]$sqlText
    )

    $sqlConnectionString = 'Data Source=' + $sqlServerInstance + ';Integrated Security=SSPI;Initial Catalog=' + $sqlDatabase 
    $sqlConnection = new-object System.Data.SqlClient.SqlConnection($sqlConnectionString)
    $sqlConnection.Open()

    $sqlCommand = new-object System.Data.SqlClient.SqlCommand
    $sqlCommand.CommandTimeout = 0
    $sqlCommand.Connection = $sqlConnection

    $sqlCommand.CommandText = $sqlText
    $result = $sqlCommand.ExecuteScalar()
    $sqlConnection.Close()

    $result
}

function CheckForDbVersionTable{
    Param (
        [string]$sqlServerInstance,
        [string]$sqlDatabase
    )
    $sqlText = "SELECT ISNULL(OBJECT_ID('dbo.__DbVersion'),0) AS ObjId"
    ExecuteScalar -sqlServerInstance $sqlServerInstance -sqlDatabase $sqlDatabase -sqlText $sqlText
}

function GetCurrentVersion{
    Param (
        [string]$sqlServerInstance,
        [string]$sqlDatabase
    )
    $sqlText = "SELECT TOP 1 Version FROM dbo.__DbVersion ORDER BY Id DESC"
    ExecuteScalar -sqlServerInstance $sqlServerInstance -sqlDatabase $sqlDatabase -sqlText $sqlText
}

function InsertMigratedToVersionRow{
    Param (
        [string]$sqlServerInstance,
        [string]$sqlDatabase,
        [string]$version
    )

    $sqlText = "INSERT INTO dbo.__DbVersion (Version) VALUES ('$($version)')"
    ExecuteScalar -sqlServerInstance $sqlServerInstance -sqlDatabase $sqlDatabase -sqlText $sqlText
}

function ExecuteSingleSqlScript
{
    param(
        [string]$sqlScriptFoldername,
        [string]$sqlScriptFilename
    )

    "Executing sql script: $($sqlScriptFilename)..."
    $sqlScriptContent = Get-Content "$sqlScriptFoldername\\$sqlScriptFilename" -Raw

    #handle multi-statement query file
    if($sqlScriptContent -match "GO"){
		$sqlStatementsReplaced = $sqlScriptContent -creplace "GO\b","GO;";    
        $sqlStatements = $sqlStatementsReplaced -csplit "GO;" | Where-Object {$_.length -gt 2}
        "Found $($statements.Count) SQL statements in file."
    
        $statementCount = 0
        foreach($sqlStatement in $sqlStatements){
            try{
                $result = ExecuteNonQuery -sqlServerInstance $sqlServerInstance -sqlDatabase $sqlDatabase -sqlText $sqlStatement
                Write-Progress -Activity "Executing statements" -Status "Progress:" -PercentComplete ($statementCount++/$sqlStatements.Count * 100)
            }
            catch
            {
                Write-Error "Failed executing statement: $sqlStatement"
                throw
            }
        }
    }
    else
    {
        #handle single file statement
        ExecuteNonQuery -sqlServerInstance $sqlServerInstance -sqlDatabase $sqlDatabase -sqlText $sqlScriptContent
    }
}
function ExecuteSqlScriptsInfolder
{
    param([string]$folderName)

    ""
    "Processing folder: " + $folderName 

    $sqlScripts = Get-ChildItem -Filter "*.sql" -Name -File $folderName | Sort-Object
    if($sqlScripts){
        "Files found: $($sqlScripts)"
        foreach($sqlScriptFilename in $sqlScripts){ 
            ExecuteSingleSqlScript $folderName $sqlScriptFilename 
        }
    }else{
        "No sql files found in folder: $($folderName)"
    }
}

function BulkLoadDatafile{
    param(
        [string]$folderName,
        [string]$dataFilename
    )

    Write-Host "Loading bulk load datafile: $folderName\$dataFilename...`n"
    $tableName = [io.path]::GetFileNameWithoutExtension($dataFilename)

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.CreateNoWindow = $true
    $pinfo.FileName = $bcp
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $filename = Resolve-Path "$folderName\$dataFilename"
    $pinfo.Arguments = "$tableName in `"$filename`" -c -F 2 -T -t `"|`" -S `"$sqlServerInstance`" -d $sqlDatabase"
    Write-Host "$($bcp) $($pinfo.Arguments)"
    
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    if(-not $p.ExitCode -eq 0){
        Write-Error "exitCode: $($p.ExitCode)"
        Write-Error "stdout: $stdout"
        Write-Error "stderr: $stderr"
    }
    $p.ExitCode
}

function BulkLoadDatafilesInFolder
{
    param([string]$folderName)
 
    Write-Host "Processing folder: " + $folderName 
    $bulkLoadDatafiles = Get-ChildItem -Filter "*.blk" -Name -File $folderName | Sort-Object

    $errorsFoundDuringLoad = 0
    if($bulkLoadDatafiles){
        Write-Host "Files found: $($bulkLoadDatafiles)"
        foreach($datafile in $bulkLoadDatafiles){ 
            $ef = BulkLoadDatafile -folderName $folderName -dataFilename $datafile 
            if($errorsFoundDuringLoad -eq 0 -and -not $ef -eq 0){
                $errorsFoundDuringLoad = $ef
                Write-Error "Bulk load failed! Stopping..."
                break
            }
            }  
    }
    return $errorsFoundDuringLoad
}

function ExecutePowerShellInFolder
{
    param([string]$folderName)

    $folders =  $folderName | Get-ChildItem -Name -Directory
    foreach($execFolder in $folders){ 
        Write-Host "Processing folder: " $execFolder 
        $script = "$($PSScriptRoot)\$($folderName)\$($execFolder)\$($execFolder).ps1 -sqlServerInstance $($sqlServerInstance) -sqlDatabase $($sqlDatabase)";
        Invoke-Expression $script
    }  

    return $errorsFoundDuringLoad
}

function ExecutePreExecuteFolder
{
    $folderName = Get-ChildItem -Name -Directory | Where-Object {$_ -like "_pre"} # We are only interested in folder named "Master"
    "Now, executing the _pre folder..."
    try
    {
        #runs all .ps1 files
        ExecutePowerShellInFolder $folderName
        "Completed."
    }
    catch
    {
        "Error!! Stopping..."
        Write-Host $_.Exception.Message -ForegroundColor "Red"        
    }
}

function ExecuteDraftExecuteFolder
{
    $folderName = Get-ChildItem -Name -Directory | Where-Object {$_ -like "_draft"} # We are only interested in folder named "Master"
    "Now, executing the _draft folder..."
    try
    {
        #runs all .ps1 files
        ExecutePowerShellInFolder $folderName
        "Completed."
    }
    catch
    {
        "Error!! Stopping..."
        Write-Host $_.Exception.Message -ForegroundColor "Red"        
    }
}

function ExecutePostExecuteFolder
{
    $folderName = Get-ChildItem -Name -Directory | Where-Object {$_ -like "_post"} # We are only interested in folder named "Master"
    "Now, executing the _post folder..."
    try
    {
        #runs all .ps1 files
        ExecutePowerShellInFolder $folderName
        "Completed."
    }
    catch
    {
        "Error!! Stopping..."
        Write-Host $_.Exception.Message -ForegroundColor "Red"        
    }
}

#check if database exists and auto-create if required
$sqlText = "SELECT ISNULL(DB_ID (N'$sqlDatabase'),0);";
$databaseExists = ExecuteScalar -sqlServerInstance $sqlServerInstance -sqlDatabase "master" -sqlText $sqlText

if(!$databaseExists){
    $sqlText = "CREATE DATABASE $sqlDatabase;"
    ExecuteNonQuery -sqlServerInstance $sqlServerInstance -sqlDatabase "master" -sqlText $sqlText
}

#check if database has been pre-configured to support migration
$dbVersionExists = CheckForDbVersionTable -sqlServerInstance $sqlServerInstance -sqlDatabase $sqlDatabase
if(!$dbVersionExists){
	InitDatabase -sqlServerInstance $sqlServerInstance -sqlDatabase $sqlDatabase;
}

#runs all scripts before migrated starts
ExecutePreExecuteFolder

#starts processing all migration steps
$currentVersion = GetCurrentVersion -sqlServerInstance $sqlServerInstance -sqlDatabase $sqlDatabase
"Current version of sqlDatabase '$($sqlDatabase)': $($currentVersion)"

$folderNames = Get-ChildItem -Name -Directory | Where-Object {$_ -like "v*_*-v*_*"} # We are only interested in folders named "v#_##-v#_##"
$maxVersionFolderName = $folderNames | Sort-Object | Select-Object -Last 1
$toVersion = $maxVersionFolderName.Substring($maxVersionFolderName.IndexOf("-")+1)
$errorOccured = 0

#when db version is latest, do nothing
if($currentVersion -eq $toVersion){
    $toVersionFound = 1
    ""
    "Current version of sqlDatabase is already the same as the specified value: $($toVersion)."
    "Stopping."
}
else
{
    $folderNames = Get-ChildItem -Name -Directory | Where-Object {$_ -like "v**_**-v**_**"} # We are only interested in folders named "v#_##-v#_##"
    $sortedFolderNames = $folderNames | Sort-Object

    $fromVersionFound = 0
    $toVersionFound = 0

    foreach($folderName in $sortedFolderNames){
        if($folderName -like "$($currentVersion)-*"){
            $fromVersionFound = 1
        }

        if(!$toVersionFound -and $fromVersionFound){

            if($folderName -like "*-$($toVersion)"){
                $toVersionFound = 1
            }

            try
            {
                #runs all .sql files
                ExecuteSqlScriptsInfolder $folderName
                
                #runs all .blk files
                $eo = BulkLoadDatafilesInFolder $folderName
                
                #runs all .ps1 files
                ExecutePowerShellInFolder $folderName

                if($errorOccured -eq 0 -and -not $eo -eq 0){
                    $errorOccured = $eo
                    "Error!! Stopping..."
                    break;
                }

                #track latest version executed in target db
                $processingVersion = $folderName.Substring($folderName.IndexOf("-")+1)
                InsertMigratedToVersionRow  -sqlServerInstance $sqlServerInstance -sqlDatabase $sqlDatabase -version $processingVersion
            }
            catch
            {
                "Error!! Stopping..."
                Write-Host $_.Exception.Message -ForegroundColor "Red"
                $errorOccured = 1
                break
            }
        }

        #reset the location, Invoke-Expression cause the script path to get lost
        Set-Location $PSScriptRoot;

        if($toVersionFound -or $errorOccured){           
            break # No more files to process or an error occured, so we stop
        }
    }

    if($errorOccured){
        "Error!! Stopped."
    }
}

if(!$errorOccured){
    #runs all draft scripts, scripts not yet graduated to a migration step
    ExecuteDraftExecuteFolder

    #runs all scripts after migrated completed
    ExecutePostExecuteFolder
    
    #reset the location, Invoke-Expression cause the script path to get lost
    Set-Location $PSScriptRoot;
}
