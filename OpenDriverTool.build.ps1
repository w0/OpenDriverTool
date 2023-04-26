
$RequiredModules = @{
    ModuleBuilder = 3.0
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
    remove Output
}

task Build {
    Build-Module
}

task . Build
