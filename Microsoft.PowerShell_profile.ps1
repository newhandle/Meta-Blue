<#
    This function is meant to be ran out of the root folder of whatever pull you 
    what to analyze. Its pretty dope and auto stacks based on the field that is 
    defined in the $dataTypes hashtable.

    What you want is a file in the whitelist folder that is named ex. host_processes_wl.csv
    basically the same name as the output CSV but with _WL appended to it. Then, it needs the "Name"
    column that will act as a whitelist.
#>
function Audit-MetaBlue {
    $pullPath = (Get-Location).path
    $rawPath = "$pullPath\raw"
    $anomaliesPath = "$pullPath\Anomalies"
    $whitelistpath = "C:\Meta-Blue\Whitelist"
    $sourceNames = "Host","Server","Unknown"
    $dataTypes = @{                     
                    AccessibilityFeature = "PSChildName";
                    ARPCache = "IPAddress";
                    AVProduct = "pathToSignedReportingExe";                    
                    BITSJobs = "message";
                    DLLHash = "Path","Hash";
                    DLLSearchOrderHijacking = "Path";
                    DriverHash = "Path","Hash";
                    Drivers = "Pathname";
                    EnvironVars = "Name","VariableValue";
                    InstalledSoftware = "InstallLocation";
                    Logons = "name"; 
                    LSASSDriver = "Message";
                    NetAdapters = "ServiceName","Description";
                    PNPDevices = "pnpclass","name";
                    PortMonitors = "Driver";
                    PoshVersion = "State";
                    ProcessHash = "Path","Hash";
                    UserInitMprLogonScript = "HasLogonScripts";
                    UnsignedDrivers = "Path";
                    WMIEventFilters = "Query";
                    AlternateDataStreams = "Stream";
                    DiskDrives = "FirmwareRevision","Model";
                    DnsClientServerAddress = "Address";
                    Services = "pathname";
                    ShortcutModification = "filename","path";
                    SMBConns = "sharename";
                    CapapilityAccessManager = "pschildname","psparentpath";
                    DLLSinTempDirs = "Line";
                    LogicalDisks = "name","volumename"
                    ScheduledTaskDetails = "execute" , "arguments";
                    Processes = "executablepath";
                    RDPHistoricallyConnectedIps = "pscomputername" , "value";
                    NetshHelperDll = "2","4","authfwcfg","dhcpclient","dot3cfg","fwcfg","hnetmon","netiohlp","nettrace","nshhttp","nshwipsec","nshwfp","p2pnetsh","rpc","wcnNetsh","whhelper","wlancfg","wshelper","wwancfg","peerdistsh"
                    KnownDLLs = "_wow64cpu","_wowarmhw","_xtajit","advapi32","clbcatq","combase","COMDLG32","com12","DifxApi","gdi32","gdiplus","IMAGEHLP","IMM32","kernel32","MSCTF","MSVCRT","NORMALIZ","NSI","ole32","OLEAUT32","PSAPI","rpcrt4","sechost","Setupapi","SHCORE","SHELL32","SHLWAPI","user32","WLDAP32","wow64","wow64win","WS2_32";
                    Registry = "AppCertDlls","BootShell","BootExecute","NetworkList","AuthenticationPackage","HKLMRun","HKCURun","HKLMRunOnce","HKCURunOnce","Shell","Manufacturer","AppInitDlls","ShimCustom","UserInit","PowerShellv2"
                    
                    }
    if(!(Test-Path $whitelistpath)){
        mkdir $whitelistpath
    }
    if(!(Test-Path $anomaliesPath)){
        mkdir $anomaliesPath
    }
    foreach($dataType in $dataTypes.Keys){
        foreach($name in $sourceNames){
        
            $dataFile = "$($name)_$($dataType).csv"
            $dataPath = "$rawPath\$dataFile"
            $wlFile = "$($name)_$($dataType)_WL.csv"
            $wlPath = "$whitelistpath\$wlFile"
            if(!(Test-Path $wlPath)){
            New-Item -ItemType File -path $wlPath
            }
            if(Test-Path $dataPath){
        
                if(test-path $wlPath){
                    $anomalies = [System.Collections.ArrayList]@()
                    $data = import-csv $dataPath
                    $whitelist = [System.Collections.ArrayList]@()
                    $wlimportdata = import-csv $wlPath

                    foreach($i in $wlimportdata){
                        $whitelist.add($i.name) | Out-Null
                    }
                    $whitelist.sort()
            
                    #if(($data -ne $null) -and ($whitelist -ne $null)){
                    if(($data -ne $null)){
                       foreach($i in $data){
                            if($dataTypes[$dataType].Count -gt 1){

                                $stackString = [system.text.stringbuilder]::new()

                                for($j = 0; $j -lt $dataTypes[$dataType].Count; $j++){

                                    $stackString.Append("$($i.$($dataTypes[$dataType][$j]))") | Out-Null

                                    if($j -ne ($dataTypes[$dataType].Count -1)){

                                        $stackString.Append(", ") | Out-Null
                                    }
                                }

                                if(($i.$($dataTypes[$datatype]) -ne "") -and ($whitelist.BinarySearch($stackString.ToString()) -lt 0)){
                                    
                                    $anomalies.add($stackString.ToString()) | Out-Null

                                
                                }
                            }
                            elseif(($i.$($dataTypes[$datatype]) -ne "") -and ($whitelist.BinarySearch($i.$($dataTypes[$datatype])) -lt 0)){
                        
                                $anomalies.add($i.$($dataTypes[$datatype])) | out-null
                            }
                       }$anomalies.sort()
                       if($anomalies.Count -ne 0){
                            Write-Host -ForegroundColor Yellow "Non-Baseline $name $dataType Entries:"
                            Write-Host -ForegroundColor Yellow "================================"

                            $output = $anomalies | group | select count,name | sort count
                            $output | Format-Table -RepeatHeader -AutoSize
                            $output | export-csv -NoTypeInformation "$anomaliesPath\$($name)_$($dataType)_Anomalies.csv"
                            $anomname = "(A)" + "$($datafile)"
                            Rename-Item -Path $datapath -NewName $anomname
                            Write-Host "`n"

                       }else{
                            Write-Host -ForegroundColor Green "No Anomalous $name $dataType`n"
                            #mv $dataPath "$clearedPath\$dataFile"
                            $anomname = "(C)" + "$($datafile)"
                            Rename-Item -Path $datapath -NewName $anomname
                            Write-Host "`n"
                       }
               
                    }else{
                        write-host -ForegroundColor Red "Empty $dataFile or $wlFile !`n"
                    }
                }else{
                    write-host -ForegroundColor Red "$wlFile Not Found!`n"
                }
        
            }else{
                write-host -ForegroundColor Red "$dataFile Not Found!`n"
            }
        }
    }
}

