{%REGION Movies}
function AddMovieToBase(ams:pointer;  aId:int64;
     const aname, atitle, apath:string; aviews:integer):boolean;
var
  lmodid,lSQL,sid:string;
begin
  result:=false;

  Str(aid,sid);
  lmodid:=CheckForMod(ams,'movies', sid, PModScanner(ams)^.FModId);
  if lmodid<>'' then
  begin
    lSQL:='REPLACE INTO movies (id, name, title, path, views, modid) VALUES ('+
        sid+', '+FixedText(aname)+', '+FixedText(atitle)+', '+FixedText(apath)+
        ', '+IntToStr(aviews)+', '+lmodid+')';

    result:=ExecuteDirect(PModScanner(ams)^.db,lSQL);
  end;
end;

function AddMovieNode(ams:pointer; anode:pointer):integer;
var
  lnode, llnode:pointer;
  pcw:PWideChar;
  lname,ltitle,lpath:string;
  lid:int64;
  i,j,lviews:integer;
begin
  result:=0;

  for i:=0 to GetChildCount(anode)-1 do
  begin
    lnode:=GetChild(anode,i); // 'MOVIE'
    ltitle:='';
    lid   :=-1;
    lviews:=1;

    for j:=0 to GetChildCount(lnode)-1 do
    begin
      llnode:=GetChild(lnode,j);

      pcw:=GetNodeName(llnode);
      if      CompareWide(pcw,'NAME'       )=0 then lname :=AsString   (llnode)
      else if CompareWide(pcw,'GUID'       )=0 then lid   :=AsInteger64(llnode)
      else if CompareWide(pcw,'DISPLAYNAME')=0 then ltitle:=AsString   (llnode)
      else if CompareWide(pcw,'PATH'       )=0 then lpath :=AsString   (llnode)
      else if CompareWide(pcw,'MAXPLAYS'   )=0 then lviews:=AsInteger  (llnode);
    end;

    if lid<>-1 then
      if AddMovieToBase(ams,lid,lname,ltitle,lpath,lviews) then inc(result);
  end;

end;

function ScanMovies(ams:pointer):integer;
var
  p:pointer;
begin
  result:=0;

  LoadFile(ams,'MEDIA/MOVIES/MOVIES.DAT',p);
  if p<>nil then
  begin
    if AddMovieNode(ams,p)>0 then
      result:=1
    else
    begin
      RGLog.Add('can''t update MOVIES.DAT');
      result:=0;
    end;
    DeleteNode(p);
  end;
end;

function CreateMoviesTable(adb:PSQLite3):boolean;
begin
  if not IsTableExists(adb,'movies') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE movies ('+
      '  id    INTEGER     PRIMARY KEY,'+
      '  name  TEXT,'+
      '  title TEXT,'+
      '  views INTEGER (1) DEFAULT (1),'+
      '  path  TEXT,'+
      '  modid TEXT);');
end;

{%ENDREGION Movies}
