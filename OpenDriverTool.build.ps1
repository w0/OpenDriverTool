
$RequiredModules = @{
    ModuleBuilder = 3.0
    platyPS = 0.14.2
}

task CheckModules -Before Build {
    $RequiredModules.GetEnumerator() | %{
        if (-not (Get-Module $_.Key)) {
            Write-Host "    Installing Module: $($_.Key)"
            Install-Module $_.Key -Scope CurrentUser
        }

        if (Get-Module $_.Key -ListAvailable) {
            Write-Host "    Importing Module: $($_.Key)"
        }
    }
}

task Clean -Before Build {
    remove dist
    remove en-US
}

task BuildHelp -Before Build {
    New-ExternalHelp .\docs -OutputPath en-US\
}

task Build {
    Build-Module .\source -Passthru
}

task Publish {
    $PublishModule = @{
        Path = "$BuildRoot\dist\OpenDriverTool"
        NuGetApiKey = $env:NUGET_API_KEY
    }
    Publish-Module @PublishModule
}

task . Build