function Audit-SMBConnections($smbfile){
    $smbconns = import-csv $smbfile
    foreach($i in $smbconns){
        $name = $i.username.split('\') | ?{$_ -ne "CHANGE"}
        $cred = $i.credential.split('\') | ?{($_ -ne "CHANGETOYOURDOMAIN") -and ($_ -ne "CHANGE")}
        if($name -ne $cred){
            write-host "Mismatch:" $name $cred
        }if($i.dialect -notlike "3.*"){
            write-host "Vulnerable SMB connection from:" $i.pscomputername "to:" $i.servername
        }
    }
}

function TempDirProcessExecution($processFile){

    $A=(import-csv $processFile).path
    #$A = (gwmi win32_process).path 
    $A | Select-String "Appdata","ProgramData","Temp","Users","public"|sort|unique;

}

function Clear-ZeroSizedBois ($folder){
    foreach($file in Get-ChildItem $folder){
        if($file.length -eq 0){
            $newName = "(Z)" + $file.name
            Rename-Item $file $newname
        }
    
    }

}

function Detect-PassTheHash($PTHfile){
    $a = import-csv $PTHfile
    foreach($i in $a){
        if(($i.username -ne "SYSTEM") -and ($i.username -ne "NETWORK SERVICE") -and !$i.client.contains($i.username)){
            write-host -ForegroundColor Yellow "PTH:" $i.username "`t" $i.client
        }
    }
}

function Hunt-Machine{
    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $PTHfile,
         [Parameter(Mandatory=$true, Position=1)]
         [string] $ComputerName,
         [Parameter(Mandatory=$true, Position=2)]
         [string] $field
    )
    $a = import-csv $PTHfile
    $a | ?{$_.PSComputername -eq $ComputerName } | group $field | select count,name | sort count
}

function Find-Artifact{
    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $PTHfile,
         [Parameter(Mandatory=$true, Position=1)]
         [string] $field,
         [Parameter(Mandatory=$true, Position=2)]
         [string] $term
    )
    $a = import-csv $PTHfile
    $a | ?{$_.$field -eq $term } | FL
}

function Detect-Prefetch($PTHfile){  
    $a = import-csv $PTHfile
    $i.name.split("-",2) | ?{$_ -like "*.EXE"} | group | select count,name | sort count
}

function Detect-NewService($PTHfile){
    $a = import-csv $PTHfile
    $a.message.split("`n") | ?{ $_ -like "*Service File Name: *"} | group | select count,name | sort count

}

function Un-Anomolize($folder){
    foreach($file in Get-ChildItem $folder){
        if($file.name -like "(A)*"){
            $newname = $file.Name.Split(')')[1]
            Rename-Item $file $newname
        }
    }
}