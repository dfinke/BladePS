. ..\spike\try-dcf-parser.ps1

$t=@"
* {{name}}
* {{age}}
* {{company}}
* {{{company}}}
"@

$c=@"
{
  "name": "Chris",
  "company": "<b>GitHub</b>"
}
"@ | ConvertFrom-Json


Invoke-Template $c $t