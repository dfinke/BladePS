. ..\spike\try-dcf-parser.ps1 

$t = @"
<h1>{{header}}</h1>
{{#items}}* {{name}}{{/items}}
"@

$c = @"
{
  "header": "Colors",
  "items": [
      {"name": "red", "first": true, "url": "#Red"},
      {"name": "green", "link": true, "url": "#Green"},
      {"name": "blue", "link": true, "url": "#Blue"}
  ],
  "empty": false
}
"@ | ConvertFrom-Json

Invoke-Template $c $t 