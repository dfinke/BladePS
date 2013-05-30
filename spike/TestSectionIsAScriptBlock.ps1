cls

. .\try-dcf-parser.ps1

$context = @{
  "beatles"= @(
    @{ "firstName"="John";"lastName"="Lennon" }
    @{ "firstName"="Paul";"lastName"="McCartney" }
    [pscustomobject]@{ "firstName"="George";"lastName"="Harrison" }
    @{ "firstName"="Ringo";"lastName"="Starr" }
  )
  
  "name"= {param($target) "[$((Get-Date).ToString('d'))] {0}, {1}" -f $target.lastName, $target.firstName}
}

$t = @"
{{#beatles}}* {{name}}{{/beatles}}
"@

Invoke-Template $context $t
#return
#if($context.name -is [ScriptBlock]) {
#    foreach($item in $context.beatles) {
#        if($item -is [hashtable]) {
#            $item = [PSCustomObject]$item 
#        }
#                
#        & $context.name $item
#    }
#}
