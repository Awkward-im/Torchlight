unit formMovies;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, Buttons,
  tl2save,tl2types;

type

  { TfmMovies }

  TfmMovies = class(TForm)
    bbUpdate: TBitBtn;
    sgMovies: TStringGrid;
    procedure bbUpdateClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure sgMoviesEditingDone(Sender: TObject);
  private
    FMovies:TL2IdValList;

  public
    procedure FillInfo(aSGame:TTL2SaveFile);

  end;

var
  fmMovies: TfmMovies;

implementation

{$R *.lfm}

uses
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
  lviews:=StrToIntDef(sgMovies.Cells[colViews,sgMovies.Row],0);
  if (lviews<0) or
     (lviews>integer(sgMovies.Objects[1,sgMovies.Row])) then lviews:=0;
  sgMovies.Cells[colViews,sgMovies.Row]:=IntToStr(lviews);
end;

procedure TfmMovies.bbUpdateClick(Sender: TObject);
var
  i:integer;
begin
  for i:=1 to sgMovies.RowCount do
  begin
    fmovies[integer(sgMovies.Objects[0,i])].value:=
        StrToInt(sgMovies.Cells[colViews,i]);
  end;
end;

procedure TfmMovies.FormCreate(Sender: TObject);
begin

end;

procedure TfmMovies.FillInfo(aSGame:TTL2SaveFile);
var
  lmodid:TL2ID;
  lmax,i:integer;
  lmod,lname,ltitle,lpath:string;
begin
  FMovies:=aSGame.Movies;

  sgMovies.BeginUpdate;
  sgMovies.Clear;
  sgMovies.RowCount:=Length(FMovies)+1;
  if Length(FMovies)>0 then
  begin
    for i:=0 to High(FMovies) do
    begin
      ltitle:=GetTL2Movie(FMovies[i].id,lmodid,lmax,lname,lpath);
      if lmodid<>TL2ID(-1) then
        lmod:=GetTL2Mod(lmodid)
      else
        lmod:='';

      sgMovies.Objects[0,i+1]:=TObject(i);
      sgMovies.Objects[1,i+1]:=TObject(lmax);

      sgMovies.Cells[colTitle,i+1]:=ltitle;
      sgMovies.Cells[colViews,i+1]:=IntToStr(FMovies[i].value);
      sgMovies.Cells[colPath ,i+1]:=lpath;
      sgMovies.Cells[colID   ,i+1]:=IntToStr(FMovies[i].id);
      sgMovies.Cells[colName ,i+1]:=lname;
      sgMovies.Cells[colMod  ,i+1]:=lmod;
    end;
    sgMovies.Row:=1;
  end;
  sgMovies.EndUpdate;
end;

end.
