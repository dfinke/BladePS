. ..\BladePS.ps1

$template = '<name>{{Person.LastName}}, {{Person.FirstName}}</name>'
$context = @{person=@{firstname='Jane'; lastname='Doe'} }

Invoke-Template $context $template
