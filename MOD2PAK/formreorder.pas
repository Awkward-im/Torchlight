unit formReorder;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  EditBtn;

type

  { TfmReorder }

  TfmReorder = class(TForm)
    dePAKDir: TDirectoryEdit;
    ImageList: TImageList;
    lblTitle: TLabel;
    lbPAKList: TListBox;
    sbUp: TSpeedButton;
    sbDown: TSpeedButton;
    sbApply: TSpeedButton;
    procedure dePAKDirAcceptDirectory(Sender: TObject; var Value: String);
    procedure dePAKDirButtonClick(Sender: TObject);
    procedure lbPAKListClick(Sender: TObject);
    procedure sbApplyClick(Sender: TObject);
    procedure sbDownClick(Sender: TObject);
    procedure sbUpClick(Sender: TObject);
  private
    procedure FillList(const adir: string);

  public
    constructor Create(AOwner:TComponent; const adir:string); overload;
  end;

var
  fmReorder: TfmReorder;

implementation

{$R *.lfm}

function MyFileSort(List: TStringList; Index1, Index2: Integer): Integer;
begin
  if Single(List.Objects[Index1])>Single(List.Objects[Index2]) then
    result:=1
  else
    result:=-1;
end;

procedure TfmReorder.FillList(const adir:string);
var
  sr:TSearchRec;
  sl:TStringList;
  i:integer;
begin
  lbPAKList.Clear;
  sl:=TStringList.Create;
  if FindFirst(adir+'\*.PAK',faAnyFile,sr)=0 then
  begin
    repeat
      if Upcase(sr.Name)<>'DATA.PAK' then
        sl.AddObject({adir+'\'+}sr.Name,TObject(Single(sr.Timestamp)));
    until FindNext(sr)<>0;
    FindClose(sr);
    sl.CustomSort(@MyFileSort);
  end;
  for i:=0 to sl.Count-1 do
    lbPAKList.AddItem(sl[i],nil);

  sl.Free;

  lbPAKListClick(Self);
  sbApply.Enabled:=lbPAKList.Count>1;
end;

procedure TfmReorder.dePAKDirAcceptDirectory(Sender: TObject; var Value: String);
begin
  FillList(Value);
end;

procedure TfmReorder.dePAKDirButtonClick(Sender: TObject);
var
  ls:string;
begin
  ls:=dePAKDir.Text;
  if ls[1]='<' then dePAKDir.Text:='';
end;

procedure TfmReorder.lbPAKListClick(Sender: TObject);
begin
  sbUp  .Enabled:=lbPAKList.ItemIndex>0;
  sbDown.Enabled:=lbPAKList.ItemIndex<(lbPAKList.Count-1);
end;

procedure TfmReorder.sbApplyClick(Sender: TObject);
var
  ldir,ls:string;
  ldate:TDateTime;
  i:integer;
begin
  ldir:=dePAKDir.Text+'\';
  ldate:=Now();
  for i:=0 to lbPAKList.Count-1 do
  begin
    ls:=lbPAKList.Items[i];
//  DATE ORDER IS FROM OLD TO NEW
    FileSetDate(ldir+ls,ldate-lbPAKList.Count+i);
    FileSetDate(ldir+ls+'.MAN',ldate-lbPAKList.Count+i);
  end;
end;

procedure TfmReorder.sbDownClick(Sender: TObject);
var
  lidx:integer;
begin
  lidx:=lbPAKList.ItemIndex;
  if (lidx>=0) and (lidx<(lbPAKList.Count-1)) then
  begin
    lbPAKList.Items.Move(lidx,lidx+1);
    lbPAKList.ItemIndex:=lidx+1;
    lbPAKListClick(Sender);
  end;
end;

procedure TfmReorder.sbUpClick(Sender: TObject);
var
  lidx:integer;
begin
  lidx:=lbPAKList.ItemIndex;
  if lidx>0 then
  begin
    lbPAKList.Items.Move(lidx,lidx-1);
    lbPAKList.ItemIndex:=lidx-1;
    lbPAKListClick(Sender);
  end;
end;

constructor TfmReorder.Create(AOwner:TComponent; const adir:string);
begin
  inherited Create(AOwner);

  if adir<>'' then
  begin
   dePAKDir.Text:=adir;
   FillList(adir);
  end
  else
  begin
    dePAKDir.Text:='<Choose directory with PAK files first>';
  end;
end;

end.

