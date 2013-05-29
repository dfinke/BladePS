cls

. .\try-dcf-parser.ps1

$context = @{
  "beatles"= @(
    @{ "firstName"="John";"lastName"="Lennon" }
    @{ "firstName"="Paul";"lastName"="McCartney" }
    [pscustomobject]@{ "firstName"="George";"lastName"="Harrison" }
    @{ "firstName"="Ringo";"lastName"="Starr" }
  )
  
  "name"= {$this.lastName + ", " + $this.firstName}
}



$t = @"
{{#beatles}}
* {{name}}
{{/beatles}}
"@

#Invoke-Template $context $t

if($context.name -is [ScriptBlock]) {
    foreach($item in $context.beatles) { 
        if($item -is [hashtable]) {
            $item = [PSCustomObject]$item 
        } 

        ($item | Add-Member -MemberType ScriptProperty -PassThru -Name Result -Value $context.name).Result
    }
}