Param($SkipLoad = 29, $Paths=(".\data.noun", ".\data.verb",".\data.adv",".\data.adj",".\data.adv"))
                # ID    lexnum type  count          Word        lexid  pntrcnt    pntrsmbl id typ src/trgt  frame:cnt   fnum  wnum           glossary
$RegexPattern = "^(\d+) (\d\d) (\w) (\S{2})(?: (\S+ \S))+ (\d\d\d)(?: (.{1,2} \d+ \w \S+))* ?(\d\d( \+ \d\d \S{2})*)? \| (.*)$"
$Matcher = [regex]::new($RegexPattern)
#https://wordnet.princeton.edu/documentation/wndb5wn
#https://wordnet.princeton.edu/documentation/wninput5wn
<#
The pointer_symbol s for nouns are:

!    Antonym 
@    Hypernym 
@i    Instance Hypernym 
 ~    Hyponym 
 ~i    Instance Hyponym 
#m    Member holonym 
#s    Substance holonym 
#p    Part holonym 
%m    Member meronym 
%s    Substance meronym 
%p    Part meronym 
=    Attribute 
+    Derivationally related form         
;c    Domain of synset - TOPIC 
-c    Member of this domain - TOPIC 
;r    Domain of synset - REGION 
-r    Member of this domain - REGION 
;u    Domain of synset - USAGE 
-u    Member of this domain - USAGE 
The pointer_symbol s for verbs are:

!    Antonym 
@    Hypernym 
 ~    Hyponym 
*    Entailment 
>    Cause 
^    Also see 
$    Verb Group 
+    Derivationally related form         
;c    Domain of synset - TOPIC 
;r    Domain of synset - REGION 
;u    Domain of synset - USAGE 
The pointer_symbol s for adjectives are:

!    Antonym 
&    Similar to 
<    Participle of verb 
\    Pertainym (pertains to noun) 
=    Attribute 
^    Also see 
;c    Domain of synset - TOPIC 
;r    Domain of synset - REGION 
;u    Domain of synset - USAGE 
The pointer_symbol s for adverbs are:

!    Antonym 
\    Derived from adjective 
;c    Domain of synset - TOPIC 
;r    Domain of synset - REGION 
;u    Domain of synset - USAGE 
#>

$WordResults = New-Object System.Collections.ArrayList
$RelationResults = New-Object System.Collections.ArrayList

$LastUpdate = [DateTime]::Now
$UpdateSchedule = [TimeSpan]::FromSeconds(5)
$Trash = $null

foreach ($Path in $Paths) {
    Write-Host $Path
    $Content = Get-Content -Path $Path

    for ($I = $SkipLoad; $I-lt $Content.Length; $I++) {
        $Line = $Content[$I]

        $RMatches = $Matcher.Matches($Line)[0]
        if ($RMatches -eq $null) {
            Write-Host "ERR: $Line"
        }
        $ID = $RMatches.Groups[1].Captures.Value
        $Type = $RMatches.Groups[3].Captures.Value
        $Names = $RMatches.Groups[5].Captures.Value
        $Relations = $RMatches.Groups[7].Captures.Value
        $Glossary = $RMatches.Groups[10].Captures.Value

        foreach ($Name in $Names) {
            $Trash=$WordResults.Add((New-Object -TypeName PSObject -Property @{Name=$Name.Substring(0, $Name.Length-2); ID=$ID; Glossary=$Glossary; Type=$Type })) # Piping to out-null is actually really slow. idk why. Setting a trash variable is waaaay faster, need to do this or results are f*cked
        }

        foreach ($Relation in $Relations) {
            $RelationParts = $Relation.Split(" ")
            $PairType = $RelationParts[0]
            $PairedID = $RelationParts[1]
            $PairedType = $RelationParts[2]
            $SourceTarget = $RelationParts[3]
            $Trash=$RelationResults.Add((New-Object -TypeName PSObject -Property @{Relationship=$PairType;SourceID=$ID;PairedID=$PairedID;PairedType=$PairedType; SourceTarget=$SourceTarget })) # Piping to out-null is actually really slow. idk why. Setting a trash variable is waaaay faster, need to do this or results are f*cked
        }
        if ([DateTime]::Now - $LastUpdate -gt $UpdateSchedule) {
            Write-Host "$I/$($Content.Length)"
            $LastUpdate = [DateTime]::Now
        }
    }
}
return @{Words=$WordResults;Relations=$RelationResults}