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


resourcestring
  rsWarning         = 'Warning!';
  rsUnsaved         = 'You have unsaved changes. Continue anyway?';
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
  rsCreateDir       = 'Create directory';
  rsSelectDir       = 'Select directory';
  rsDirName         = 'Enter dir name';
  rsCreateFile      = 'Create file';
  rsFileName        = 'Enter file name';
  rsFileDirName     = 'Enter name (with / at the end for dir)';
  rsReady           = 'Ready to work';
  rsRename          = 'Rename file/dir';
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

implementation


end.

