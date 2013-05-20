cls

. .\try-dcf-parser.ps1

$Context = @{
    Person=@{
        FirstName = "Homer"
        LastName = "Simpson"
    }
}

$s=@"
<name>
$($Context.Person.LastName), $($Context.Person.FirstName)
babu
</name>
"@

#Invoke-ApplyTokens (Get-BladeTokens -Text $s) |iex
#return 

$s = @"
{{#stooges}}
* {{name}}
{{/stooges}}
"@

$context = @{
    stooges = @(
        @{name='Moe'}
        @{name='Larry'}
        @{name='Curly'}
    )
}

#(Get-BladeTokens -Text $s)
#Invoke-ApplyTokens (Get-MustacheTokens -Text $s) | iex #| iex

Invoke-Template $Context $s