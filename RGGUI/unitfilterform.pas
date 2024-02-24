unit unitFilterForm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  CheckLst, IniFiles;

type

  { TFilterForm }

  TFilterForm = class(TForm)
    clbExtension: TCheckListBox;
    clbCategory: TCheckListBox;
    lblCategory: TLabel;
    lblExtension: TLabel;
    Panel1: TPanel;
    procedure clbCategoryItemClick(Sender: TObject; Index: integer);
    procedure clbCategorySelectionChange(Sender: TObject; User: boolean);
    procedure clbExtensionItemClick(Sender: TObject; Index: integer);
    procedure FormCreate(Sender: TObject);
  private
    procedure CheckExtList(checked: TCheckBoxState);
    procedure FillCategoryList();
    procedure FillExtList(filter: integer);
  public
    exts:array of boolean;

    function  DirIsOn:boolean;
    procedure LoadSettings(config: TIniFile);
    procedure SaveSettings(config: TIniFile);
  end;

var
  fmFilterForm: TFilterForm;

implementation

{$R *.lfm}
uses
  rgfiletype;

{ TFilterForm }

const
  strSection = 'Filter';
  strShowDir = 'ShowDir';

procedure TFilterForm.SaveSettings(config:TIniFile);
var
  i:integer;
begin
  for i:=1 to clbCategory.Count-1 do
  begin
    if IntPtr(clbCategory.Items.Objects[i])=catFolder then
    begin
      config.WriteBool(strSection,strShowDir,clbCategory.Checked[i]);
      break;
    end;
  end;

  for i:=0 to High(exts) do
    config.WriteBool(strSection,TableExt[i]._ext,exts[i]);
end;

procedure TFilterForm.LoadSettings(config:TIniFile);
var
  i,j:integer;
  lstate:integer;
begin
  for i:=0 to High(exts) do
    exts[i]:=config.ReadBool(strSection,TableExt[i]._ext,true);

  // check categories by checking all exts
  for i:=1 to clbCategory.Count-1 do
  begin
    if IntPtr(clbCategory.Items.Objects[i])=catFolder then
      clbCategory.Checked[i]:=config.ReadBool(strSection,strShowDir,true)
    else
    begin
      lstate:=-1;
      for j:=0 to High(TableExt) do
      begin
        if PAKTypeToCategory(TableExt[j]._type)=
           IntPtr(clbCategory.Items.Objects[i]) then
        begin
          if lstate<0 then lstate:=ORD(exts[j])
          else if lstate<>ORD(exts[j]) then lstate:=2;
        end;
      end;
      if lstate<0 then lstate:=0;
      clbCategory.State[i]:=TCheckBoxState(lstate);
    end;
  end;
  CheckExtList(cbGrayed);
  // check "All"
  clbCategoryItemClick(self,1);
end;

function TFilterForm.DirIsOn:boolean;
var
  i:integer;
begin
  for i:=1 to clbCategory.Count-1 do
  begin
    if IntPtr(clbCategory.Items.Objects[i])=catFolder then
    begin
      exit(clbCategory.Checked[i]);
    end;
  end;
  result:=false;
end;

procedure TFilterForm.FormCreate(Sender: TObject);
begin
  SetLength(exts,Length(TableExt));
  FillCategoryList();
//  FillExtList();
end;

procedure TFilterForm.FillCategoryList();
begin
  with clbCategory do
  begin
    Clear;
    AddItem('All',nil);
    AddItem(PAKCategoryName(catUnknown),TObject(catUnknown));
    AddItem(PAKCategoryName(catModel  ),TObject(catModel  ));
    AddItem(PAKCategoryName(catImage  ),TObject(catImage  ));
    AddItem(PAKCategoryName(catSound  ),TObject(catSound  ));
    AddItem(PAKCategoryName(catFolder ),TObject(catFolder ));
    AddItem(PAKCategoryName(catFont   ),TObject(catFont   ));
    AddItem(PAKCategoryName(catData   ),TObject(catData   ));
    AddItem(PAKCategoryName(catLayout ),TObject(catLayout ));
    AddItem(PAKCategoryName(catShaders),TObject(catShaders));
    AddItem(PAKCategoryName(catOther  ),TObject(catOther  ));
    clbCategory.Selected[0]:=true;
  end;
end;

procedure TFilterForm.clbCategoryItemClick(Sender: TObject; Index: integer);
var
  i:integer;
  lstate:TCheckBoxState;
begin
  if index=0 then
  begin
    if clbCategory.State[0]<>cbGrayed then
    begin
      for i:=1 to clbCategory.Count-1 do
        clbCategory.Checked[i]:=clbCategory.Checked[0];
      for i:=0 to High(exts) do
        exts[i]:=clbCategory.Checked[0];
    end;
  end
  else
  begin
    lstate:=clbCategory.State[1];
    for i:=2 to clbCategory.Count-1 do
    begin
      if lstate<>clbCategory.State[i] then
      begin
        lstate:=cbGrayed;
        break;
      end;
    end;
    clbCategory.State[0]:=lstate;
  end;
end;

procedure TFilterForm.clbCategorySelectionChange(Sender: TObject; User: boolean);
var
  i:integer;
begin
  if clbCategory.Selected[0] then
  begin
    FillExtList(-1);
    CheckExtList(cbGrayed);
  end
  else
    for i:=1 to clbCategory.Count-1 do
      if clbCategory.Selected[i] then
      begin
        FillExtList(IntPtr(clbCategory.Items.Objects[i]));
        CheckExtList(clbCategory.State[i]);
        break;
      end;
end;

procedure TFilterForm.clbExtensionItemClick(Sender: TObject; Index: integer);
var
  lext,lcat:IntPtr;
  lstate:TCheckBoxState;
  i:integer;
begin
  lext:=IntPtr(clbExtension.Items.Objects[Index]);
  exts[lext]:=clbExtension.Checked[Index];
  lcat:=PAKTypeToCategory(TableExt[lext]._type);

  lstate:=clbExtension.State[0];
  for i:=0 to clbExtension.Count-1 do
  begin
    if lstate<>clbExtension.State[i] then
    begin
      lstate:=cbGrayed;
      break;
    end;
  end;

  for i:=1 to clbCategory.Count-1 do
  begin
    if IntPtr(clbCategory.Items.Objects[i])=lcat then
    begin
      clbCategory.State[i]:=lstate;
      clbCategoryItemClick(self,i);
      break;
    end;
  end;
end;

procedure TFilterForm.FillExtList(filter:integer);
var
  i:integer;
begin
  with clbExtension do
  begin
    Clear;
    for i:=0 to High(TableExt) do
    begin
      if (filter<0) or
          (PAKTypeToCategory(TableExt[i]._type)=filter) then
      begin
        AddItem(TableExt[i]._ext,TObject(IntPtr(i)));
      end;
    end;
  end;
end;

procedure TFilterForm.CheckExtList(checked:TCheckBoxState);
var
  i,lext:integer;
begin
  if checked=cbGrayed then
  begin
    for i:=0 to clbExtension.Count-1 do
    begin
      lext:=IntPtr(clbExtension.Items.Objects[i]);
      clbExtension.Checked[i]:=exts[lext];
    end;
  end
  else
    for i:=0 to clbExtension.Count-1 do
    begin
      clbExtension.State[i]:=checked;
      lext:=IntPtr(clbExtension.Items.Objects[i]);
      exts[lext]:=checked=cbChecked;
    end;
end;

end.

