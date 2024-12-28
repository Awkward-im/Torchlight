{%REGION Movies}

{NOTE: TL1 don't have it}

function AddMovieToBase(ams:pointer;  aId:int64;
     const aname, atitle, apath:string; aviews:integer):integer;
var
  lmodid,lSQL,sid:string;
begin
  Str(aid,sid);
  lmodid:=CheckIdForMod(ams,'movies', sid);
  if lmodid<>'' then
  begin
    lSQL:='REPLACE INTO movies (id, name, title, path, views, modid) VALUES ('+
        sid+', '+FixedText(aname)+', '+FixedText(atitle)+', '+FixedText(apath)+
        ', '+IntToStr(aviews)+', '+lmodid+')';

    if ExecuteDirect(PModScanner(ams)^.db,lSQL) then
      result:=1
    else
      result:=0;
  end
  else
    result:=-1;
end;

function AddMovieNode(ams:pointer; anode:pointer):integer;
var
  lnode, llnode:pointer;
  pcw:PWideChar;
  lname,ltitle,lpath:string;
  lid:int64;
  lcnt,i,j,lviews:integer;
begin
  result:=0;
  lcnt:=0;

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
    begin
      j:=AddMovieToBase(ams,lid,lname,ltitle,lpath,lviews);
           if j>0 then inc(result)
      else if j<0 then inc(lcnt);
    end;
  end;
  if (result=0) and (lcnt>0) then result:=-lcnt;
end;

function ScanMovies(ams:pointer):integer;
var
  p:pointer;
begin
  result:=sres_fail;

  if PModScanner(ams)^.gamever=verTL1 then
  begin
    RGLog.Add('TL1 don''t support Movie clips setup');
    exit;
  end;

  LoadFile(ams,'MEDIA/MOVIES/MOVIES.DAT',p);
  if p<>nil then
  begin
    result:=AddMovieNode(ams,p);
    if result=0 then
    begin
      result:=sres_fail;
      if RGDebugLevel=dlDetailed then RGLog.Add('can''t update MOVIES.DAT');
    end;

    DeleteNode(p);
  end;
end;

function CreateMoviesTable(adb:PSQLite3):boolean;
begin
  if not IsTableExists(adb,'movies') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE movies ('+
      '  id    INTEGER PRIMARY KEY,'+
      '  name  TEXT,'+
      '  title TEXT,'+
      '  views INTEGER (1) DEFAULT (1),'+
      '  path  TEXT,'+
      '  modid TEXT);')
  else
    result:=true;
end;

{%ENDREGION Movies}
