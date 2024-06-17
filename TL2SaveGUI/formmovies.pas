unit formMovies;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, Buttons,
  StdCtrls, tlsave, rgglobal;

type

  { TfmMovies }

  TfmMovies = class(TForm)
    bbUpdate: TBitBtn;
    lblNote: TLabel;
    sgMovies: TStringGrid;

    procedure bbUpdateClick(Sender: TObject);
    procedure sgMoviesEditingDone(Sender: TObject);
    procedure sgMoviesKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
      );
  private
    SGame:TTLSaveFile;

  public
    procedure FillInfo(aSGame:TTLSaveFile);

  end;


implementation

{$R *.lfm}

uses
  LCLType,
  addons,
  tl2db;

const
  colTitle = 0;
  colViews = 1;
  colPath  = 2;
  colID    = 3;
  colName  = 4;
  colMod   = 5;

procedure TfmMovies.sgMoviesEditingDone(Sender: TObject);
var
  lviews:integer;
begin
  lviews:=StrToIntDef(sgMovies.Cells[colViews,sgMovies.Row],-1);
  if (lviews<0) or
     (lviews>IntPtr(sgMovies.Objects[1,sgMovies.Row])) then
  begin
    sgMovies.Cells[colViews,sgMovies.Row]:='0';
  end;
  bbUpdate.Enabled:=true;
end;

procedure TfmMovies.sgMoviesKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key=VK_DELETE) then
  begin
    bbUpdate.Enabled:=DeleteSelectedRows(sgMovies);
  end;
end;

procedure TfmMovies.bbUpdateClick(Sender: TObject);
var
  ls:string;
  i:integer;
begin
  ls:=Application.MainForm.Caption;
  ls[1]:='*';
  Application.MainForm.Caption:=ls;

  for i:=1 to sgMovies.RowCount do
  begin
    SGame.Movies[IntPtr(sgMovies.Objects[0,i])].value:=
        StrToInt(sgMovies.Cells[colViews,i]);
  end;
  bbUpdate.Enabled:=false;
end;

procedure TfmMovies.FillInfo(aSGame:TTLSaveFile);
var
  lmax,i:integer;
  lmod,lname,ltitle,lpath:string;
begin
  SGame:=aSGame;

  sgMovies.BeginUpdate;
  sgMovies.Clear;
  sgMovies.RowCount:=Length(aSGame.Movies)+1;
  if Length(aSGame.Movies)>0 then
  begin
    for i:=0 to High(aSGame.Movies) do
    begin
      ltitle:=GetTL2Movie(aSGame.Movies[i].id,lmod,lmax,lname,lpath);
      lmod:=GetTL2Mod(lmod);

      sgMovies.Objects[0,i+1]:=TObject(IntPtr(i));
      sgMovies.Objects[1,i+1]:=TObject(IntPtr(lmax));

      sgMovies.Cells[colTitle,i+1]:=ltitle;
      sgMovies.Cells[colViews,i+1]:=IntToStr(aSGame.Movies[i].value);
      sgMovies.Cells[colPath ,i+1]:=lpath;
      sgMovies.Cells[colID   ,i+1]:=IntToStr(aSGame.Movies[i].id);
      sgMovies.Cells[colName ,i+1]:=lname;
      sgMovies.Cells[colMod  ,i+1]:=lmod;
    end;
    sgMovies.Row:=1;
  end;
  sgMovies.EndUpdate;
  bbUpdate.Enabled:=false;
end;

end.
