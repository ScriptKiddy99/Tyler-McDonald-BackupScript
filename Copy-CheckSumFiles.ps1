
[CmdletBinding()]
Param
(
    # Source destination, this will contain the folders you want to validate then copy.
    [Parameter(
        Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
         Position=0)]
    [String]
    $Source,

    # Destination, this is the directory you want the validate files to be sent.
    [Parameter(
        Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
         Position=1)]
    [String]
    $Destination,

    # Recurse, By default the script will only copy the top level of the source file structure, recurse will copy everything.
    [Parameter(
    Mandatory=$false,
    ValueFromPipelineByPropertyName=$true,
        Position=2)]
    [Switch]
    $Recurse


)

Begin
{
    #region Variable Decleration

    # This array will hold all the file items from our source folder
    [Array]$SourceFiles = $Null 
    [Array]$ValidFiles  = $Null

    [String]$CheckSumFilePath = "$((Get-Item $MyInvocation.MyCommand.Path).Directory)\CheckSum.json"

    # This will hold our check sum object
    [PSCustomObject]$CheckSums = $Null

    #endregion Variable Decleration
}
Process
{
    # Checks if we have a persitance CheckSum file, This is a json file that stores the files location and it's checksum like below;
    # {'c\\scripts\\something\\example.doc': "AE82ABE26634DEBEE9E6A2813044C9913D20C4DC2E36AB4D6D24936D8671147E"}
    Write-Host -ForegroundColor Cyan -Object "Validating persitance CheckSum file"

    # Checks if the checksum file exits, if not creates a new file with the base template.
    # { 
    #   'files': []
    # }
    if(-NOT(Test-Path -LiteralPath $CheckSumFilePath)) { 
        Write-Host -ForegroundColor Cyan -Object "File does not exist creating new check sum json"
        New-Item -Path $CheckSumFilePath  -ItemType File -Value $(@{Files=@()}| ConvertTo-Json -Depth 2) | Out-Null
    }
    else { 
         Write-Host -ForegroundColor Cyan -Object "Check sum file found"
    }

    # Loads the check sum json file, which contains out MD5 Hashs for each source file.
    Write-Host -ForegroundColor Cyan -Object "Loading check sum content"
    $CheckSums = ( Get-Content -Path $CheckSumFilePath -Raw | ConvertFrom-Json )

    # Validate the source location exists
    Write-Host -ForegroundColor Cyan -Object "Validating source location exists [$Source]"
    if (-NOT(Test-Path -LiteralPath $Source -IsValid)) { 
        throw "Source location does not exist [$Source]"
    }


    # Get all the files from the source location
    Write-Host -ForegroundColor Cyan -Object "Getting source files"
    $SourceFiles = Get-ChildItem -Path $Source -Recurse:$Recurse

    # If our check sum has no files, assume it's the first time running the script, and generate the hashes, then copy over the files. 
    if($CheckSums.files.count -eq 0) { 
        # Create initial hash for each file then copy them down/ 

        # Iterates through each source file
        ForEach($File in $SourceFiles) { 
            # Generates a new MD5 hash for this file
            $FileCheckSum = Get-FileHash -Path $file.FullName -Algorithm MD5

            # Saves the Path and hash values from our new checksum
            $CheckSums.Files += $FileCheckSum | Select-Object -Property Hash,Path

            # Copies over the source file to the destination location
            Write-Host -ForegroundColor Green -Object "Copying file [$($File.FullName)] to $Destination"
            Copy-Item -Path $File.FullName -Destination $Destination -Force
        }

        # Saves our newly created hashes and file locations, which we will use to validate file changes in the next script execution
        Set-Content -LiteralPath $CheckSumFilePath -Value ($CheckSums | ConvertTo-Json)
    }
    else { 
        Write-Host -ForegroundColor Cyan -Object "Validating source files"
        ForEach($File in $SourceFiles) {
            $FileCheckSum = Get-FileHash -Path $file.FullName -Algorithm MD5

            ForEach($CheckSum in $CheckSums.Files) {
                if($CheckSum.Path -eq $File.FullName) { 
                    if($CheckSum.Hash -eq $FileCheckSum.Hash) {
                        $ValidFiles += $File.FullName
                    }
                }
            }
        }

        $ValidFiles | ForEach-Object {  
            Write-Host -ForegroundColor Green -Object "Copying file [$_] to $Destination"
            Copy-Item -Path $_ -Destination $Destination -Force | Out-Null 
        }
        
    }
}
End
{
}
