#Create a new database, and create a user for it
#Then run the following
Param($Data, $SQLIP="localhost", $UserID="root", $UserPWD, $Database="WordNetDictionary", $SSL=$true)

#From Thomas Maurer
#https://www.thomasmaurer.ch/2011/04/powershell-run-mysql-querys-with-powershell/
Function Run-MySQLQuery {
<#
.SYNOPSIS
   run-MySQLQuery
    
.DESCRIPTION
   By default, this script will:
    - Will open a MySQL Connection
	- Will Send a Command to a MySQL Server
	- Will close the MySQL Connection
	This function uses the MySQL .NET Connector or MySQL.Data.dll file
     
.PARAMETER ConnectionString
    Adds the MySQL Connection String for the specific MySQL Server
     
.PARAMETER Query
 
    The MySQL Query which should be send to the MySQL Server
	
.EXAMPLE
    C:\PS> run-MySQLQuery -ConnectionString "Server=localhost;Uid=root;Pwd=p@ssword;database=project;" -Query "SELECT * FROM firsttest" 
    
    Description
    -----------
    This command run the MySQL Query "SELECT * FROM firsttest" 
	to the MySQL Server "localhost" with the Credentials User: Root and password: p@ssword and selects the database project
         
.EXAMPLE
    C:\PS> run-MySQLQuery -ConnectionString "Server=localhost;Uid=root;Pwd=p@ssword;database=project;" -Query "UPDATE firsttest SET firstname='Thomas' WHERE Firstname like 'PAUL'" 
    
    Description
    -----------
    This command run the MySQL Query "UPDATE project.firsttest SET firstname='Thomas' WHERE Firstname like 'PAUL'" 
	to the MySQL Server "localhost" with the Credentials User: Root and password: p@ssword
	
.EXAMPLE
    C:\PS> run-MySQLQuery -ConnectionString "Server=localhost;Uid=root;Pwd=p@ssword;" -Query "UPDATE project.firsttest SET firstname='Thomas' WHERE Firstname like 'PAUL'" 
    
    Description
    -----------
    This command run the MySQL Query "UPDATE project.firsttest SET firstname='Thomas' WHERE Firstname like 'PAUL'" 
	to the MySQL Server "localhost" with the Credentials User: Root and password: p@ssword and selects the database project
    
#>
	Param(
        [Parameter(
            Mandatory = $true,
            ParameterSetName = '',
            ValueFromPipeline = $true)]
            [string]$query,   
		[Parameter(
            Mandatory = $true,
            ParameterSetName = '',
            ValueFromPipeline = $true)]
            [string]$connectionString
        )
	Begin {
		Write-Verbose "Starting Begin Section"		
    }
	Process {
		Write-Verbose "Starting Process Section"
		try {
			# load MySQL driver and create connection
			Write-Verbose "Create Database Connection"
			# You could also could use a direct Link to the DLL File
			# $mySQLDataDLL = "C:\scripts\mysql\MySQL.Data.dll"
			# [void][system.reflection.Assembly]::LoadFrom($mySQLDataDLL)
			[void][System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")
			$connection = New-Object MySql.Data.MySqlClient.MySqlConnection
			$connection.ConnectionString = $ConnectionString
			Write-Verbose "Open Database Connection"
			$connection.Open()
			
			# Run MySQL Querys
			Write-Verbose "Run MySQL Querys"
			$command = New-Object MySql.Data.MySqlClient.MySqlCommand($query, $connection)
			$dataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($command)
			$dataSet = New-Object System.Data.DataSet
			$recordCount = $dataAdapter.Fill($dataSet, "data")
			$dataSet.Tables["data"] | Format-Table
		}		
		catch {
			Write-Host "Could not run MySQL Query" $Error[0]
            Write-Host $query
		}	
		Finally {
			Write-Verbose "Close Connection"
			$connection.Close()
		}
    }
	End {
		Write-Verbose "Starting End Section"
	}
}

$ConnectionString = "Server=$SQLIP;Uid=$UserID;Pwd=$UserPWD;database=$Database;Encrypt=$SSL"

$TableCreateQueries = @(
    "CREATE TABLE Words (ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE, Word VARCHAR(255) NOT NULL, Glossary VARCHAR(2048), SynSetID BIGINT, Type VARCHAR(1) NOT NULL);",
    "CREATE TABLE Relations (ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE, SourceID BIGINT NOT NULL, PairedID BIGINT NOT NULL, Relationship VARCHAR(2) NOT NULL, PairedType VARCHAR(1) NOT NULL);",
    "CREATE INDEX Word ON Words (Word);",
    "CREATE INDEX SynSetID ON Words (SynSetID);",
    "CREATE INDEX SourceID ON Relations (SourceID);",
    "CREATE INDEX PairedID ON Relations (PairedID);",
    "CREATE INDEX Type ON Words (Type);",
    "CREATE INDEX Type ON Relations (PairedType);"
)

foreach ($Query in $TableCreateQueries) {
    Run-MySQLQuery -ConnectionString $ConnectionString -query $Query
}


$LastUpdate = [DateTime]::Now
$UpdateSchedule = [TimeSpan]::FromSeconds(5)
$I=0;
foreach ($Word in $Data["Words"]) {
    $Name = $Word.Name.Replace("'", "\'")
    $Description = $Word.Glossary.Replace("'", "\'").Trim()
    $Query = "INSERT INTO Words (Word, Glossary, SynSetID, Type) VALUES ('$Name', '$Description', $($Word.ID), '$($Word.Type)');"
    Run-MySQLQuery -ConnectionString $ConnectionString -query $Query
    $I++;
    if ([DateTime]::Now - $LastUpdate -gt $UpdateSchedule) {
        Write-Host "$($I)/$($Data["Words"].Count)"
        $LastUpdate = [DateTime]::Now
    }
}
Write-Host "On to relations"
$I=0;
foreach ($Relation in $Data["Relations"]) {
    $Relationship = $Relation.Relationship.Replace("\", "\\")
    $Query = "INSERT INTO Relations (SourceID, PairedID, Relationship, PairedType) VALUES ($($Relation.SourceID), $($Relation.PairedID), '$($Relationship)', '$($Relation.PairedType)');"
    Run-MySQLQuery -ConnectionString $ConnectionString -query $Query
    $I++;
    if ([DateTime]::Now - $LastUpdate -gt $UpdateSchedule) {
        Write-Host "$($I)/$($Data["Relations"].Count)"
        $LastUpdate = [DateTime]::Now
    }
}
Write-Host "Done"