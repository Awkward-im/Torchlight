unit RGGUI.Shared;

interface

uses
  LCLType, Forms, Graphics;

{
type
  TPanelData = record
    panel:TForm;
  end;
}
var
  ActivePanel:integer;
  PanelCount:integer;
  Panels:array [0..15] of TForm;//TPanelData;
  

const
  strParentDir = '. . /';
  strDir       = '< DIR >';
const
  stlblNew     = '+' ;
  stlblChanged = '*' ;
  stlblDelete  = 'X' ;
  stlblLinkNew = 'F+';
  stlblLinkEd  = 'F*';
const
  clrNewFG     = clDefault; clrNewBG     = clLime;
  clrChangedFG = clDefault; clrChangedBG = TColor($FFFF00); // Cyan
  clrDeleteFG  = clDefault; clrDeleteBG  = TColor($C0C0C0); // Light Gray
  clrLinkFG    = clDefault; clrLinkBG    = clMaroon;


const
  defFontName    = 'Courier New'; // 'MS Sans Serif'
  defFontCharset = DEFAULT_CHARSET;
  defFontSize    = 12;
  defFontStyle   = '';
  defFontColor   = clWindowText;

  sSectSrcFont  = 'srcfont';
  sFontName     = 'Name';
  sFontCharset  = 'Charset';
  sFontSize     = 'Size';
  sFontStyle    = 'Style';
  sFontColor    = 'Color';


const
  sNewDir  = 'NEWDIR/';
  sNewFile = 'NEWFILE.DAT';

resourcestring
  rsWarning         = 'Warning!';
  rsUnsaved         = 'You have unsaved changes. Continue anyway?';
  rsTypeChanged     = 'New name have another extension. Continue?';
  rsSureToDelete    = 'Are you sure to delete selected?';

  rsReadPAK         = ' Read PAK. Parsing...';
  rsBuildTree       = ' Build tree';
  rsBuildGrid       = ' Build file list. Please, wait...';
//  rsBuildPreview    = ' Build preview';
  rsNothingToShow   = 'Nothing to show with current filter';
  rsUnpackSucc      = 'unpacked succesfully.';
  rsFilesUnpackSucc = ' files unpacked succesfully.';
//  rsTotal           = 'Total: ';
  rsFiles           = 'Files: ';
  rsDirs            = '; dirs: ';
  rsFilePath        = 'File path: ';
  rsSave            = 'Save Pak/mod';
  rsSavePatch       = 'Save patch (Changes)';
  rsSaved           = 'File saved';
  rsSavedAs         = 'File saved as';
  rsSavedPatch      = 'Patch saved as';
  rsCantSave        = 'Can''t save file';
  rsExtractDir      = 'Extract directory ';
  rsSelectDir       = 'Select directory';

  rsCreateDir       = 'Create directory';
  rsCreateFile      = 'Create file';
  rsDirName         = 'Enter dir name';
  rsFileName        = 'Enter file name';
  rsFileDirName     = 'Enter name (with / at the end for dir)';
  rsNewName         = 'Enter new name';
  rsExists          = 'File or dir with this name exists already.';

  rsFullList        = 'Full file list';

  rsReady           = 'Ready to work';
  rsRename          = 'Rename file/dir';
  rsRenameOld       = 'Rename existing file';
  rsRenameNew       = 'Rename copying file';
  rsImported        = ' files imported';
  rsLinkingNote     = 'These files still on disk and not built-in until PAK/MOD saved.';
  rsNothingImported = 'Nothing was imported.';
//  rsChooseVer       = 'Choose game';
//  rsGameVer         = 'Game';

  rsNewFile         = 'New file';
  rsChangedFile     = 'Changed file';
  rsDeleteFile      = 'Deleted file';
  rsLinkNewFile     = 'Link to new file';
  rsLinkChangedFile = 'Link to changed file';

  rsSureToCopyShell = 'Are you sure to copy selected files to'#13#10'"%s" dir?';
  rsSureToCopy      = 'Are you sure to copy selected files to'#13#10+
                      '"$2" dir of "$1" pak?';
//                      '"%0:s" Pak and "%1:s" dir?';
  rsCopied          = 'File copied';
  rsNotCopied       = 'Nothing copied';


implementation


end.

