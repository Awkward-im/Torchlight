ABOUT
-----
This program was developed to help translate Torchlight II text from mods to another
languages. It was written on FreePascal language with less as possible 3rd side components.
It supports different interface languages (English is built-in) but initially russian used.
It based on another program, 'TorchTranslate' by Abramoff
Feel free to modify it. But if you will show me changes, it can be nice ^_^
=====

How to change program language:
------------------------------
"Settings" dialog have list of program localizations which you can use. Just select required
line. If your language not presents there, you can create it by yourself. That just text file in
UTF-8 encoding. You can use languages\sqlcp.pot as template to create your own program interface
translation and languages\*.po files as examples. Save your newly created (edited) PO file there and
restart program. You can use Poedit (https://poedit.net/download) program to edit these localizations.
=====

'Import from clipboard' function requires next format:
<source text><tab><translated text>
=====

Main hotkeys:
-------------
Ctrl-E       - Export
Ctrl-F       - Change font
Ctrl-S       - Save project
Alt-H        - Notes window
Alt-F4       - Exit program
F5           - Show Similar text window
F6           - Show Doubles window
F7           - Show List of text at same place
=====

Project Hotkeys:
----------------
Enter        - Edit current translation cell
Ctrl-A       - Select original text column
Ctrl-I       - Import from clipboard
Ctrl-R       - Call replace dialog
Ctrl-T       - Translate current line with online translation service
Shift-Ctrl-C - copy selected cells (current column only) without tags
Alt-F        - Toggle filter/search mode
Alt-I        - Import file(s)
Alt-P        - Check for notes of translation
Alt-Del      - Set translation without color info
Alt-Right    - Search next
Del          - Delete translated text / delete line(s)

Double-Click opens text editor window
=====

Text Edit in Cell hotkeys:
-------------------------
(Mainly for non-latin locales. These insertions replaces selected text)
Enter        - Finish to edit translation cell
Alt-C        - Insert color tag from original text
Alt-N        - Insert \n (new line) signature
Alt-U        - Insert |u (end colored text) signature
Alt-V        - Insert parameters like <STAT1>, [TIME] and [[KB:SkillMenu]]
Alt-Del      - Delete color info
====

Text Edit window hotkeys:
-------------------------
Alt-Left     - Previous line
Alt-Right    - Next line
Alt-Up       - Previous untranslated line
Alt-Down     - Next untranslated line
Alt-P        - [Un]mark line as partially translated
Alt-S        - Show/hide source with partial translation
Alt-T        - Translate selected or source text with online translation service
=====

Notes:
------
If you have any questions, feel free to email me: cheshirabit@gmail.com
=====
