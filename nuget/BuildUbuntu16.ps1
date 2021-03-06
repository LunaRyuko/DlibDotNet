Param()

$OperatingSystem="linux"
$Distribution="ubuntu"
$DistributionVersion="16"

# Store current directory
$Current = Get-Location
$DlibDotNetRoot = (Split-Path (Get-Location) -Parent)
$DlibDotNetSourceRoot = Join-Path $DlibDotNetRoot src
$DockerDir = Join-Path $Current docker

Set-Location -Path $DockerDir

$DockerFileDir = Join-Path $DockerDir build  | `
                 Join-Path -ChildPath $Distribution | `
                 Join-Path -ChildPath $DistributionVersion

$ArchitectureHash = @{32 = "x86"; 64 = "x64"}
$BuildSourceArray = @("DlibDotNet.Native", "DlibDotNet.Native.Dnn")
$BuildSourceHash = @{"DlibDotNet.Native" = "libDlibDotNetNative.so"; "DlibDotNet.Native.Dnn" = "libDlibDotNetNativeDnn.so"}

$BuildTargets = @()
$BuildTargets += New-Object PSObject -Property @{Target = "cpu";  Architecture = 64; CUDA = 0   }
$BuildTargets += New-Object PSObject -Property @{Target = "mkl";  Architecture = 64; CUDA = 0   }
#$BuildTargets += New-Object PSObject -Property @{Target = "cuda"; Architecture = 64; CUDA = 90  }
#$BuildTargets += New-Object PSObject -Property @{Target = "cuda"; Architecture = 64; CUDA = 91  }
$BuildTargets += New-Object PSObject -Property @{Target = "cuda"; Architecture = 64; CUDA = 92  }
$BuildTargets += New-Object PSObject -Property @{Target = "cuda"; Architecture = 64; CUDA = 100 }
$BuildTargets += New-Object PSObject -Property @{Target = "cuda"; Architecture = 64; CUDA = 101 }

foreach($BuildTarget in $BuildTargets)
{
  $target = $BuildTarget.Target
  $architecture = $BuildTarget.Architecture
  $cudaVersion = $BuildTarget.CUDA
  $options = New-Object 'System.Collections.Generic.List[string]'
  if ($target -ne "cuda")
  {
     $libraryDir = Join-Path "artifacts" $target
     $build = "build_" + $OperatingSystem + "_" + $target + "_" + $ArchitectureHash[$architecture]
     $dockername = "dlibdotnet/build/$Distribution/$DistributionVersion/$Target"
     $imagename  = "dlibdotnet/devel/$Distribution/$DistributionVersion/$Target"
  }
  else
  {
     $libraryDir = Join-Path "artifacts" ($target + "-" + $cudaVersion)
     $build = "build_" + $OperatingSystem + "_" + $target + "-" + $cudaVersion + "_" + $ArchitectureHash[$architecture]
     $options.Add($cudaVersion.ToString())
     $cudaVersion = ($cudaVersion / 10).ToString("0.0")
     $dockername = "dlibdotnet/build/$Distribution/$DistributionVersion/$Target/$cudaVersion"
     $imagename  = "dlibdotnet/devel/$Distribution/$DistributionVersion/$Target/$cudaVersion"
  }

  Write-Host "Start 'docker build'" -ForegroundColor Green
  docker build -q -t $dockername $DockerFileDir --build-arg IMAGE_NAME="$imagename"

  Write-Host "Start 'docker run'" -ForegroundColor Green
  docker run --rm `
             -v "$($DlibDotNetRoot):/opt/data/DlibDotNet" `
             -t "$dockername" $target $architecture ($options -join " ")

  # Copy output binary
  foreach($Source in $BuildSourceArray)
  {
    $dll = $BuildSourceHash[$Source]
    $srcDir = Join-Path $DlibDotNetSourceRoot $Source

    $binary = Join-Path $srcDir $build  | `
              Join-Path -ChildPath $dll
    $output = Join-Path $Current $libraryDir  | `
              Join-Path -ChildPath runtimes | `
              Join-Path -ChildPath ($OperatingSystem + "-" + $ArchitectureHash[$architecture]) | `
              Join-Path -ChildPath native | `
              Join-Path -ChildPath $dll

    Write-Host "Copy $dll to $output" -ForegroundColor Green
    Copy-Item $binary $output
  }
}

# Move to Root directory 
Set-Location -Path $Current