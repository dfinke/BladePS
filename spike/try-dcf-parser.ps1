function Get-MustacheTokens {
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
    $inMustacheCount = 0
    [bool]$inMustache=$false
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
                    $inMustache=$true
                    $inMustacheCount = 0
                
                    if($LiteralText) {
                        $tokens += New-Token LiteralText $LiteralText
                    }
                    $LiteralText=""
                }
             }
        
            '}' { 
                $rightCurlyCount += 1

                if($rightCurlyCount -eq 2) {
                    $inMustache=$false
                    $leftCurlyCount = 0
                    $rightCurlyCount = 0
                    $inMustacheCount = 0               
                
                    $tokens += new-token $TokenType $MustacheToken.Trim()
                    $MustacheToken=""
                }
             }
            default {
                if($inMustache) {
                    $currentChar = $_
                    $inMustacheCount += 1

                    if($inMustacheCount -eq 1) {
                        switch($currentChar) {
                            "#" {$TokenType="StartSection"}
                            "/" {$TokenType="EndSection"}
                            ">" {$TokenType="Include"}
                            default {
                                $TokenType="Token"
                                $MustacheToken+=$_
                            }
                        }
                    } else {
                        switch($currentChar) {
                            default {
                                $MustacheToken+=$_
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
            $outputString+='foreach(`$item in `$Context.stooges) {'
        }

        {$_.TokenType -eq 'EndSection' } {            
            $outputString += '"' + ($sectionText -join '') + '"'
            $outputString += '}'
            $sectionText =@()
        }
    }
        
    "@`"`r`n$outputString`r`n`"@"
}