Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# Paths
$brandingFolder = "C:\Branding"
$imageUrl = "https://1of1servers.com/opengraph/1of1servers_vps_server_wallpaper_2025.png"
$imagePath = "$brandingFolder\branding.png"
$tosFile = "$brandingFolder\ToS.txt"
$logFile = "$brandingFolder\AcceptanceLog.txt"

$appDataKeyFolder = "$env:APPDATA\1of1Servers"
$keyFile = "$appDataKeyFolder\key.txt"
$username = $env:USERNAME

# Ensure required folders exist
New-Item -ItemType Directory -Path $brandingFolder -Force | Out-Null
New-Item -ItemType Directory -Path $appDataKeyFolder -Force | Out-Null

# Download wallpaper if missing
if (-not (Test-Path $imagePath)) {
    Invoke-WebRequest -Uri $imageUrl -OutFile $imagePath -UseBasicParsing -ErrorAction SilentlyContinue
}

# Create ToS if missing
if (-not (Test-Path $tosFile)) {
@'

Welcome to 1of1Servers VPS.

     .=*######*=.
  .+*#*=*----*=*#*-
 *#*            .+#+
+#+         .=:   =#+
##.       :+##:   .##
*#=     :+####:   -#+
.*#+.   ...###.  =#+
  =##+:    ###++#*-
    .=-    ##**=.


'@ | Out-File $tosFile -Encoding UTF8
}

# Check key file and log
function Has-Accepted {
    if (!(Test-Path $keyFile)) { return $false }
    if (!(Test-Path $logFile)) { return $false }

    $storedKey = Get-Content $keyFile -Raw
    $logContent = Get-Content $logFile -ErrorAction SilentlyContinue
    return $logContent | Where-Object { $_ -like "$username|$storedKey" }
}

if (Has-Accepted) {
    return
}

