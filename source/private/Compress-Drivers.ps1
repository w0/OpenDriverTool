function Compress-Drivers {
    param (
        [Parameter(Mandatory)]
        [io.directoryInfo]
        $ContentPath
    )

    $Child = Get-ChildItem $ContentPath

    Compress-Archive -Path $Child -DestinationPath $ContentPath\DriverPackage.zip -PassThru

}