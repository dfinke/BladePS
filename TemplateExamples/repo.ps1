cls
. ..\spike\try-dcf-parser.ps1 

$template = @"
{{#repo}}<b>{{name}}</b>{{/repo}}
"@

$context = @{
  "repo"= @(
    @{ "name"="resque" }
    @{ "name"="hub" }
    @{ "name"="rip" }
    @{ "name"="other" }
  )
}

Invoke-Template $context $template