
if (-not (Get-Module InvokeBuild -ListAvailable)) {
    Install-Module InvokeBuild -Scope CurrentUser
}

$Module = Invoke-Build

Import-Module $Module.Path -Force -Verbose
