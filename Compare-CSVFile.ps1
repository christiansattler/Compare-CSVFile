
#$VerbosePreference="Continue";

function Compare-CSVFile {
    <#
        .SYNOPSIS
            EN: Comparison of two CSV files line by line.
            DE: Vergleich zweier CSV Dateien zeilenweise.  
        
        .DESCRIPTION
		    EN: Comparison of two CSV files line by line. Each line is identified by one or more columns which are unique for the line in the file. For more info about functionalities see parameter help.
            DE: Vergleich von zwei CSV Dateien - zeilenweise. Jede Zeile wird durch eine oder mehrere Spalten eindeutig in der Datei identifiziert. Für mehr Info über Funktionalitäten in der Parameter Hilfe nachsehen.

        .PARAMETER ReferenceFile
            EN: File used as a reference for comparison (filename, absolute path or relative to current directory).
            DE: Datei verwendet als Referenz für den Vergleich (Dateiname, absoluter Pfad oder relativ zu aktuellem Verzeichnis)

        .PARAMETER DifferenceFile
            EN: File that is compared to the reference file (filename, absolute path or relative to current directory). 
            DE: Datei die mit der Referenzdatei verglichen werden soll (Dateiname, absoluter Pfad oder relativ zu aktuellem Verzeichnis)	

	    .PARAMETER Identifier
		    EN: Optional. One or more columns (separated by comma when more than one) that acts as a unique identifier for a line. 
                This is in order to compare lines with the same identifier across the both files. When missing this parameter the first column is taken as unique identifier.
            DE: Optional. Eine oder mehrere Spalten (getrennt mit Komma wenn es mehrere sind) die als eindeutiger Kenner für eine Zeile wirken.
                Dies dient dazu Zeilen des gleichen Kenner in den beiden Dateien zu vergleichen. Beim Fehlen dieses Parameter wird die erste Spalte als eindeutiger Kenner verwendet. 

        .PARAMETER Delimiter
            EN: Optional. Separator used by the files between columns. When missing this parameter the semicolon (;) is used as default value.
            DE: Optional. Trennzeichen genutzt in den Dateien zwischen den Spalten. Beim Fehlen dieses Parameter wird das Semikolon (;) als Standardwert genommen.

        .PARAMETER Header
            EN: Optional. List of column names. When missing this parameter the content of the first line is taken. 
                Additional functionality: set this parameter to 'numbers' for numbering the columns to 1..n
            DE: Optional. Liste von Spalten-Namen für die Spalten. Beim Fehlen dieses Parameter wird der Inhalt der ersten Zeile als Spalten-Namen verwendet. 
                Zusätzliche Funktionalität: auf 'numbers' gesetzt werden die Spalten durchnummeriert auf 1..n

        .PARAMETER ignoreColum
            EN: Optional. One or more columns (separated by comma when more than one) that are ignored by the comparison - all other columns are compared. 
                This parameter is used when there are columns having differences that are not of interest by the comparison. 
                Columns that are part of the parameter Identifier (or the content of parameter Identifier) can not be ignored. 
            DE: Optional. Ein oder mehrere Spalten (getrennt mit Komma wenn es mehrere sind) die im Vergleich ignoriert werden - alle anderen Spalten werden verglichen.
                Dieser Parameter wird verwendet wenn es Spalten mit Unterschieden gibt die für den Vergleich nicht von Interesse sind.
                Spalten im Parameter Identifier (bzw. der Inhalt des Parameter Identifier ) können nicht ignoriert werden.

        .PARAMETER Focus
            EN: Optional. Possible values: 'all', 'clearEquals', 'clearDiffs', 'clearEqualsOnReference'. Explanation: 'all' (show all cells), 'clearEquals' (clear cells that are equal in reference and difference), 
                'clearDiffs' (clear cells that are different in reference and difference), 'clearEqualsOnReference' (clear cells in reference that are equal in reference and difference)
            DE: Optional. Mögliche Werte: 'all', 'clearEquals', 'clearDiffs', 'clearEqualsOnReference'. Erläuterung: 'all' (zeige alle Zellen), 'clearEquals' (leeren der Zellen die gleich in Referenz und Difference), 
                'clearDiffs' (leeren der Zellen die unterschiedlich in Referenz und Difference sind), 'clearEqualsOnReference' (leeren der Zellen in Referenz die gleich in Referenz und Difference sind)

        .PARAMETER Output
            EN: Optional. Possible values: 'all', 'stat', 'diff'. Explanation: 'all' (get statistics and differences), 'stat' (get statistics), 'diff' (get differences)
            DE: Optional. Mögliche Werte: 'all', 'stat', 'diff'. Erläuterung: 'all' (liefert Statistiken und Unterschiede), 'stat' (liefert Statistiken), 'diff' (liefert Unterschiede)

		
        .EXAMPLE  
            See Compare-CSVFile.Tests.ps1 for examples.

    #>
    [CmdletBinding()] 
    param(
        # Parameter ReferenceFile
        [Parameter(Mandatory=$True)] 
        [ValidateScript({
            if(-Not ($_ | Test-Path) ){
                throw "File or folder does not exist"
            }
            if(-Not ($_ | Test-Path -PathType Leaf) ){
                throw "The Path argument must be a file. Folder paths are not allowed."
            }
            return $true 
        })]
        [System.IO.FileInfo]$ReferenceFile,
        # Parameter DifferenceFile
        [Parameter(Mandatory=$True)] 
        [ValidateScript({
            if(-Not ($_ | Test-Path) ){
                throw "File or folder does not exist"
            }
            if(-Not ($_ | Test-Path -PathType Leaf) ){
                throw "The Path argument must be a file. Folder paths are not allowed."
            }
            return $true 
        })]
        [System.IO.FileInfo]$DifferenceFile,
        # Parameter Identifier
            [String[]]  $Identifier=$null,
        # Parameter Delimiter
            [Char]      $Delimiter=";",
        # Parameter Header
                        $Header=$null,
        # Parameter ignoreColum
            [String[]]  $ignoreColumn,
        # Parameter Focus
        [ValidateSet('all', 'clearEquals', 'clearDiffs', 'clearEqualsOnReference')]
            [String]    $Focus='all',
        # Parameter Output
        [ValidateSet('all', 'diff', 'stat')]  #  
            [String]    $Output='diff'    
    )

    # Init 
    $Started = (Get-Date)
    
    # Statistics
    $Stats = [Ordered]@{ 
        "ReferenceFile"=""; 
        "ReferenceFileNumLines"=0; 
        "DifferenceFile"=""; 
        "DifferenceFileNumFiles"=0; 
        "Diffs"=0; 
        "Insert"=0; 
        "Update"=0; 
        "Delete"=0; 
        "ParameterIdentifier"=$Identifier; 
        "ParameterignoreColumn"="" 
    };

    # Import CSV file 
    $ImportCSV = 
    {
        param(
            [String] $File,
            [String] $Delimiter,
                     $Header
        )
        
        # Parameter Header -eq numbers 
        if ($Header -eq 'numbers') {
            Write-Verbose "File $File is using parameter Header: numbers" 
            $fileData = (Get-Content $File | Out-String) 
            $numberOfColumns = ((($fileData -replace "(`"[^;]+?)`r`n",'$1') -split "`r`n" | Select -First 1).split($Delimiter)).Count
            $CSV = Import-Csv $File -Header (1..( "$numberOfColumns" )) -Delimiter $Delimiter | Select -Skip 1
        }
        # Parameter Header 
        elseif ($Header) {
            Write-Verbose "File $File is using parameter Header: $Header"
            $CSV = Import-Csv $File -Delimiter $Delimiter -Header $Header
        }
        # First line as header
        else {
            Write-Verbose "File $File is using first line as header"
            $CSV = Import-Csv $File -Delimiter $Delimiter
        }

        return $CSV;
    }

    Write-Verbose "Import Files. Elapsed $((Get-Date)-$Started)" 

    # Import ReferenceFile
    $ReferenceObject = & $ImportCSV -File $ReferenceFile -Header $Header -Delimiter $Delimiter
    $Stats["ReferenceFileNumLines"] = $ReferenceObject.Count;

    # Extract columns 
    $RefCols = $ReferenceObject | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name 
    $RefNotIdentifierCols = $RefCols | Where { $Identifier -notcontains $_ }

    # Import DifferenceFile
    $DifferenceObject = & $importCSV -File $DifferenceFile -Header $Header -Delimiter $Delimiter
    $Stats["DifferenceFileNumLines"] = $DifferenceObject.Count;
    
    # Parameter Identifier
    if (-not $Identifier) {
        $Identifier = $RefCols[0];
        Write-Verbose "Parameter Identifier is Undefined. Taking first column as Identifier: $Identifier"
    }
    elseif ($Identifier -isnot [array]) {
        $Identifier = @($Identifier)
    }

    # Validate Identifier to be existing columns
    if (-not @($Identifier | Where { $RefCols -notcontains $_ }).Count) {
        Write-Verbose "Identifier $Identifier is valid"
    }
    else {
        Write-Verbose "Identifier $Identifier is invalid or contains an unknown column"
    }

    # Ignore Columns
    if ($ignoreColumn) {
        # Ignore columns in parameter Identifier to be ignored
        $ignoreColumn = $ignoreColumn | Where { -not $Identifier.contains($_) }

        # Ignore columns to be ignored        
        $RefCols = $RefCols | Where { -not $ignoreColumn.contains($_) }
        
        Write-Verbose "Columns ignored: $ignoreColumn"
        Write-Verbose "Columns compared: $RefCols"
    }

    # Compare
    Write-Verbose "Compare-Object. Elapsed $( (Get-Date)-$Started )"
    $Diffs = Compare-Object $ReferenceObject $DifferenceObject -Property $RefCols -PassThru | Group $Identifier   
    
    # Focus
    Write-Verbose "Focus. Elapsed $( (Get-Date)-$Started )"
    
    # Save time when not needed
    if ($Output -eq 'all' -or $Output -eq 'diff') {
        
        # The switch to save time by avoiding to much questions while looping
        switch ($Focus) {
            # Show all cells, do not clear any cells 
            'all' {
                foreach($d in $Diffs) {
                    switch ($d.Count) {
                        # insert, delete
                        1 { 
                            $d.Group | Add-Member -MemberType NoteProperty -Name 'DiffIndicator' -Value $d.Group.SideIndicator
                        }
                        # update
                        2 {
                            $d.Group[0] | Add-Member -MemberType NoteProperty -Name 'DiffIndicator' -Value '<>'
                            $d.Group[1] | Add-Member -MemberType NoteProperty -Name 'DiffIndicator' -Value '<>'
                        }
                    } 
                }
            }
            # Clear cells that are equal in reference and difference
            'clearEquals' {
                foreach($d in $Diffs) {
                    # object to hashtable
                    $RefHT = @{}
                    $d.Group[1].psobject.properties | Where { $RefNotIdentifierCols -contains $_.name } | foreach { $RefHT[$_.Name] = $_.Value }

                    # object to hashtable
                    $DifHT = @{}
                    $d.Group[0].psobject.properties | Where { $RefNotIdentifierCols -contains $_.name } | foreach { $DifHT[$_.Name] = $_.Value }
        
                    switch ($d.Count) {
                        # insert, delete
                        1 {
                            $d.Group | Add-Member -MemberType NoteProperty -Name 'DiffIndicator' -Value $d.Group.SideIndicator
                        }
                        # update
                        2 {
                            $RefNotIdentifierCols | % {
			                    if ($RefHT[$_] -eq $DifHT[$_]) {
                                    $d.Group[0].psobject.Properties.Item($_).Value = ''
                                    $d.Group[1].psobject.Properties.Item($_).Value = ''
	    	                    }
	                        }

                            $d.Group[0] | Add-Member -MemberType NoteProperty -Name 'DiffIndicator' -Value '<>'
                            $d.Group[1] | Add-Member -MemberType NoteProperty -Name 'DiffIndicator' -Value '<>'
                        }
                    } 
                }        
            }
            # Clear cells that are different in reference and difference
            'clearDiffs' {
                foreach($d in $Diffs) {
                    # object to hashtable
                    $RefHT = @{}
                    $d.Group[1].psobject.properties | Where { $RefNotIdentifierCols -contains $_.name } | foreach { $RefHT[$_.Name] = $_.Value }

                    # object to hashtable
                    $DifHT = @{}
                    $d.Group[0].psobject.properties | Where { $RefNotIdentifierCols -contains $_.name } | foreach { $DifHT[$_.Name] = $_.Value }
        
                    switch ($d.Count) {
                        # insert, delete
                        1 {
                            $d.Group | Add-Member -MemberType NoteProperty -Name 'DiffIndicator' -Value $d.Group.SideIndicator
                        }
                        # update
                        2 {
                            $RefNotIdentifierCols | % {
			                    if ($RefHT[$_] -ne $DifHT[$_]) {
                                    $d.Group[0].psobject.Properties.Item($_).Value = ''
                                    $d.Group[1].psobject.Properties.Item($_).Value = ''
	    	                    }
	                        }

                            $d.Group[0] | Add-Member -MemberType NoteProperty -Name 'DiffIndicator' -Value '<>'
                            $d.Group[1] | Add-Member -MemberType NoteProperty -Name 'DiffIndicator' -Value '<>'
                        }
                    } 
                }        
            }
            # Clear cells in reference that are equal in reference and difference.
            'clearEqualsOnReference' {
                foreach($d in $Diffs) {
                    # object to hashtable
                    $RefHT = @{}
                    $d.Group[1].psobject.properties | Where { $RefNotIdentifierCols -contains $_.name } | foreach { $RefHT[$_.Name] = $_.Value }

                    # object to hashtable
                    $DifHT = @{}
                    $d.Group[0].psobject.properties | Where { $RefNotIdentifierCols -contains $_.name } | foreach { $DifHT[$_.Name] = $_.Value }
        
                    switch ($d.Count) {
                        # insert, delete
                        1 {
                            $d.Group | Add-Member -MemberType NoteProperty -Name 'DiffIndicator' -Value $d.Group.SideIndicator
                        }
                        # update
                        2 {
                            $RefNotIdentifierCols | % {
			                    if ($RefHT[$_] -eq $DifHT[$_]) {
                                    $d.Group[1].psobject.Properties.Item($_).Value = ''
	    	                    }
	                        }

                            $d.Group[0] | Add-Member -MemberType NoteProperty -Name 'DiffIndicator' -Value '<>'
                            $d.Group[1] | Add-Member -MemberType NoteProperty -Name 'DiffIndicator' -Value '<>'
                        }
                    } 
                }        
            }
        }
    }

    # Stats
    Write-Verbose "Stats. Elapsed $( (Get-Date)-$Started )"
    if ($Output -eq 'all' -or $Output -eq 'stats') {
        $Stats["insert"] = ( ($Diffs | Where Count -eq 1).Group | Where { $_.SideIndicator -eq "=>" }).Count;
        $Stats["delete"] = ( ($Diffs | Where Count -eq 1).Group | Where { $_.SideIndicator -eq "<=" }).Count;
        $Stats["update"] = ( ($Diffs | Where Count -eq 2).Group | Where { $_.SideIndicator -eq "=>" }).Count;
        $Stats["diffs"] = $Stats["insert"] + $Stats["update"] + $Stats["delete"]; 
    }
    
    # Output
    switch($Output) {
        'all' { 
            return [PSCustomObject]@{
                'Stats'=$Stats
                'Diff'=$Diffs.Group | Select ( @("DiffIndicator", "SideIndicator") + $RefCols ) | Sort ($Identifier  += "SideIndicator")
            }
        }
        'stats' { 
             return [PSCustomObject]$Stats 
        }
        # default
        'diff' { 
             return [PSCustomObject]$Diffs.Group | Select ( @("DiffIndicator", "SideIndicator") + $RefCols ) | Sort ($Identifier  += "SideIndicator")
        }
    }

    Write-Verbose "End. Elapsed $( (Get-Date)-$Started )"
}

# tests

#cd C:\Users\xattler\Desktop\ps201901\ps-compare

#Set-Location -Path C:\Users\xattler\Desktop\ps201901\ps-compare

# Compare-CSVFile test-1-reference.csv test-1-diff-in-first-line.csv -Identifier col1,col2 <#| Where { $_.SideIndicator -eq "=>" -and $_.diff -eq "<>" }#> | Format-Table -Autosize #-Header numbers
#Compare-CSVFile test-1-reference.csv test-1-diff-in-first-line.csv -Identifier col1,col2 | Where { $_.SideIndicator -eq "=>" -and $_.DiffIndicator -eq "<>" } | Format-Table -Autosize 
#Compare-CSVFile test-1-reference.csv test-1-diff-in-first-line.csv -Identifier col1,col2 | Where { $_.SideIndicator -eq "=>"  } | Format-Table -Autosize 
#Compare-CSVFile test-1-reference.csv test-1-diff-in-first-line.csv -Identifier col1,col2 | Format-Table -Autosize

#(Compare-CSVFile test-1-reference.csv test-1-diff-in-first-line.csv -Identifier col1,col2) | Where { $_.SideIndicator -eq "=>"  } | Format-Table -Autosize 
#(Compare-CSVFile test-1-reference.csv test-1-diff-in-first-line.csv -Identifier col1,col2 -Output diff) | Format-Table -Autosize 

#Compare-CSVFile s.csv s2.csv -Identifier first,last,age | Format-Table -Autosize 

# eof