. .\BladePS.ps1

Describe "Testing Invoke-Template" {

    It "test simple context and template" {

        $template = '<name>{{Person.LastName}}, {{Person.FirstName}}</name>'
        $context = "{person: {firstname: 'John', lastname: 'Doe'} }" | ConvertFrom-Json

        $expected = '<name>Doe, John</name>'
        Invoke-Template $context $template | Should Be $expected
    }

    It "test template from file" {

        $context = "{person: {firstname: 'John', lastname: 'Doe'} }" | ConvertFrom-Json

        $expected = '<name>Doe, John</name>'
        Invoke-Template $context -Path .\Templates\PersonName.txt | Should Be $expected
    }

    It "tests nested arrays and using methods of objects" {

$Context = @"
{
    "name": "Alan", "hometown": "Somewhere, TX",
    "kids": [
        {"name": "Jimmy", "age": "12"},
        {"name": "Sally", "age": "4"}
    ]
}
"@ | ConvertFrom-Json

$template = @"
<p>Hello, my name is {{name}}. I am from {{hometown}}. I have
{{kids.count}} kids.</p>
"@
$expected = "<p>Hello, my name is Alan. I am from Somewhere, TX. I have
2 kids.</p>"

        Invoke-Template $Context $template | Should Be $expected
    }


    It "tests nested items and top level" {

$context = @"
{
  "name": {
    "first": "Michael",
    "last": "Jackson"
  },
  "age": "RIP"
}
"@ | ConvertFrom-Json

$template = @"
* {{name.first}} {{name.last}}
* {{age}}
"@
    $expected = @"
* Michael Jackson
* RIP
"@
        Invoke-Template $Context $Template | Should Be $expected
    }

    It "Should do a foreach" {
    $Context = @{
        stooges = @(
            @{ "name"= "Moe" },
            @{ "name"= "Larry" },
            @{ "name"= "Curly" }
        )
    }
    
        $Template = @"
{{#stooges}}
{{name}}
{{/stooges}}
"@
        $expected = "Moe Larry Curly"
        
        Invoke-Template $Context $Template | Should Be $expected
    }

    It "Test an array and the '.' current item in list" {
        $context = @"
{
  "musketeers": ["Athos", "Aramis", "Porthos", "D'Artagnan"]
}
"@ | ConvertFrom-Json

        $template = @"
{{#musketeers}}
{{.}}
{{/musketeers}}
"@
        Invoke-Template $context $template
    }
}