# Show TOS Window
function Show-TOS {
    $tosWindow = New-Object System.Windows.Window
    $tosWindow.Title = "Terms of Service"
    $tosWindow.Width = 1600
    $tosWindow.Height = 800
    $tosWindow.WindowStartupLocation = "CenterScreen"
    $tosWindow.ResizeMode = "NoResize"
    $tosWindow.Background = 'Black'

    $tosText = Get-Content $tosFile -Raw
    $tosText += "`r`n`r`n"
    $tosText += "Do you accept the Terms of Service? [Y/N]: "

    $tosBox = New-Object System.Windows.Controls.TextBox
    $tosBox.Margin = "10"
    $tosBox.TextWrapping = "Wrap"
    $tosBox.VerticalScrollBarVisibility = "Auto"
    $tosBox.AcceptsReturn = $true
    $tosBox.AcceptsTab = $false
    $tosBox.Text = $tosText
    $tosBox.IsReadOnly = $false
    $tosBox.Background = 'Black'
    $tosBox.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
    $tosBox.FontSize = 24
    $tosBox.FontFamily = 'Consolas'
    $tosBox.CaretIndex = $tosBox.Text.Length
    $tosBox.SelectionStart = $tosBox.Text.Length
    $tosBox.Focusable = $true

    # Prevent editing above the prompt
    $promptStart = $tosBox.Text.Length

    $tosBox.Add_PreviewKeyDown({
        param($sender, $e)
        # Only allow input after the prompt
        if ($tosBox.CaretIndex -lt $promptStart) {
            $tosBox.CaretIndex = $tosBox.Text.Length
            $e.Handled = $true
            return
        }

        # State tracking
        if (-not $script:tosAccepted) { $script:tosAccepted = $false }
        if (-not $script:linksPrompt) { $script:linksPrompt = $false }

        if (-not $script:tosAccepted) {
            # First prompt: Accept ToS
            if ($e.Key -eq [System.Windows.Input.Key]::Y) {
                $e.Handled = $true
                $guid = [guid]::NewGuid().ToString()
                "$guid" | Out-File $keyFile -Encoding ASCII -Force
                "$username|$guid" | Out-File $logFile -Append -Encoding ASCII

                # Append links and next prompt to the ToS box
                $tosBox.AppendText("`r`n`r`nThank you for accepting the Terms of Service.`r`nVisit these resources:`r`n")
                $tosBox.AppendText("View ToS online --> https://www.1of1servers.com/tos`r`n")
                $tosBox.AppendText("Visit 1of1 Servers Docs --> https://docs.1of1servers.com/`r`n")
                $tosBox.AppendText("Visit 1of1 Servers Roadmap --> https://trello.com/b/ZsoaDlZR/1-of-1-servers-roadmap`r`n")
                $tosBox.AppendText("Visit 1of1 Servers Merch --> https://merch.1of1servers.com/`r`n")
                $tosBox.AppendText("Visit 1of1 Servers Status --> https://status.1of1servers.com/`r`n")
                $tosBox.AppendText("Visit 1of1 Servers YouTube --> https://youtube.com/channel/1of1servers`r`n")
                $tosBox.AppendText("`r`nAre you done reading? [Y/N]: ")
                $tosBox.CaretIndex = $tosBox.Text.Length
                $tosBox.ScrollToEnd()
                $script:tosAccepted = $true
                $script:promptStart2 = $tosBox.Text.Length
                return
            } elseif ($e.Key -eq [System.Windows.Input.Key]::N) {
                $e.Handled = $true
                $tosWindow.Close()
                [System.Windows.MessageBox]::Show(
                    "You must accept the Terms of Service to use this server. Shutting down...", 
                    "1of1Servers", "OK", "Error"
                )
                Stop-Computer -Force
            }
        } elseif ($script:tosAccepted -and -not $script:linksPrompt) {
            # Second prompt: Are you done reading?
            if ($tosBox.CaretIndex -lt $script:promptStart2) {
                $tosBox.CaretIndex = $tosBox.Text.Length
                $e.Handled = $true
                return
            }
            if ($e.Key -eq [System.Windows.Input.Key]::Y) {
                $e.Handled = $true
                $script:linksPrompt = $true
                # Now show the "create something awesome" popup (repeat until Yes)
                do {
                    $result = [System.Windows.MessageBox]::Show(
                        "Are you ready to create something awesome?!", 
                        "1of1Servers", 
                        [System.Windows.MessageBoxButton]::YesNo
                    )
                } while ($result -ne [System.Windows.MessageBoxResult]::Yes)

                [System.Windows.MessageBox]::Show(
                    "Thank you for accepting the terms of service, we're excited to have you here!",
                    "1of1Servers"
                )
                $tosWindow.Close()
            } elseif ($e.Key -eq [System.Windows.Input.Key]::N) {
                $e.Handled = $true
                $tosBox.AppendText("`r`nAre you done reading? [Y/N]: ")
                $tosBox.CaretIndex = $tosBox.Text.Length
                $tosBox.ScrollToEnd()
                $script:promptStart2 = $tosBox.Text.Length
                return
            }
        } elseif ($e.Key -eq [System.Windows.Input.Key]::Back) {
            # Prevent deleting the prompt
            if ($script:tosAccepted -and $tosBox.CaretIndex -le $script:promptStart2) {
                $e.Handled = $true
            } elseif (-not $script:tosAccepted -and $tosBox.CaretIndex -le $promptStart) {
                $e.Handled = $true
            }
        }
    })

    $tosWindow.Content = $tosBox
    $tosWindow.Add_SourceInitialized({
        $tosBox.Focus()
        $tosBox.CaretIndex = $tosBox.Text.Length
        $tosBox.SelectionStart = $tosBox.Text.Length
    })

    $tosWindow.ShowDialog() | Out-Null
}

# Show Branding Window
$window = New-Object System.Windows.Window
$window.Title = "Welcome to 1of1Servers VPS"
$window.Width = 1800
$window.Height = 1200
$window.WindowStartupLocation = "CenterScreen"
$window.ResizeMode = "NoResize"
$window.Background = 'Black'

$grid = New-Object System.Windows.Controls.Grid

$image = New-Object System.Windows.Controls.Image
$image.Margin = "10"
$image.Source = [System.Windows.Media.Imaging.BitmapImage]::new([Uri] $imagePath)
$image.Stretch = "Uniform"

$nextButton = New-Object System.Windows.Controls.Button
$nextButton.Content = "Next"
$nextButton.Width = 200
$nextButton.Height = 50
$nextButton.HorizontalAlignment = "Center"
$nextButton.Margin = "0,30,0,0"

$stackPanel = New-Object System.Windows.Controls.StackPanel
$stackPanel.VerticalAlignment = "Center"
$stackPanel.HorizontalAlignment = "Center"
$stackPanel.Children.Add($image)
$stackPanel.Children.Add($nextButton)

$grid.Children.Add($stackPanel)
$window.Content = $grid

$nextButton.Add_Click({
    $window.Close()
    Show-TOS
})

$window.ShowDialog() | Out-Null
