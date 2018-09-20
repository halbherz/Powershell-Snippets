PARAM(
    [Parameter(Mandatory=$true)]
    [string] $TfsUri,
    [Parameter(Mandatory=$true)]
    [string] $Collection,
    [Parameter(Mandatory=$true, HelpMessage="List of projects seperated by ','.")]
    [string] $Projects,
    [Parameter(Mandatory=$true)]
    [string] $TfsUsername,
    # Unfortunatelly the password needs to be plain text for the basic authentification against TFS
    [Parameter(Mandatory=$true)]
    [string] $TfsPassword
)

$Projects.Split(",") | ForEach-Object {
    $prefix = $_ -replace "%20", "."

    # Base uri to get a list of repositories from TFS
    $baseUri = "{0}/{1}/{2}/_apis/git/repositories" -f $TfsUri, $Collection, $_

    # Create the auth header
    $TfsUsernameAndPassword = "{0}:{1}" -f $TfsUsername, $TfsPassword
    $Utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($TfsUsernameAndPassword)
    $base64AuthInfo = [Convert]::ToBase64String($Utf8Bytes)

    $response = Invoke-RestMethod -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Uri $baseUri

    # set the git config to use the integrated user authentification
    $gitConfig = "credential.{0}/.integrated" -f $TfsUri
    git config --global $gitConfig true

    # Iterate over all found repositories and bundle them into one folder
    # TODO: Handle errors so that your location is not set back. Might be possible to work with push.
    Foreach ($repository in $response.value) {
        $remoteUrl = $repository.remoteUrl -replace " ", "%20"
        $bundleName = $prefix + "_" + $repository.name + ".bundle"

        git clone $remoteUrl $repository.name | Out-Null
        # Realy not sure about the Set-Location command.
        # Seems to be a bit dirty.
        Set-Location $("./" + $repository.name)
        git bundle create $bundleName --all | Out-Null

        Move-Item $bundleName "..\Bundles"

        Set-Location "./.."
    }
}