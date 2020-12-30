unit formGUI;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, Grids, Menus,
  ActnList, ExtCtrls, ComboEx, StdCtrls,
  rgpak;

type

  { TRGGUIForm }

  TRGGUIForm = class(TForm)
    ccbCategory: TCheckComboBox;
    ccbExtension: TCheckComboBox;
    ImageList: TImageList;
    lblExtension: TLabel;
    lblCategory: TLabel;
    pnlFilter: TPanel;
    StatusBar: TStatusBar;
    ToolBar: TToolBar;
    sgMain: TStringGrid;

    MainMenu: TMainMenu;
    miFile: TMenuItem;
    miFileOpen   : TMenuItem;
    miFileSave   : TMenuItem;
    miFileSaveAs : TMenuItem;
    miFileClose  : TMenuItem;
    N1           : TMenuItem;
    miFileExit   : TMenuItem;
    miEdit: TMenuItem;
    miEditExtract: TMenuItem;
    miEditSearch : TMenuItem;
    miEditReplace: TMenuItem;
    miEditDelete : TMenuItem;
    miHelp: TMenuItem;
    miHelpAbout  : TMenuItem;

    ActionList: TActionList;
    actFileOpen   : TAction;
    actFileSave   : TAction;
    actFileSaveAs : TAction;
    actFileClose  : TAction;
    actFileExit   : TAction;
    actEditExtract: TAction;
    actEditDelete : TAction;
    actEditSearch : TAction;
    actEditReplace: TAction;
    actHelpAbout  : TAction;
    actInfoInfo   : TAction;
    procedure actFileCloseExecute(Sender: TObject);
    procedure actFileExitExecute(Sender: TObject);
    procedure actFileOpenExecute(Sender: TObject);
    procedure ccbCategoryCloseUp(Sender: TObject);
    procedure ccbCategoryItemChange(Sender: TObject; AIndex: Integer);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure sgMainCompareCells(Sender: TObject; ACol, ARow, BCol,
      BRow: Integer; var Result: integer);
  private
    fCatWasChanged: Boolean;
    rgpi:TPAKInfo;

    procedure FillExtList();
    procedure FillGrid();
    function FillGridLine(arow: integer; const adir: string;
      const afile: TMANFileInfo): boolean;

  public

  end;

var
  RGGUIForm: TRGGUIForm;

implementation

{$R *.lfm}

uses
  rgglobal;
{
resourcestring
  rsCategory = 'Category';
}
const
  colDir    = 1;
  colName   = 2;
  colType   = 3;
  colTime   = 4;
  colPack   = 5;
  colUnpack = 6;
  colSource = 7;

//----- Support -----

const
  FileTimeBase      = -109205.0;
  FileTimeStep: Extended = 24.0 * 60.0 * 60.0 * 1000.0 * 1000.0 * 10.0; // 100 nSek per Day

function FileTimeToDateTime(const FileTime: Int64): TDateTime;
begin
  Result := FileTime / FileTimeStep;
  Result := Result + FileTimeBase;
end;

{ TRGGUIForm }

procedure TRGGUIForm.actFileOpenExecute(Sender: TObject);
var
  OpenDialog: TOpenDialog;
begin
  OpenDialog:=TOpenDialog.Create(nil);
  try
//    OpenDialog.Title  :=rsFileOpen;
    OpenDialog.Options:=[ofFileMustExist];

    if OpenDialog.Execute then
    begin
      rgpi.fname:=OpenDialog.FileName;
      if GetPAKInfo(rgpi,piFullParse) then
      begin
        Self.Caption:='RGGUI - '+rgpi.fname;
        StatusBar.SimpleText:='Total: '+IntToStr(rgpi.total)+'; dirs: '+IntToStr(Length(rgpi.Entries));
      end;
      FillExtList();
      FillGrid();
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TRGGUIForm.ccbCategoryCloseUp(Sender: TObject);
begin
  ccbCategory.ItemIndex:=-1;
//  ccbCategory.Text:=rsCategory; //!! not working
  if fCatWasChanged then
  begin
    FillGrid();
    fCatWasChanged:=false;
  end;
end;

procedure TRGGUIForm.ccbCategoryItemChange(Sender: TObject; AIndex: Integer);
begin
  fCatWasChanged:=true;
end;

procedure TRGGUIForm.FillExtList();
var
  i,j:integer;
begin
  ccbExtension.ReadOnly:=true;
  ccbExtension.Clear;
{
  if ABS(rgpi.ver)=verTL2 then
  begin
    for i:=0 to High(TableExtTL2) do
    begin
      ccbExtension.AddItem(TableExtTL2[i],cbChecked);
//      ccbExtension.Objects[i]:=TObject(i);
    end;
  end
  else
  begin
    for i:=0 to High(TableExtHob) do
    begin
      ccbExtension.AddItem(TableExtHob[i],cbChecked);
//      ccbExtension.Objects[i]:=TObject(i);
    end;
  end;
}
end;

