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
Just remove tl2trans.ru.po file, it gives russian translation only.
You can use tl2trans.pot as template to create your own program interface translation.
=====

How to combine files into one:
------------------------------
1 - Add required files to Addon list on Settings tab
2 - Choose proper order of added files
3 - Opend last file as usual
4 - Do full export
=====

How to delete old (not presented anymore) lines:
----------------------------
1 - scan source
2 - import old project file with translation
3 - save new file

Note: Import/export buttons on project page works only with visible grid lines

'Import' function requires next format:
<source text><tab><translated text>
=====

Main hotkeys:
-------------
Ctrl-B         - Build translation file from default file and 'import' directory
Ctrl-E         - Export
Ctrl-F         - Change font
Ctrl-N         - Show tree to start scan for new project
Ctrl-O         - Open saved project
Ctrl-S         - Save project
Shift-Ctrl-S   - Save project as...
Alt-H          - Notes window
Alt-F4         - Exit program
Ctrl-F4        - Close project tab
Ctrl-Tab       - Next tab
Shift-Ctrl-Tab - Prev tab
Alt-0..Alt-9   - Go to tab ¹0-9

Middle-click on tab will close it
Double-click or Enter on Tree node will choose directory to scan
=====

Project Hotkeys:
----------------
Ctrl-A    - Select original text column
Ctrl-I    - Import from clipboard
Ctrl-R    - Call replace dialog
Ctrl-T    - Translate current line with yandex translate service
Alt-F     - Toggle filter/search mode
Alt-I     - Import file(s)
Alt-N     - Toggle full/short file name
Alt-R     - Toggle hide/show translated lines
Alt-S     - Open source file referred by file and tag
Alt-Del   - Set translation without color info
Alt-Right - Search next
Del       - Delete translated text / delete line(s)

Double-Click opens text editor window
=====

Text Edit in Cell hotkeys:
-------------------------
(Mainly for non-latin locales. These insertions replaces selected text)
Alt-C   - Insert color tag from original text
Alt-N   - Insert \n (new line) signature
Alt-U   - Insert |u (end colored text) signature
Alt-V   - Insert parameters like <STAT1>, [TIME] and [[KB:SkillMenu]]
Alt-Del - Delete color info
====

Text Edit window hotkeys:
-------------------------
Alt-Left  - Previous line
Alt-Right - Next line
Alt-Up    - Previous untranslated line
Alt-Down  - Next untranslated line
Alt-P     - [Un]mark line as partially translated
Alt-S     - Show/hide source with partial translation
Alt-T     - Translate selected or source text with yandex translate service
=====

Notes:
------
*.ref file saves info about source mod files, tags and lines where they was.
Also it keep "partial" translation state. So, if this info not useful,
that files can be deleted.

If you have any questions, feel free to email me: cheshirabit@gmail.com
=====
