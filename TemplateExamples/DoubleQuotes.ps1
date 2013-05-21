. ..\spike\try-dcf-parser.ps1

$t = @"
<div class="entry">
  <h1>{{title}}</h1>
  <div class="body">
    {{body}}
  </div>
</div>
"@

$context = @"
{title: "My New Post", body: "This is my first post!"}
"@ | ConvertFrom-Json

Invoke-Template $context $t 
