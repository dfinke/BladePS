. ..\BladePS.ps1

$template = '<name>{{Person.LastName}}, {{Person.FirstName}}</name>'
$context = [PSCustomObject]@{person=@{firstname='Tom'; lastname='Doe'} }

Invoke-Template $context $template
