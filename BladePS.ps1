function Get-VariableName {
    param($text)

    $text -replace '{{', '' -replace '}}', ''
}

function Parse-Template ([string]$t){

    $StartLocation = $t.IndexOf('{{')    

    while($StartLocation -gt -1) {
        
        $EndLocation = $t.IndexOf('}}', $StartLocation) + 2
        $Length = $EndLocation-$StartLocation
        $Text = $t.Substring($StartLocation, $EndLocation-$StartLocation)
        
        Switch ($Text) {
            
            {$_.StartsWith('{{#')}{
                $TokenType="Start"
                $variable =  (Get-VariableName $text) -replace '#', '$Context.'
                $Transform = "`$(foreach(`$item in $variable) {"
                $InBlock = $true
            }

            {$_.StartsWith('{{/')}{
                $TokenType="End"
                $Transform = '})'
                $InBlock = $false
            }
            
            default {
                $TokenType="Variable"
                $variable =  Get-VariableName $text
                if($InBlock) {
                    if($variable -eq '.') {
                        $Transform = "`$(`$item)"
                    } else {
                        $Transform = "`$(`$item.$variable)"
                    }
                } else {
                    $Transform = "`$(`$Context.$variable)"
                }
            }
        }

        [PSCustomObject]@{
            StartLocation = $StartLocation
            EndLocation   = $EndLocation
            Length        = $Length
            Text          = $Text
            TokenType     = $TokenType
            Transform     = $Transform
        }

        $StartLocation = $t.IndexOf('{{', $StartLocation+1)
    }

}

function ConvertFrom-Template {
    param(        
        [String]$Template,
        [String]$Path,
        [Switch]$Encoded,
        [Switch]$OnlyTokens
    )

    if($Path) {
        $Path = Resolve-Path $Path
        Write-Debug $Path
        $Template = [IO.File]::ReadAllText($Path)
    }

    $tokens = Parse-Template $Template

    if($OnlyTokens) {
        return $tokens
    }

    foreach($token in $tokens) {
        $Template = $Template.Replace($token.Text, $token.TransForm)         
    }

    if($Encoded) {
        return "@`"`r`n$Template`r`n`"@"
    }

    $Template
}

function Invoke-Template {
    param(
        $Context,
        [String]$Template,
        [String]$Path
    )
     
    ConvertFrom-Template -Template $Template -Path $Path -Encoded | Invoke-Expression
}