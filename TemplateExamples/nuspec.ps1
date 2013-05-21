cls

. .\try-dcf-parser.ps1

$t=@"
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd">
  <metadata>
    <id>{{PackageName}}</id>
    <version>{{PackageVersion}}</version>
    <authors>{{PackageAuthors}}</authors>
    <description>{{PackageDescription}}</description>
    <language>en-US</language>
    <tags>{{PackageTags}}</tags>
    <dependencies>
    	<group>	{{#PackageDependencies}}            <dependency id="{{Id}}" version="{{Version}}" />{{/PackageDependencies}}        </group>
    </dependencies>    
  </metadata>
</package>
"@

$Context = @{
    PackageName="BladePS"
    PackageVersion="1.0.0.1"
    PackageAuthors="Author 1, Author 2, Author 3"
    PackageDescription="This is a cool package"
    PackageTags="Templates, PowerShell"
    PackageDependencies=@(
        @{id=1;version="1.0"}
        @{id=2;version="1.1"}
        @{id=3;version="1.2"}
    )
}

Invoke-Template $Context $t 