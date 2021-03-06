Param()

$baseDockerfiles = Get-ChildItem  -Recurse base -include Dockerfile

foreach($dockerfile in $baseDockerfiles)
{
   $relativePath = Resolve-Path $dockerfile -Relative
   $dockerfileDirectory = $relativePath.Replace('\Dockerfile', '')
   $basetag = "dlibdotnet" + $dockerfileDirectory.Trim('.').Replace('\', '/')

   Write-Host "Start docker build -t $tag $dockerfileDirectory" -ForegroundColor Green
   docker build -t $basetag $dockerfileDirectory

   # check operation system and version
   $path = $dockerfileDirectory.Split('\')
   $os = $path[2]
   $version = $path[3]

   $runtimeNameBase = $dockerfileDirectory
   $runtimeDockerfileDirectory = Join-Path 'runtime' $os  | `
                                 Join-Path -ChildPath $version -Resolve
   $runtimetag = "dlibdotnet" + (Resolve-Path $runtimeNameBase -Relative).Trim('.').Replace('\', '/').Replace('base', 'runtime')
   Write-Host "Start docker build -t $runtimetag runtime" -ForegroundColor Green
   docker build -t $runtimetag $runtimeDockerfileDirectory --build-arg IMAGE_NAME="$basetag"
}