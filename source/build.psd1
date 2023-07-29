@{
    ModuleManifest  = "OpenDriverTool.psd1"
    # Subsequent relative paths are to the ModuleManifest
    OutputDirectory = "../dist"
    VersionedOutputDirectory = $true
    SourceDirectories = @( 'public', 'private', 'classes', 'enum' )
    CopyDirectories = @( '../en-US' )
}