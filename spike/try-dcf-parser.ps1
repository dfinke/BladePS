function Get-BladeTokens {
    param(        
        [string]$Path,
        [string]$Text
    )

    if($Path) { $sr = New-Object System.IO.StreamReader($Path) }
    if($Text) { $sr = New-Object System.IO.StringReader($Text) }
    
    function Get-NextChar {        
        $s = $sr.Read()        
        if($s -eq -1 -or $sr.EndOfStream) {
            return $null
        }
        [char]$s
    }
        
    $leftCurlyCount = 0
    $rightCurlyCount = 0
    $inBladeCount = 0
    [bool]$inBlade=$false
    $tokens = @()

    function New-Token {
        param($TokenType, $Text)
        [PSCustomObject]@{
            TokenType=$TokenType
            Text=$Text
        }
    }

    while($true) {        
        $s = Get-NextChar
        
        if($s -eq $null) {
            $tokens += New-Token LiteralText $LiteralText
            break
        }

        Switch ($s) {
        
            '{' {
                $leftCurlyCount  += 1
                if($leftCurlyCount -eq 2) {
                    $inBlade=$true
                    $inBladeCount = 0
                
                    if($LiteralText) {
                        $tokens += New-Token LiteralText $LiteralText
                    }
                    $LiteralText=""
                }
             }
        
            '}' { 
                $rightCurlyCount += 1

                if($rightCurlyCount -eq 2) {
                    $inBlade=$false
                    $leftCurlyCount = 0
                    $rightCurlyCount = 0
                    $inBladeCount = 0               
                
                    $tokens += new-token $TokenType $BladeToken.Trim()
                    $BladeToken=""
                }
             }
            default {
                if($inBlade) {
                    $currentChar = $_
                    $inBladeCount += 1

                    if($inBladeCount -eq 1) {
                        switch($currentChar) {
                            "#" {$TokenType="StartSection"}
                            "/" {$TokenType="EndSection"}
                            ">" {$TokenType="Include"}
                            default {
                                $TokenType="Token"
                                $BladeToken+=$_
                            }
                        }
                    } else {
                        switch($currentChar) {
                            default {
                                $BladeToken+=$_
                            }
                        }
                    }

                } else {
                    $LiteralText += $_
                }
            }
        }
    } 

    $sr.Dispose()

    $tokens
}

function Invoke-ApplyTokens {
    param($tokens)

    $containsSection = $tokens | Where {$_.tokentype -match 'section'}
    $outputString = $null    
    $inSection = $false
    
    Switch ($tokens) {
    
        {$_.TokenType -eq 'LiteralText' } {
            if($containsSection) {
                $sectionText += @($_.text)
            } else {
                $outputString+=$_.text
            }
        } 

        {$_.TokenType -eq 'Token' } {
            if($containsSection) {
                $sectionText += @('`$(`$item.{0})' -f $_.text)
            } else {
                $outputString+='$($context.{0})' -f $_.text
            }
        }

        {$_.TokenType -eq 'StartSection' } {
            $inSection = $true
            $outputString+='foreach(`$item in `$Context.' + $_.text + ') {'
        }

        {$_.TokenType -eq 'EndSection' } {            
            $inSection = $false
            $outputString += '"' + ($sectionText -join '') + '"'
            $outputString += '}'
            $sectionText =@()
        }
    }
        
    [PSCustomObject]@{
        ResolvedTemplate = "@`"`r`n$outputString`r`n`"@"
        ContainsSection = $containsSection.Count -ge 1
    }
}

function Invoke-Template {
    param(
        $Context,
        $Template,
        [Switch]$AsResolved,
        [Switch]$AsTokens
    )

    $tokens = Get-BladeTokens -Text $Template
    if($AsTokens) {
        return $tokens
    }

    $result = Invoke-ApplyTokens $tokens
    
    if($AsResolved) {
        return $result.ResolvedTemplate
    }

    if($result.ContainsSection) {
        $result.ResolvedTemplate | Invoke-Expression | Invoke-Expression
    } else {
        $result.ResolvedTemplate | Invoke-Expression 
    }
}