procedure TRGGUIForm.FormCreate(Sender: TObject);
begin
  // Category
  ccbCategory.ReadOnly:=true;
  ccbCategory.Clear;
  ccbCategory.AddItem(CategoryList[catUnknown],cbChecked);
  ccbCategory.AddItem(CategoryList[catModel  ],cbChecked);
  ccbCategory.AddItem(CategoryList[catImage  ],cbChecked);
  ccbCategory.AddItem(CategoryList[catSound  ],cbChecked);
  ccbCategory.AddItem(CategoryList[catFolder ],cbUnChecked);
  ccbCategory.AddItem(CategoryList[catFont   ],cbChecked);
  ccbCategory.AddItem(CategoryList[catData   ],cbChecked);
  ccbCategory.AddItem(CategoryList[catLayout ],cbChecked);
  ccbCategory.AddItem(CategoryList[catShaders],cbChecked);
  ccbCategory.AddItem(CategoryList[catOther  ],cbChecked);
  ccbCategory.ItemIndex:=-1;
//  ccbCategory.Style:=csDropDownList;
//  ccbCategory.Text:=rsCategory; //!! not working

  // Extension
end;

procedure TRGGUIForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  FreePAKInfo(rgpi);
end;

procedure TRGGUIForm.actFileCloseExecute(Sender: TObject);
begin
  FreePAKInfo(rgpi);
  sgMain.Clear;
end;

procedure TRGGUIForm.actFileExitExecute(Sender: TObject);
begin
  actFileCloseExecute(Sender);
  Close;
end;

procedure TRGGUIForm.sgMainCompareCells(Sender: TObject; ACol, ARow, BCol,
  BRow: Integer; var Result: integer);
var
  s1,s2:string;
  dt1,dt2:TDateTime;
begin
  s1:=(Sender as TStringGrid).Cells[ACol,ARow];
  s2:=(Sender as TStringGrid).Cells[BCol,BRow];

  if ACol in [colPack,colUnpack,colSource] then
  begin
    result:=StrToIntDef(s1,0)-
            StrToIntDef(s2,0);
  end
  else if ACol=colTime then
  begin
{
  variant - sort not by table but source timestamp
  TMANFileInfo link requires
}
    dt1:=StrToDateTimeDef(s1,0);
    dt2:=StrToDateTimeDef(s2,0);
    if dt1>dt2 then
      result:=1
    else if dt1<dt2 then
      result:=-1
    else
      result:=0;
  end
  else
    result:=CompareStr(s1,s2);

  if (Sender as TStringGrid).SortOrder=soDescending then
    result:=-result;
end;

function TRGGUIForm.FillGridLine(arow:integer; const adir:string; const afile:TMANFileInfo):boolean;
var
  lext:WideString;
  lcat:integer;
  i:integer;
begin
  result:=false;

  if afile.size_s=0 then exit;
  
  lext:=ExtractFileExt(afile.name);
  for i:=0 to ccbExtension.Items.Count-1 do
  begin

  end;

//  lcat:=GetCategory(lext);
//  if not ccbCategory.Checked[lcat] then exit(false);

  sgMain.Cells[colDir   ,arow]:=adir;
  sgMain.Cells[colName  ,arow]:=afile.name;
  sgMain.Cells[colPack  ,arow]:=IntToStr(afile.size_c);
  sgMain.Cells[colUnpack,arow]:=IntToStr(afile.size_u);
  sgMain.Cells[colType  ,arow]:=PAKTypeToCategoryText(rgpi.ver,afile.ftype);
  if sgMain.Columns[colTime-1].Visible and (afile.ftime<>0) then
  begin
    try
      sgMain.Cells[colTime,arow]:=DateTimeToStr(FileTimeToDateTime(afile.ftime));
    except
      sgMain.Cells[colTime,arow]:='0x'+HexStr(afile.ftime,16);
    end;
  end
  else
    sgMain.Cells[colTime,arow]:='';
  if afile.size_s<>afile.size_u then
    sgMain.Cells[colSource,arow]:=IntToStr(afile.size_s)
  else
    sgMain.Cells[colSource,arow]:='';

  result:=true;
end;

procedure TRGGUIForm.FillGrid();
var
  i,j:integer;
  lcnt:integer;
begin
  sgMain.Clear;
  sgMain.BeginUpdate;
  sgMain.Columns[colTime-1].Visible:=(ABS(rgpi.ver)=verTL2);

  sgMain.RowCount:=rgpi.total+1;
  lcnt:=1;
  for i:=0 to High(rgpi.Entries) do
  begin
    for j:=0 to High(rgpi.Entries[i].Files) do
    begin
      if FillGridLine(lcnt, rgpi.Entries[i].name, rgpi.Entries[i].Files[j]) then
        inc(lcnt);
    end;
  end;
  sgMain.RowCount:=lcnt;

  sgMain.EndUpdate;
end;

end.

