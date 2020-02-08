<#
##############################################################################################################################################
# SYNOPSIS:
# The below scripts builds solution and rull all test in parallel
# 
# COMPATIBILITY: PowerSumod 4.0 
# 
# DESCRIPTION:
# Accumulated the delta from current branch Head and Master. Retrieve the delta and build npm packages based on the changes in root aka fo/bo
# Below is the sequence of actions which takes place
# 1. Get Changes and Convert to Array
# 2. Matches with delta on a root level to identify fo/bo
# 3. Build NPM packages in background parallel
# 4. Build the Solution and Run All Test 
# 5. Roll the test in parallel and print out the result.
# 6. Print the result in Receive-JOB
#
# Entry Point: Main
.PARAM $msbuild = "'C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\msbuild.exe'",
.PARAM $nuget = "'C:\ProgramData\chocolatey\bin\nuget.exe'",
.PARAM $vstest = "'C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE\CommonExtensions\Microsoft\TestWindow\vstest.console.exe'",
.PARAM $slang_sol = "Sumod.LubeAnalyst.sln /nologo /nr:false /verbosity:minimal /
.PARAM $slang_sol_nuget_restore = "restore Sumod.LubeAnalyst.sln",
.PARAM $slang_test  = "src\test\Sumod.LubeAnalyst.Test\bin\Debug\net462\Sumod.LubeAnalyst.Test.dll",
.PARAM $targetMaster = 'origin/master',
.PARAM $fofilePath = 'D:\Sumod\Repo\LANextGen\src\web\Sumod.LubeAnalyst.Website',
.PARAM $bofilePath = 'D:\Sumod\Repo\LANextGen\src\web\Sumod.LubeAnalyst.BackOffice'
##############################################################################################################################################
#>
#Requires -Version 4.0
Param(
			[Parameter(Mandatory = $false)][string]$msbuild = "'C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\msbuild.exe'",
			[Parameter(Mandatory = $false)][string]$nuget = "'C:\ProgramData\chocolatey\bin\nuget.exe'",
			[Parameter(Mandatory = $false)][string]$vstest = "'C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE\CommonExtensions\Microsoft\TestWindow\vstest.console.exe'",
			[Parameter(Mandatory = $false)][string]$slang_sol = "Sumod.LubeAnalyst.sln /nologo /nr:false /verbosity:minimal /p:runcodeanalysis=true /p:CodeAnalysisTreatWarningsAsErrors=false /p:StyleCopTreatErrorsAsWarnings=false  /p:configuration=Debug /p:VisualStudioVersion=15.0 /p:GenerateProjectSpecificOutputFolder=true /p:PublishProfile=FolderProfile /m:8 /fileLogger",
			[Parameter(Mandatory = $false)][string]$slang_sol_nuget_restore = "restore Sumod.LubeAnalyst.sln",
			[Parameter(Mandatory = $false)][string]$slang_test = "src\test\Sumod.LubeAnalyst.Test\bin\Debug\net462\Sumod.LubeAnalyst.Test.dll",
			[Parameter(Mandatory = $false)][string]$targetMaster = 'origin/master',
			[Parameter(Mandatory = $true)][string]$fofilePath = 'D:\Sumod\Repo\LANextGen\src\web\Sumod.LubeAnalyst.Website',
			[Parameter(Mandatory = $true)][string]$bofilePath = 'D:\Sumod\Repo\LANextGen\src\web\Sumod.LubeAnalyst.BackOffice'
)
#
##---------------------Build----------------------------------------
$buildSource = $Env:BUILD_SOURCESDIRECTORY
$frontofilePath = $Env:BUILD_SOURCESDIRECTORY + "\" + $fofilePath
$backofilePath = $Env:BUILD_SOURCESDIRECTORY + "\" + $bofilePath	
##---------------------Build---------------------------------------- 
#
#---------------------Local-----------------------------------------
#$buildSource = 'D:\Sumod\Repo\LANextGen'
#$frontofilePath = $buildSource + "\" + $fofilePath
#$backofilePath = $buildSource + "\" + $bofilePath
##---------------------Local---------------------------------------- 
###########################NPM Configurations############################
############---Global Members----######################
$jobs = @()
$gitLogarray = @()
############---Global Members----######################
$npmInstall = {
Param($filePath)
Set-Location $filePath 
$stdOut = npm-cache install npm 2>($tmpFile=New-TemporaryFile)
$stderr = Get-Content $tmpFile; Remove-Item $tmpFile
$stderr = $stderr | Select-String -Pattern '(ERROR)|(Error:)' -CaseSensitive
if($stdErr.count -gt 0)
{
	Write-Host "OOPS! Something went wrong on NPM Install"
	Write-Host $stdErr
	throw "npm install failed with exit code 1"
}
else
	{
		$stdout = npm run pr-build --loglevel error 2>($tmpFile=New-TemporaryFile)
		$stderr = Get-Content $tmpFile; Remove-Item $tmpFile
		Write-Host $stderr
		$stderr = $stderr | Select-String -Pattern '(ERROR)|(Error:)' -CaseSensitive 
		if($stdErr.count -gt 0)
		{
			Write-Host "OOPS! Something went wrong on NPM RUN pr-build"
			Write-Host $stdErr
			throw "npm run pr-build failed with exit code 1"
		}
		else
		{
			Write-Host "NPM RUN pr-build - Succeeded"
		}
	}
}
###########################NPM Configurations############################
###########################/Test Suite Configurations############################
$runTestsuite = {
    Param($fullyQualifiedname, $rootPath, $slang_test, $vstest)
    Try {
        Set-Location $rootPath 
        Write-Host "Executing Tests...$fullyQualifiedname"
        $startTime = Get-Date
        $runTestexpression = "&$vstest $slang_test /TestCaseFilter:FullyQualifiedName~" + $fullyQualifiedname
        Write-Host $runTestexpression
        Invoke-Expression $runTestexpression
        if ($LASTEXITCODE -gt 0) {
            throw "Test failed with exit code 1"
        }
        $endTime = Get-Date
        Write-Host "Time taken for Run Test..." ($endTime - $startTime)
    }
    Catch {
        write-host "Caught an exception:" -ForegroundColor Red
        write-host "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
        write-host "Exception Message: $($_.Exception.Message)" -ForegroundColor Red
    }
    Finally {
        $fullyQualifiedname = $null
        $slang_test = $null
        $vstest = $null
    }
}
###########################Test Suite Configurations/############################
#
#####################################################################/Functions###############################################
function Get-Deltafromgit() {
    param([Parameter(Mandatory=$true)][string]$targetMaster)
    $startTime = Get-Date
    Write-Host 'git --no-pager diff --name-only HEAD $(git merge-base HEAD' $targetMaster')'
    $changes = git --no-pager diff --name-only HEAD $(git merge-base HEAD $targetMaster)
    $gitLogarray = @()
    $changes | foreach {
        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'FileName' -MemberType Noteproperty -Value $_
        $object | Add-Member -Name 'Extension' -MemberType Noteproperty -Value $_.Substring($_.LastIndexOf('.'))
        $gitLogarray += $object
    }
    $endTime = Get-Date
    Write-Host "Time taken for Get-Deltafromgit..." ($endTime - $startTime)
    return $gitLogarray
}
#
function Find-FileChangeServer() {
    param($filenamesList, [string]$fileExtension)
    $startTime = Get-Date
    $containsExtension = $false
    foreach ($fileName in $filenamesList)
    {
        if ($fileName.Extension -contains $fileExtension) {
            $containsExtension = $true
        }
    }
    $endTime = Get-Date
    Write-Host "Time taken for Find-FileChange..." ($endTime - $startTime)
    return $containsExtension
}
function Find-FileChangeClient(){
    param($newarray, [string[]]$extension)
	$startTime = Get-Date
    $containsExtension = $false
    $newarray | foreach { 
        if ($_.Extension -in $extension)
        {
           $containsExtension = $true
        }
      }
	$endTime = Get-Date
	Write-Host "Time taken for Find-FileChange..." ($endTime - $startTime)
    return $containsExtension
}
#
function Start-BuildSolution() {
    param([Parameter(Mandatory = $true)]$rootPath)
    Try {
        Set-Location $rootPath 
        Write-Host $rootPath
        Write-Host "Compiling Solution..."
        $startTime = Get-Date
        $nugetRestore = "&$nuget $slang_sol_nuget_restore"
        $msbuildExpression = "&$msbuild $slang_sol| Out-Host"
        Write-Host $nugetRestore
        Write-Host $msbuildExpression
        Invoke-Expression $nugetRestore
        Invoke-Expression $msbuildExpression
        $buildLogFilePath = "$rootPath\msbuild.log"
        Write-Host $buildLogFilePath
        [bool] $buildOutputDoesNotContainFailureMessage = (Select-String -Path $buildLogFilePath -Pattern "Build FAILED." -SimpleMatch) -eq $null
        $buildSucceeded = $buildOutputDoesNotContainFailureMessage 
        if(!$buildSucceeded)
        {
			Write-Error "Build Failed with exit code 1"
			throw "Build Failed with exit code 1"
        }
		#//Note:Code Analysis computation.
		Get-CodeAnalysisError $buildLogFilePath $rootPath
		$regExStyleCop = "SA\d{4}"
		$styleCopMatches = Select-String -Path $buildLogFilePath -Pattern $regExStyleCop -AllMatches -CaseSensitive
		if($styleCopMatches.Matches)
		{
			Write-Host $styleCopMatches.Matches
			$errorCount = $styleCopMatches.Matches.Count
			Write-Warning "Total number of StyleCop errors : $errorCount"
			Write-Error "Build Failed with exit code 1,Fix StyleCop errors."
		}
        if ($LASTEXITCODE -gt 0) {
            throw "Build Failed with exit code 1"
        }
        $endTime = Get-Date
        Write-Host "Time taken for Solution build..." ($endTime - $startTime)
        return $true
    }
    Catch {
        throw $Error[0].Exception
    }
    Finally {
        $msbuild = $null
        $nuget = $null
        $slang_sol = $null
        $slang_sol_nuget_restore = $null
    }
}
function Get-CodeAnalysisError(){
param([Parameter(Mandatory = $true)]$logPath,[Parameter(Mandatory = $true)]$rootPath)

		#Build the Lookup Table from RuleSet
		$rulesetLookupTable = @{}
		$ruleSet = "$rootPath\SumodRules.ruleset"
		$xPath = "//RuleSet/Rules/Rule[@Action='Error']"
		$filterXPath = Select-Xml -Path $ruleSet -XPath $xPath | Select-Object -ExpandProperty "Node"
		foreach ($rule in $filterXPath)
		{
			$rulesetLookupTable[$rule.Id] = $rule.Action
		}
		$uniqueCAforFix = @()
		$regExCA = "(CA|CS|C2)\d{4}"
		$caMatches = Select-String -Path $logPath -Pattern $regExCA -AllMatches -CaseSensitive
		if($caMatches.Matches)
		{
			$caMatchedCount = $caMatches.Matches.Count
			Write-Information "Total Number of Code Analysis Matches: $caMatchedCount"
			$uniqueRecords = $caMatches.Matches | Select-Object -Unique
			$uniqueRecordCount = $uniqueRecords.Length
			Write-Information "Total Number of Unique Records: $uniqueRecordCount"
			foreach ($eachError in $uniqueRecords)
			{
				$isError = $rulesetLookupTable[[string]$eachError]
				if($isError -eq "Error")
				{
					$uniqueCAforFix += [string]$eachError
					Write-Warning "CodeAnalysis-ERROR: Please fix $eachError"
				}
			}
		}
		$totalCount = $uniqueCAforFix.Length
		Write-Warning "Summation of code analysis error accross all projects as superset in numbers: $totalCount"
}
#
function Invoke-SequentialTests() {
    param([Parameter(Mandatory = $true)]$rootPath)
    Try {
        Set-Location $rootPath 
        Write-Host "Running Tests..."
        $startTime = Get-Date
        #$testExpression = "&$vstest $slang_test | Out-Host"
        $testExpression = "&$vstest $slang_test /EnableCodeCoverage /TestAdapterPath:'$rootPath' /UseVsixExtensions:true /logger:trx /Parallel| Out-Host"
        Write-Host $testExpression
        Invoke-Expression $testExpression
        $endTime = Get-Date
        Write-Host "Time taken for Execute Test..." ($endTime - $startTime)
        if ($LASTEXITCODE -gt 0) {
            throw "Test Failed with exit code 1"
        }
        else {
            return $true
        }
    }
    Catch {
        throw "Test Failed"
    }
}
#
function Initialize-TestItems() {
    param([Parameter(Mandatory = $true)]$gitLogarray)
    $startTime = Get-Date
    $itemstoTest = @("BaseTests", "CoreTests")
    foreach ($list in $gitLogarray) {   
        switch -regex ($list.FileName) { 
            "Sumod.LubeAnalyst.Api" {
                $itemstoTest += "FrontOffice"
            }
            "Sumod.LubeAnalyst.BackOffice.Api" {
                $itemstoTest += "BackOffice"
            }
        }
    }
    $endTime = Get-Date
    Write-Host "Time taken for Initialize-TestItems..." ($endTime - $startTime)
    return $itemstoTest
}
#
function Initialize-TestLookup() {
    param([Parameter(Mandatory = $true)]$slang_test, [Parameter(Mandatory = $true)]$vstest)
    $testLookup = @{}
    #Reflect the FQCN and filter only namespace
    $resultList = Invoke-Expression "&$vstest $slang_test /ListTests" | Where-Object {$_ -match "Sumod.LubeAnalyst.Test."} |  Get-Unique
    $foApi = @()
    $boApi = @()
    $baseTests = @()
    $coreTests = @()
    #hack to get rid of numbers in namespace
    $resultList = $resultList | Where-Object {$_ -notmatch "4.2"}#hack until I find a perfect regEx
    $resultCleanList = @()
    foreach ($fqName in $resultList) {
        #Build the Clean List
        $resultCleanList += Get-Fullyqualifiedclass $fqName
    }
    $resultList = $resultCleanList | Get-Unique
    Write-Host "Total number of Test Classes found :" $resultList.length -ForegroundColor DarkGreen -BackgroundColor White
    foreach ($fqName in $resultList) {
        #$fullyQualifiedname = Get-Fullyqualifiedclass $fqName
        #TODO : Find out optimal RegEx
        switch -regex ($fqName) {   
            "BackOffice" {  
                $boApi += $fqName.Trim()    
            }
            "FrontOffice" { 
                $foApi += $fqName.Trim()    
            }
            "BackOfficeAPI" {
                $boApi += $fqName.Trim() 
            }
            "FrontOfficeAPI" {
                $boApi += $fqName.Trim() 
            }
            "Core" {
                $coreTests += $fqName.Trim()
            }
            "Filters" { 
                $baseTests += $fqName.Trim() 
            }
            "Extensions" {
                $baseTests += $fqName.Trim() 
            }
            default {
                $baseTests += $fqName.Trim()
            }
        }
    }
    $testLookup["BaseTests"] = $baseTests| Get-Unique
    $testLookup["FrontOffice"] = $foApi| Get-Unique
    $testLookup["BackOffice"] = $boApi| Get-Unique
    $testLookup["CoreTests"] = $coreTests| Get-Unique
    return $testLookup
}
#
function Get-Fullyqualifiedclass() {
    param([Parameter(Mandatory = $true)][string]$fullyQualifiedname)
    $lastIndex = $fullyQualifiedname.LastIndexOf(".")
    $fullyQualifiedname = $fullyQualifiedname.Substring(0, $lastIndex)
    return $fullyQualifiedname
}
#
function Start-PushQueue() {
    param([Parameter(Mandatory = $true)]$itemstoTest, $rootPath)
    $startTime = Get-Date
    $testjobsQueue = @()
    $getmeLookup = Initialize-TestLookup $slang_test $vstest  
    $foApi = @()
    $boApi = @()
    $baseTests = @()
    $coreTests = @()
    foreach ($itemTest in $itemstoTest) {
        Switch ($itemTest) {
            "BaseTests" { 
                $baseTests += $getmeLookup[$itemTest]
            }
            "CoreTests" { 
                $coreTests += $getmeLookup[$itemTest]
            }
            "FrontOffice" {
                $foApi += $getmeLookup[$itemTest] 
            }
            "BackOffice" {
                $boApi += $getmeLookup[$itemTest] 
            }
        }
    }
    $mergeResult = $baseTests + $coreTests + $boApi + $foApi
    $prepareforTrigger = $mergeResult |Sort-Object -unique
    $testjobsQueue += Invoke-Paralleljobsfortests $prepareforTrigger $rootPath $slang_test $vstest 
    $endTime = Get-Date
    Write-Host "Time taken for Start-PushQueue..." ($endTime - $startTime)
    return $testjobsQueue
}
#
function Invoke-Paralleljobsfortests() {
    Param([Parameter(Mandatory = $true)]$fullyqualifiednameList,
        [Parameter(Mandatory = $true)][string]$rootPath,
        [Parameter(Mandatory = $true)][string]$slang_test,
        [Parameter(Mandatory = $true)][string]$vstest)
    Try {
        $testjobsQueue = @()
        foreach ($fqName in $fullyqualifiednameList) {
            Write-Host "Commencing Job for Test Class : "$fqName
            $testjobsQueue += start-job  -ScriptBlock $runTestsuite -ArgumentList $fqName.Trim(), $rootPath, $slang_test, $vstest
        }
    }   
    Catch {
        Write-Output $error[0]#blind spit out needs a detailed handler.
    }
    return $testjobsQueue
}
#
function Get-JobsintheQueueforclient() {
    param([Parameter(Mandatory = $true)]$testjobsQueue)
    $startTime = Get-Date
    $testjobsQueue | Format-Table -Auto
    Write-Host "Receiving Test Results..."
    Get-Job
    Wait-Job -Job $testjobsQueue | Out-Null
    Write-Host "------------------------------------------Job Processing Complete for Test Suite----------------------------------------------------"
    foreach ($job in $testjobsQueue) {
        if ($job.State -eq 'Failed') {
            Write-Host ($job.ChildJobs[0].JobStateInfo.Reason.Message) -ForegroundColor Red
            Write-Host "------------------------------------------Flush the exception----------------------------------------------------"
            Write-Host (Receive-Job $job -Keep -ErrorAction Stop) -ForegroundColor Red 
            Write-Host "------------------------------------------Flush the exception complete----------------------------------------------------"
            Remove-Job -State Failed
        }
        else {
            Write-Host (Receive-Job $job -Keep -ErrorAction Continue) -ForegroundColor Green 
            Write-Host "------------------------------------------Test Complete----------------------------------------------------"
        }
    }
    $endTime = Get-Date
    Write-Host "Time taken for Receive-Jobs in the Test Queue..." ($endTime - $startTime)
}
#
function Invoke-Paralleltests() {
    param([Parameter(Mandatory = $true)]$rootPath,
        [Parameter(Mandatory = $true)]$gitLogarray)
    Try {
        Set-Location $rootPath 
        Write-Host "Running Tests..."
        $startTime = Get-Date
        $itemstoTest = Initialize-TestItems $gitLogarray
        $testjobsQueue = Start-PushQueue $itemstoTest $rootPath
        if ($testjobsQueue) {
            Get-JobsintheQueueforclient $testjobsQueue
        }
        $endTime = Get-Date
        Write-Host "Time taken for Invoke-Tests..." ($endTime - $startTime)
    }
    Catch {
        throw
        return $false
    }
    return $true
}
#
function Initialize-StateFiles() {
    param([Parameter(Mandatory = $true)]$gitLogarray)
    $stateList = @()
	$TSFileChanged = Find-FileChangeClient $gitLogarray @(".ts",".html")
    $CSFileChanged = Find-FileChangeServer $gitLogarray '.cs'
    $SQLFileChanged = Find-FileChangeServer $gitLogarray '.sql'
    #################################################
	Write-Host "Typescript file changed : $TSFileChanged"
    Write-Host "CS file changed : $CSFileChanged"
    Write-Host "SQL file changed : $SQLFileChanged"
    ##################################################
	if ($TSFileChanged) {
        $stateList += "Typescript"  
    }
    if ($CSFileChanged) {
        $stateList += "CSharp"  
    }
    if ($SQLFileChanged) {
        if($CSFileChanged -eq $false)
        {
            $stateList += "Sql" 
        }
    }
    return $stateList
}
function Assign-JobQueue()
{
	param([Parameter(Mandatory=$true)]$sourcesClients)
	$startTime = Get-Date
	$jobsQueue = @()
	foreach($sourceClient in $sourcesClients)
	{
		Switch ($sourceClient)
		{
			"fo" {$jobsQueue += start-job -Name "FrontOffice" -ScriptBlock $npmInstall -ArgumentList $frontofilePath}
			"bo" {$jobsQueue += start-job -Name "BackOffice" -ScriptBlock $npmInstall -ArgumentList $backofilePath}
		}
	}
	$endTime = Get-Date
	Write-Host "Time taken for Assign-JobQueue..." ($endTime - $startTime)
	return $jobsQueue
}
function Receive-JobsintheQueue()
{
	param([Parameter(Mandatory=$true)]$jobsQueue)
	$startTime = Get-Date
	$jobsQueue | Format-Table -Auto
	Write-Host "Processing..."
	Wait-Job -Job $jobsQueue | Out-Null
	Write-Host "------------------------------------------Process Complete----------------------------------------------------"
	foreach ($job in $jobsQueue) 
	{
		if ($job.State -eq 'Failed') {
			Write-Error "Failed on : $job.Name"
            $errMessage = $job.ChildJobs[0].JobStateInfo.Reason.Message
            Write-Error $errMessage
			Write-Host "------------------------------------------Flush the exception----------------------------------------------------"
			Write-Host (Receive-Job $job -Keep -ErrorAction Stop) -ForegroundColor Green 
			Write-Host "------------------------------------------Flush the exception complete----------------------------------------------------"
			#Remove-Job -State Failed
            return $false
		} else {
			Write-Host (Receive-Job $job -Keep -ErrorAction Stop) -ForegroundColor Green 
			Write-Host "------------------------------------------Result out----------------------------------------------------"
		}
	}
	Get-Job
	$endTime = Get-Date
	Write-Host "Time taken for Receive-JobsintheQueue..." ($endTime - $startTime)
    return $true
}
function Build-ClientSide(){
	param([Parameter(Mandatory=$true)]$gitLogarray)
	$startTime = Get-Date
	$sourceArray = @()
	foreach($list in $gitLogarray)
	{
		if($list.FileName -Match "Sumod.LubeAnalyst.Website")
		{
			$sourceArray += "fo"
		}
		if($list.FileName -Match "Sumod.LubeAnalyst.BackOffice")
		{
			$sourceArray += "bo"
		}
	}
	$uniqueList = $sourceArray | Get-Unique
	$endTime = Get-Date
	Write-Host "Time taken for Build-ClientSide..." ($endTime - $startTime)
    return $uniqueList
}
#
function Initialize-BuildState() {
    param([Parameter(Mandatory = $true)]$stateList,
        [Parameter(Mandatory = $true)]$gitLogarray)
    $startTime = Get-Date
	$isClient = $false
    $buildState = $false
    Try {
        foreach ($currentState in $stateList) {
            Try {
                Switch ($currentState) {
					"Typescript" {
						$SourceList = Build-ClientSide $gitLogarray
						$jobs = Assign-JobQueue $SourceList
						$isClient = $true
                        Write-Host "Building the State for Typescript files"
                    }
                    "CSharp" {
                        $buildState = Start-BuildSolution $buildSource
                        if ($buildState -eq $true) {
                            #$buildState = Invoke-Paralleltests $buildSource $gitLogarray
                            $buildState = Invoke-SequentialTests $buildSource
                        }
                        Write-Host "Building the State for C# files"
                    }
                    "Sql" {
                        $buildState = Start-BuildSolution $buildSource
                        Write-Host "Building the State for SQL files"
                    }
                }
            }
            Catch {
                $ErrorMessage = $_.Exception.Message
                Write-Host "Error Message : $ErrorMessage"
                $buildState = $false
                break
            }
        }
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host "Error Message : $ErrorMessage"
        $buildState = $false
        break
    }
    Finally {
		if($isClient)
		{
            $buildState = Receive-JobsintheQueue $jobs
		}
        Write-Host "Building the state for $stateList is completed."
        $stateList = $null
        $gitLogarray = $null
    }
    $endTime = Get-Date
    Write-Host "Time taken for Initialize-BuildState ..." ($endTime - $startTime)
    return $buildState
}
#
function Cleanup() {
    Remove-Job -State Completed
    get-job
	$jobs = $null
	$gitLogarray = $null
	Write-Host "------------------------------------------Complete----------------------------------------------------"
}
#############/Main#####################
function Main() {
    $startTime = Get-Date
    Get-Date
    $gitLogarray = Get-Deltafromgit $targetMaster 
    $gitLogarray
    if($gitLogarray)
    {
        $stateResult = Initialize-StateFiles $gitLogarray
        if ($stateResult) {
        $finalResult = Initialize-BuildState $stateResult $gitLogarray
        if ($finalResult -eq $true) {
            Write-Host "All state is completed sucessfully" 
        }
        else {
            Write-Host "OOPS! Something went wrong." 
        }
    }
    else {
        Write-Host "No state to build. Give me something to build..." 
    }
    $endTime = Get-Date
    Write-Host "Time taken for Main..." ($endTime - $startTime)
    }
    else {
        Write-Host "No state to build. Give me something to build..." 
        }
}
#############Main End/#####################
#
#####################################################################Functions End/###############################################
#
#############################################/Console########################################################################
Write-Host "------------------------------------------Ready to Roll----------------------------------------------------"

Main
Cleanup
Get-Date
Write-Host "------------------------------------------I am done!---------------------------------------------------"
#############################################Console End/########################################################################
