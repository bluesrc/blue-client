Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'

$clientRoot = Split-Path -Parent $PSScriptRoot
$outputDir = Join-Path $clientRoot 'data\images\ui'

function Convert-HexColor([string]$hex) {
    $value = $hex.TrimStart('#')
    return [System.Drawing.Color]::FromArgb(
        255,
        [Convert]::ToInt32($value.Substring(0, 2), 16),
        [Convert]::ToInt32($value.Substring(2, 2), 16),
        [Convert]::ToInt32($value.Substring(4, 2), 16)
    )
}

function New-RoundedPath([int]$x, [int]$y, [int]$width, [int]$height, [int]$radius) {
    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $diameter = $radius * 2
    $path.AddArc($x, $y, $diameter, $diameter, 180, 90)
    $path.AddArc($x + $width - $diameter, $y, $diameter, $diameter, 270, 90)
    $path.AddArc($x + $width - $diameter, $y + $height - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($x, $y + $height - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

function New-ButtonSheet([string]$name, [array]$states, [int]$radius = 4) {
    $bitmap = [System.Drawing.Bitmap]::new(22, 69, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half

    for ($index = 0; $index -lt 3; $index++) {
        $state = $states[$index]
        $top = $index * 23
        $path = New-RoundedPath 1 ($top + 1) 20 21 $radius
        $fill = [System.Drawing.SolidBrush]::new((Convert-HexColor $state.Fill))
        $border = [System.Drawing.Pen]::new((Convert-HexColor $state.Border), 1)
        $graphics.FillPath($fill, $path)
        $graphics.DrawPath($border, $path)

        $highlight = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(28, 255, 255, 255), 1)
        $graphics.DrawLine($highlight, 5, $top + 2, 16, $top + 2)

        $highlight.Dispose()
        $border.Dispose()
        $fill.Dispose()
        $path.Dispose()
    }

    $target = Join-Path $outputDir $name
    $bitmap.Save($target, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bitmap.Dispose()
}

function New-ComboBoxSheet([string]$name) {
    $bitmap = [System.Drawing.Bitmap]::new(91, 92, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half

    $states = @(
        @{ Fill = '#101010'; Border = '#444444'; Arrow = '#d8d8d8' },
        @{ Fill = '#171717'; Border = '#737373'; Arrow = '#ffffff' },
        @{ Fill = '#f4f4f4'; Border = '#ffffff'; Arrow = '#101010' },
        @{ Fill = '#101010'; Border = '#686868'; Arrow = '#d8d8d8' }
    )

    for ($index = 0; $index -lt 4; $index++) {
        $state = $states[$index]
        $top = $index * 23
        $path = New-RoundedPath 1 ($top + 1) 89 21 2
        $fill = [System.Drawing.SolidBrush]::new((Convert-HexColor $state.Fill))
        $border = [System.Drawing.Pen]::new((Convert-HexColor $state.Border), 1)
        $graphics.FillPath($fill, $path)
        $graphics.DrawPath($border, $path)

        if ($index -lt 3) {
            $separator = [System.Drawing.Pen]::new((Convert-HexColor $state.Border), 1)
            $graphics.DrawLine($separator, 72, $top + 2, 72, $top + 20)

            $arrow = [System.Drawing.SolidBrush]::new((Convert-HexColor $state.Arrow))
            $points = [System.Drawing.Point[]]@(
                [System.Drawing.Point]::new(78, $top + 9),
                [System.Drawing.Point]::new(85, $top + 9),
                [System.Drawing.Point]::new(81, $top + 14)
            )
            $graphics.FillPolygon($arrow, $points)

            $arrow.Dispose()
            $separator.Dispose()
        }
        $border.Dispose()
        $fill.Dispose()
        $path.Dispose()
    }

    $target = Join-Path $outputDir $name
    $bitmap.Save($target, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bitmap.Dispose()
}

function New-CheckBoxSheet([string]$name) {
    $bitmap = [System.Drawing.Bitmap]::new(15, 60, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half

    $states = @(
        @{ Fill = '#101010'; Border = '#5a5a5a'; Checked = $false },
        @{ Fill = '#101010'; Border = '#ffffff'; Checked = $false },
        @{ Fill = '#f4f4f4'; Border = '#ffffff'; Checked = $true },
        @{ Fill = '#ffffff'; Border = '#ffffff'; Checked = $true }
    )

    for ($index = 0; $index -lt 4; $index++) {
        $state = $states[$index]
        $top = $index * 15
        $path = New-RoundedPath 1 ($top + 1) 13 13 2
        $fill = [System.Drawing.SolidBrush]::new((Convert-HexColor $state.Fill))
        $border = [System.Drawing.Pen]::new((Convert-HexColor $state.Border), 1)
        $graphics.FillPath($fill, $path)
        $graphics.DrawPath($border, $path)

        if ($state.Checked) {
            $check = [System.Drawing.Pen]::new((Convert-HexColor '#101010'), 2)
            $check.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
            $check.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
            $graphics.DrawLine($check, 4, $top + 8, 6, $top + 10)
            $graphics.DrawLine($check, 6, $top + 10, 11, $top + 5)
            $check.Dispose()
        }

        $border.Dispose()
        $fill.Dispose()
        $path.Dispose()
    }

    $target = Join-Path $outputDir $name
    $bitmap.Save($target, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bitmap.Dispose()
}

function New-ScrollBarSheet([string]$name) {
    $bitmap = [System.Drawing.Bitmap]::new(39, 65, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

    $colors = @('#a8a8a8', '#ffffff', '#d2d2d2')
    $directions = @(
        @{ Row = 0; Direction = 'up' },
        @{ Row = 1; Direction = 'down' },
        @{ Row = 3; Direction = 'left' },
        @{ Row = 4; Direction = 'right' }
    )

    foreach ($entry in $directions) {
        for ($state = 0; $state -lt 3; $state++) {
            $left = $state * 13
            $top = $entry.Row * 13
            switch ($entry.Direction) {
                'up' {
                    $polygon = [System.Drawing.Point[]]@(
                        [System.Drawing.Point]::new(($left + 3), ($top + 8)),
                        [System.Drawing.Point]::new(($left + 6), ($top + 4)),
                        [System.Drawing.Point]::new(($left + 10), ($top + 8))
                    )
                }
                'down' {
                    $polygon = [System.Drawing.Point[]]@(
                        [System.Drawing.Point]::new(($left + 3), ($top + 5)),
                        [System.Drawing.Point]::new(($left + 10), ($top + 5)),
                        [System.Drawing.Point]::new(($left + 6), ($top + 9))
                    )
                }
                'left' {
                    $polygon = [System.Drawing.Point[]]@(
                        [System.Drawing.Point]::new(($left + 8), ($top + 3)),
                        [System.Drawing.Point]::new(($left + 4), ($top + 6)),
                        [System.Drawing.Point]::new(($left + 8), ($top + 10))
                    )
                }
                'right' {
                    $polygon = [System.Drawing.Point[]]@(
                        [System.Drawing.Point]::new(($left + 5), ($top + 3)),
                        [System.Drawing.Point]::new(($left + 9), ($top + 6)),
                        [System.Drawing.Point]::new(($left + 5), ($top + 10))
                    )
                }
            }
            $brush = [System.Drawing.SolidBrush]::new((Convert-HexColor $colors[$state]))
            $graphics.FillPolygon($brush, $polygon)
            $brush.Dispose()
        }
    }

    $target = Join-Path $outputDir $name
    $bitmap.Save($target, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bitmap.Dispose()
}

New-ButtonSheet 'theme_button_neutral.png' @(
    @{ Fill = '#151515'; Border = '#444444' },
    @{ Fill = '#292929'; Border = '#737373' },
    @{ Fill = '#0d0d0d'; Border = '#999999' }
)

New-ButtonSheet 'theme_tab_neutral.png' @(
    @{ Fill = '#151515'; Border = '#444444' },
    @{ Fill = '#292929'; Border = '#737373' },
    @{ Fill = '#f4f4f4'; Border = '#ffffff' }
)

New-ButtonSheet 'theme_button_success.png' @(
    @{ Fill = '#4d8f5b'; Border = '#75b683' },
    @{ Fill = '#62aa71'; Border = '#9bd1a7' },
    @{ Fill = '#376b42'; Border = '#b9dfc1' }
)

New-ButtonSheet 'theme_button_danger.png' @(
    @{ Fill = '#a84f4f'; Border = '#cf6868' },
    @{ Fill = '#c65d5d'; Border = '#ef8a8a' },
    @{ Fill = '#7f3b3b'; Border = '#f1b0b0' }
)

New-ButtonSheet 'theme_button_warning.png' @(
    @{ Fill = '#b78936'; Border = '#d6ac5b' },
    @{ Fill = '#d0a147'; Border = '#f0c977' },
    @{ Fill = '#876629'; Border = '#f1d9a5' }
)

New-ButtonSheet 'theme_input_neutral.png' @(
    @{ Fill = '#101010'; Border = '#444444' },
    @{ Fill = '#141414'; Border = '#737373' },
    @{ Fill = '#101010'; Border = '#ffffff' }
) 2

New-ComboBoxSheet 'theme_combobox_neutral.png'
New-CheckBoxSheet 'theme_checkbox.png'
New-ScrollBarSheet 'theme_scrollbar.png'
