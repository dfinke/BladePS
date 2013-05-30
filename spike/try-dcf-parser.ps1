function Get-BladeTokens {
    param(        
        [string]$Path,
        [string]$Text
    )

    if($Text.Length -eq 0) { return }

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

        if($TokenType -eq "LiteralText") {
            $Text = $Text -replace '"', '`$([char]34)'
        }

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
                            "!" {$TokenType="Comment"}
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
    $literalText = @()

    Switch ($tokens) {
    
        {$_.TokenType -eq 'LiteralText' } {
            if($containsSection -and $inSection) {
                $sectionText += @($_.text)
            } else {                
                $literalText += @($_.text)
            }
        } 

        {$_.TokenType -eq 'Token' } {
            if(($containsSection.Count -ge 1) -and $inSection) {
                            
                if($context.($_.Text) -is [ScriptBlock]) {
                    $sectionText += @('`$(& `$context.' + $_.Text + ' `$item)')
                } else {
                    $sectionText += @('`$(`$item.{0})' -f $_.text)
                }
                
            } else {
                $literalText += @('`$(`$context.{0})' -f $_.text)
            }
        }

        {$_.TokenType -eq 'StartSection' } {        
        
            if($literalText) {
                $outputString+= '"' + ($literalText -join '') + '"' + "`r`n"
                $literalText = @()
            }

            $inSection = $true

            # If the value of a section variable is a function
            $outputString+='foreach(`$item in `$Context.' + $_.text + ') {'
        }

        {$_.TokenType -eq 'EndSection' } {            
            
            if($literalText) {
                $outputString+= '"' + ($literalText -join '') + '"' + "`r`n"
                $literalText = @()
            }
            
            $inSection = $false
            $outputString += '"' + ($sectionText -join '') + '"'
            $outputString += '}'
            $sectionText =@()
        }
    }

    if($literalText) {
        $outputString+= '"' + ($literalText -join '') + '"' + "`r`n"
        $literalText = @()
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

    #if(!$Context -or $Context.KeysCount -eq 0) { return }


    $tokens = Get-BladeTokens -Text $Template
    if($AsTokens) {
        return $tokens
    }

    $result = Invoke-ApplyTokens $tokens
    
    if($AsResolved) {
        return $result.ResolvedTemplate
    }
    
    $result.ResolvedTemplate | Invoke-Expression | Invoke-Expression -ErrorAction SilentlyContinue
}