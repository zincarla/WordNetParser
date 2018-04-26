# Overview
This project provides a set of scripts to convert [Princeton's WordNet](https://wordnet.princeton.edu/) database files into a SQL database. A pre-generated database is included with these scripts if you just want to jump to that. These scripts only provide a subset of the data available in the WordNet, specifically anything located in the word database files. This gives us the word, definition, and relations to other words. 

# Scripts
These scripts allow you to generate your own database off of the WordNet database files.

## WordNetParser.ps1
Given the WordNet database files, this script will parse all the information into a dictionary (As in, the in-memory data structure), for examination or use in other scripts.

## BuildDatabase.ps1
This script, when provided the output of the WordNetParser.ps1 script, will connect to the specified MariaDB/MySQL database and generate dictionary tables based off of the data provided. This script uses [Thomas Maurer's](https://www.thomasmaurer.ch/2011/04/powershell-run-mysql-querys-with-powershell/) Run-MySQLQuery powershell function.

## Full Script Example
This is an example on how to generate the database. This assumes that the working directory of powershell contains the two scripts, and the necessary WordNet database files.
```
$Data = &".\WordNetParser.ps1"
&".\BuildDatabase.ps1" -Data $Data -SQLIP "localhost" -UserPWD "password" -SSL $true
```

# Dictionary
Also provided is a pre-generated sql export of the dictionary database. You can skip utilizing the scripts by importing this sql file into your database server. Note that this information is subject to Princeton's license.

## Database structure
### Words
This table contains information on the words themselves.

Name | Description | WordNet Term
--- | --- | ---
ID | Unique ID of word in database | Not from WordNet
Word | The word itself | word
Glossary | Description and examples of the word | gloss
SynSetID | ID of the word's synonym set, multiple words in this table will share this id | synset_offset
Type | Word class (Noun, Verb, etc) | ss_type

### Relations
This table contains additional relations between words

Name | Description | WordNet Term
--- | --- | ---
ID | Unique ID of relation in database | Not from WordNet
SourceID | SynSetID of the source word for this relationship | synset_offset
PairedID | SynSetID of the target word for this relationship | synset_offset
Relationship | Type of relationship, see table in next section | pointer_symbol
PairedType | Word class of the paired word | pos (Same as ss_type)

#### Relationship
The Relationship column of the Relations table maps to the pointer_symbol in the WordNet database. I did not alter their values. Per Princeton's documentation, these values are:

>  **The pointer_symbol s for nouns are:**<br>
>  ! Antonym<br>
>  @ Hypernym<br>
>  @i Instance Hypernym<br>
>  ~ Hyponym<br>
>  ~i Instance Hyponym<br>
>  #m Member holonym<br>
>  #s Substance holonym<br>
>  #p Part holonym<br>
>  %m Member meronym<br>
>  %s Substance meronym<br>
>  %p Part meronym<br>
>  = Attribute<br>
>  \+ Derivationally related form<br>
>  ;c Domain of synset - TOPIC<br>
>  -c Member of this domain - TOPIC<br>
>  ;r Domain of synset - REGION<br>
>  -r Member of this domain - REGION<br>
>  ;u Domain of synset - USAGE<br>
>  -u Member of this domain - USAGE<br>
>  **The pointer_symbol s for verbs are:**<br>
>  ! Antonym<br>
>  @ Hypernym<br>
>  ~ Hyponym<br>
>  \* Entailment<br>
>  \> Cause<br>
>  ^ Also see<br>
>  $ Verb Group<br>
>  \+ Derivationally related form <br>
>  ;c Domain of synset - TOPIC<br>
>  ;r Domain of synset - REGION<br>
>  ;u Domain of synset - USAGE<br>
>  **The pointer_symbol s for adjectives are:**<br>
>  ! Antonym<br>
>  & Similar to<br>
>  < Participle of verb<br>
>  \ Pertainym (pertains to noun)<br>
>  = Attribute<br>
>  ^ Also see<br>
>  ;c Domain of synset - TOPIC<br>
>  ;r Domain of synset - REGION<br>
>  ;u Domain of synset - USAGE<br>
>  **The pointer_symbol s for adverbs are:**<br>
>  ! Antonym<br>
>  \ Derived from adjective<br>
>  ;c Domain of synset - TOPIC<br>
>  ;r Domain of synset - REGION<br>
>  ;u Domain of synset - USAGE<br>

## Database Examples
To get a word's definitions
```
SELECT * FROM Words WHERE Word='car'
```
To get all relations for a specific instance of a word
```
SELECT * FROM Relations WHERE SourceID = 123456
```
To get all direct synonyms for a specific instance of a word
```
SELECT * FROM Words WHERE SynSetID= 123456
```

# Additional Information
Please see the documentation available at [Princeton's website](https://wordnet.princeton.edu/documentation). It contains alot of helpfull information in understanding WordNet itself, and the format of the files they provide.
