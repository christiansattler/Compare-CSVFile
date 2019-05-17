

# https://github.com/pester/Pester/wiki

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Compare-CSVFile" {

    Context 'Basis' {

        It 'B01. Soll keine Unterschiede erkennen, wenn Referenz mit sich selbst verglichen wird' {
            Compare-CSVFile .\test-1-reference.csv .\test-1-reference.csv | Should BeNullOrEmpty
        }

        It 'B02. Vergleich test-1-reference.csv mit test-1-difference-1.csv . Anzahl geänderte Zeilen (insert, update, delete) mit jeweils 2 Zeilen bei Änderungen. Erwartung: 8 .' {
            ( Compare-CSVFile .\test-1-reference.csv .\test-1-difference-1.csv ).Count | Should Be 8
        }
        
        It "B03. Vergleich test-1-reference.csv mit test-1-difference-1.csv . Anzahl geänderte Zeilen (update), jeweils nur die neue Version. Erwartung: 2 ." {
            ( Compare-CSVFile .\test-1-reference.csv .\test-1-difference-1.csv | Where { $_.DiffIndicator -eq '<>' -and $_.SideIndicator -eq '=>'} ).Count | Should Be 2
        }

        It "B04. Vergleich test-1-reference.csv mit test-1-difference-1.csv . Anzahl neue Zeilen (insert). Erwartung: 2 ." {
            ( Compare-CSVFile .\test-1-reference.csv .\test-1-difference-1.csv | Where { $_.DiffIndicator -eq '=>' -and $_.SideIndicator -eq '=>'} ).Count | Should Be 2
        }

        It "B05. Vergleich test-1-reference.csv mit test-1-difference-1.csv . Anzahl gelöschte Zeilen (delete). Erwartung: 2 ." {
            ( Compare-CSVFile .\test-1-reference.csv .\test-1-difference-1.csv | Where { $_.DiffIndicator -eq '<=' -and $_.SideIndicator -eq '<='} ).Count | Should Be 2
        }

        It "B06. Vergleich test-1-reference.csv mit test-1-difference-1.csv . Anzahl neue und gelöschte Zeilen (insert, delete). Erwartung: 4 ." {
            ( Compare-CSVFile .\test-1-reference.csv .\test-1-difference-1.csv | Where { $_.DiffIndicator -in ('=>','<=') -and $_.SideIndicator -ne '<>'} ).Count | Should Be 4
        }

    }

    Context 'Parameter Identifier' {

        It 'PK01. Wie B02 mit Identifier=col1' {
            ( Compare-CSVFile .\test-1-reference.csv .\test-1-difference-1.csv -Identifier col1).Count | Should Be 8
        }

        It 'PK02. Gegenprobe: Wie B02 mit Identifier=col1 . Erwartung: Nicht 0 .' {
            ( Compare-CSVFile .\test-1-reference.csv .\test-1-difference-1.csv -Identifier col1).Count | Should Not Be 0
        }

        It 'PK03. Wie B02 mit zwei Spalten als Schlüssel Identifier=col1,col2' {
            ( Compare-CSVFile .\test-1-reference.csv .\test-1-difference-1.csv -Identifier col1,col2 ).Count | Should Be 8
        }

        It 'PK04. Wie B02 mit zwei Schlüssel am Ende in umgekehrter Reihenfolge als in der Datei. Identifier=col8,col6' {
            ( Compare-CSVFile .\test-1-reference.csv .\test-1-difference-1.csv -Identifier col8,col6).Count | Should Be 8
        }

        It 'PK05. Wie PK04 mit abgekürztem Parameter Id. Id=col8,col6' {
            ( Compare-CSVFile .\test-1-reference.csv .\test-1-difference-1.csv -Id col8,col6).Count | Should Be 8
        }
    }

    Context 'Parameter Delimiter' {

        It 'PD01. Wie B02 jedoch mit Parameter Delimiter. Erwartung: 8 .' {
            ( Compare-CSVFile .\test-1-reference.csv .\test-1-difference-1.csv -Delimiter ';').Count | Should Be 8
        }

        It 'PD02. Gegenprobe. Wie B02 jedoch mit falschem Parameter Delimiter. Erwartung: 0 .' {
            ( Compare-CSVFile .\test-1-reference-delimiter-a.csv .\test-1-difference-delimiter-a.csv -Identifier col1 -Delimiter '#' | Where { $_.DiffIndicator -in '<>','<=','=>' }  ).Count | Should Be 0
        }

        It 'PD03. Wie B02 jedoch mit Parameter Delimiter Zeichen a. Erwartung: 8 .' {
            ( Compare-CSVFile .\test-1-reference-delimiter-a.csv .\test-1-difference-delimiter-a.csv -Identifier col1 -Delimiter 'a' | Where { $_.DiffIndicator -in '<>','<=','=>' }  ).Count | Should Be 8
        }

    }

    Context 'Parameter Header. Titelzeile, Spalten-Namen' {

        It "PH01. Numerische Spalten-Namen (als Spalten-Namen werden fortlaufende Nummern verwendet)" {
            ( Compare-CSVFile .\test-1-reference.csv .\test-1-difference-1.csv -Header numbers).Count | Should Be 8
        }
        It "PH02. Spalten-Namen als Parameter übergeben" {
            ( Compare-CSVFile .\test-1-reference.csv .\test-1-difference-1.csv -Header one,two,three,four,five,six,seven,eight).Count | Should Be 8        }
    }

    Context 'Parameter ignoreColumn. Ausblenden von Spalten' {

        It "PI01. Ausblenden der Spalten col7 und col8 für den Vergleich, es werden keine Unterschiede erkannt. Erwartung: 4 ." {
            ( Compare-CSVFile .\test-1-reference.csv .\test-1-difference-1.csv -ignoreColumn col7,col8).Count | Should Be 4
        }
    }

    Context 'Performance' {

        It "PE01.Erwartung: 19988 ." {
            ( Compare-CSVFile .\test-2-reference-1.csv .\test-2-difference-1.csv ).Count | Should Be 19988
        }
    }

<#
    Context 'Parameter Filter. Ausblenden von Inhalten' {

    
    }

    Context 'Fehlerbehandlung' {

        It "F01. Fehlende Referenz-Datei" {
            $True | Should Be $True
        }

        It "F02. Fehlende Vergleich-Datei" {
            $True | Should Be $True
        }

    }
#>

}
