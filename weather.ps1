function Show-MessageBox{
  [CmdletBinding(PositionalBinding=$false)]
  param(
    [Parameter(Mandatory, Position=0)]
    [string] $Message,
    [Parameter(Position=1)]
    [string] $Title,
    [Parameter(Position=2)]
    [ValidateSet('OK', 'OKCancel', 'AbortRetryIgnore', 'YesNoCancel', 'YesNo', 'RetryCancel')]
    [string] $Buttons = 'OK',
    [ValidateSet('Information', 'Warning', 'Stop')]
    [string] $Icon = 'Information',
    [ValidateSet(0, 1, 2)]
    [int] $DefaultButtonIndex
  )
  Set-StrictMode -Off
  $buttonMap = @{ 
    'OK'               = @{ buttonList = 'OK'; defaultButtonIndex = 0 }
    'OKCancel'         = @{ buttonList = 'OK', 'Cancel'; defaultButtonIndex = 0; cancelButtonIndex = 1 }
    'AbortRetryIgnore' = @{ buttonList = 'Abort', 'Retry', 'Ignore'; defaultButtonIndex = 2; ; cancelButtonIndex = 0 }; 
    'YesNoCancel'      = @{ buttonList = 'Yes', 'No', 'Cancel'; defaultButtonIndex = 2; cancelButtonIndex = 2 };
    'YesNo'            = @{ buttonList = 'Yes', 'No'; defaultButtonIndex = 0; cancelButtonIndex = 1 }
    'RetryCancel'      = @{ buttonList = 'Retry', 'Cancel'; defaultButtonIndex = 0; cancelButtonIndex = 1 }
  }
  $numButtons = $buttonMap[$Buttons].buttonList.Count
  $defaultIndex = [math]::Min($numButtons - 1, ($buttonMap[$Buttons].defaultButtonIndex, $DefaultButtonIndex)[$PSBoundParameters.ContainsKey('DefaultButtonIndex')])
  $cancelIndex = $buttonMap[$Buttons].cancelButtonIndex
  if ($IsLinux) { 
    Throw "Not supported on Linux." 
  }
  elseif ($IsMacOS) {
    $iconClause = if ($Icon -ne 'Information') { 'as ' + $Icon -replace 'Stop', 'critical' }
    $buttonClause = "buttons { $($buttonMap[$Buttons].buttonList -replace '^', '"' -replace '$', '"' -join ',') }"
    $defaultButtonClause = 'default button ' + (1 + $defaultIndex)
    if ($null -ne $cancelIndex -and $cancelIndex -ne $defaultIndex) {
      $cancelButtonClause = 'cancel button ' + (1 + $cancelIndex)
    }
    $appleScript = "display alert `"$Title`" message `"$Message`" $iconClause $buttonClause $defaultButtonClause $cancelButtonClause"            #"
    Write-Verbose "AppleScript command: $appleScript"
    $result = $appleScript | osascript 2>$null
    if (-not $result) { $buttonMap[$Buttons].buttonList[$buttonMap[$Buttons].cancelButtonIndex] } else { $result -replace '.+:' }
  }
  else { # Windows
    Add-Type -Assembly System.Windows.Forms        
    [System.Windows.Forms.MessageBox]::Show($Message, $Title, $Buttons, $Icon, $defaultIndex * 256).ToString()
  }
}

$metarFull = Invoke-WebRequest -uri "https://tgftp.nws.noaa.gov/data/observations/metar/decoded/KBFI.TXT"
#idk why this wont run outside a conditional...
if (2 -eq 2){
    $buttonChosen = Show-MessageBox "$metarFull" 'KBFI' -Buttons OK -Icon Information
    BREAK
}
