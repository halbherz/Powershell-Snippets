Param(
    [Parameter(Mandatory=$True)]
    [string]$source,
    [Parameter(Mandatory=$True)]
    [string]$target,
    [Parameter(Mandatory=$True)]
    [string]$pattern
)

$source_regex = [regex]::escape($source)
(Get-ChildItem $source -recurse | Where-Object {-not ($_.psiscontainer)} | Select-Object -expand fullname)  -match $pattern | ForEach-Object {
        $file_dest = ($_ | split-path -parent) -replace $source_regex, $target

        if (-not (test-path $file_dest)) {
            mkdir $file_dest
        }
        
        copy-item $_ -Destination $file_dest
    }