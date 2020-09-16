Converts binary .DAT, .ANIMATION (TL1, TL2, Hob) and .LAYOUT (TL2 and Hob) files to text form.

first commandline argument - process just this file
No argument - process all files starting from current dir resursively

main dictionary: "dictionary.txt"
additional (from Hob), with crap: "hashed.txt"
TL2 layout helper file - "objects.dat" (tag names and data types)
custom dictionaries (if presents) for aliases (apply first):
  "dataliases.txt" for DAT and ANIMATION files
  "layaliases.txt" for LAYOUT files

debug version of program cretes "hashes.txt" file with list of unrecognized hashes

TL2 layout decoder don't recognize tags which not presents in objects.dat, like
<STRING>GUID (code 103) and <STRING>STAT STATIC ONE (code 65)