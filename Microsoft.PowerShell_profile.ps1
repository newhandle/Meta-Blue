﻿
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


                    }
    foreach($dataType in $dataTypes.Keys){
        foreach($name in $sourceNames){
        
            $dataFile = "$($name)_$($dataType).csv"
            $dataPath = "$rawPath\$dataFile"
            $wlFile = "$($name)_$($dataType)_WL.csv"
            $wlPath = "$whitelistpath\$wlFile"

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
                                if(($i.$($dataTypes[$datatype]) -ne "") -and ($whitelist.BinarySearch("$($i.$($dataTypes[$dataType][0])), $($i.$($dataTypes[$dataType][1]))") -lt 0)){
                                    
                                    $anomalies.add("$($i.$($dataTypes[$dataType][0])), $($i.$($dataTypes[$dataType][1]))") | Out-Null
                                
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

                            Write-Host "`n"

                       }else{
                            Write-Host -ForegroundColor Green "No Anomalous $name $dataType`n"
                            #mv $dataPath "$clearedPath\$dataFile"
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
        $name = $i.username.split('\') 
        $cred = $i.credential.split('\') 
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
