. ..\BladePS.ps1

$template = '<name>{{Person.LastName}}, {{Person.FirstName}}</name>'
$context = "{person: {firstname: 'John', lastname: 'Doe'} }" | ConvertFrom-Json

Invoke-Template $context $template
