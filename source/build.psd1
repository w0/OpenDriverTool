@{
    ModuleManifest  = "OpenDriverTool.psd1"
    # Subsequent relative paths are to the ModuleManifest
    OutputDirectory = "../"
    VersionedOutputDirectory = $true
    SourceDirectories = @(
        'public'
        'private'
        'classes'
        'enum'
    )
}