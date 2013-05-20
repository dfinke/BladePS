. ..\spike\try-dcf-parser.ps1 

$t = @"
 {{#names}}
  Hi {{name}}!
{{/names}}
"@

$c = "{names: [ {'name': 'chris'}, {'name': 'mark'}, {'name': 'scott'} ] }" | ConvertFrom-Json

Invoke-Template $c $t