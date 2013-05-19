. ..\BladePS.ps1

$t = @'
Hello {{name}},
You have just won `${{value}}!
'@

$c = @{
    name  = "John"
    value = 100
}

Invoke-Template $c $t