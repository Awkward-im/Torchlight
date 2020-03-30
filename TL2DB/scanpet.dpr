uses
  sysutils,
  classes,
  sqlite3conn, sqldb,
  tl2db;

procedure CycleDir(sl:TStringList; const adir:AnsiString);
var
  sr:TSearchRec;
  lname:AnsiString;
begin
  if FindFirst(adir+'\*.*',faAnyFile and faDirectory,sr)=0 then
  begin
    repeat
      lname:=adir+'\'+sr.Name;
      if (sr.Attr and faDirectory)=faDirectory then
      begin
        if (sr.Name<>'.') and (sr.Name<>'..') then
;//          CycleDir(sl, lname);
      end
      else
      begin
        if UpCase(ExtractFileExt(lname))='.DAT' then
        begin
          sl.Add(lname);
        end;
      end;
    until FindNext(sr)<>0;
    FindClose(sr);
  end;
end;

type
  tpetinfo = record
    id:QWord;
    title:string;
    name:string;
    atype:integer;
    scale:string{single};
    textures:integer;
  end;

const
  c  = '<STRING>UNIT_GUID:';
  c1 = '<TRANSLATE>DISPLAYNAME:';
  c2 = '<STRING>UNITTYPE:STARTING PET';
  c3 = '<STRING>UNITTYPE:PET';
  c4 = '<STRING>NAME:';
  c5 = '<FLOAT>SCALE:';
  c6 = '[TEXTURE_OVERRIDE_LIST]';
  c7 = '<STRING>TEXTURE:';

function ReadPetInfo(const fname:string; var apet:TPetInfo):boolean;
var
  ls:string;
  sl:TStringList;
  k,i,j:integer;

begin
  result:=true;
  sl:=TStringList.Create;
  sl.LoadFromFile(fname);

  apet.textures:=0;
  apet.atype:=-1;

  for i:=0 to sl.Count-1 do
  begin
    ls:=sl[i];
    if  pos(c2,ls)>0  then apet.atype:=0;
    if  pos(c3,ls)>0  then apet.atype:=1;
    if (pos(c6,ls)>0) and (apet.atype=0) then
    begin
      j:=i+1;
      while (j<sl.count) and (pos(c7,sl[j])>0) do
      begin
        inc(apet.textures);
        inc(j);
      end;
      break;
    end;

    k:=pos(c5,ls);
    if k>0 then
    begin
      apet.scale := {StrToFloat}(Copy(ls,k+Length(c5)));
    end;
    k:=pos(c4,ls);
    if k>0 then
    begin
      apet.name := Copy(ls,k+Length(c4));
    end;
    k:=pos(c,ls);
    if k>0 then
    begin
      apet.id := QWord(StrToInt64(Copy(ls,k+Length(c))));
    end;
    k:=pos(c1,ls);
    if k>0 then
    begin
      apet.title := Copy(ls,k+Length(c1));
    end;

  end;
  sl.Free;
end;

var
  SQLConnection: TSQLite3Connection = nil;
  SQLQuery: TSQLQuery;
  SQLTransaction: TSQLTransaction;

procedure InitDatabase;
begin
  SQLConnection := TSQLite3Connection.Create(nil);
//  Connected := False;
//  LoginPrompt := False;
//  KeepConnection := False;
  SQLConnection.Transaction := SQLTransaction;

  SQLTransaction := TSQLTransaction.Create(nil);
//  Active := False;
  SQLTransaction.Database := SQLConnection;

  SQLQuery := TSQLQuery.Create(nil);
  SQLQuery.Options     := [sqoAutoCommit];
  SQLQuery.Database    := SQLConnection;
  SQLQuery.Transaction := SQLTransaction;

end;

function OpenDatabase(const name:string):boolean;
var
  newFile:boolean;
begin
  if SQLConnection = nil then
    InitDatabase;

  SQLConnection.Close;
  SQLConnection.DatabaseName := name;
  newFile := not FileExists(SQLConnection.DatabaseName);
  SQLConnection.Open;

  if newFile then
  begin
//    CloseDatabase; //??
  end
  else
  begin
  end;
  result := not newFile;
end;

procedure CloseDatabase;
begin
  if SQLConnection<>nil then
  begin
    SQLQuery.Close;
    SQLTransaction.Active := False;
    SQLConnection.Connected := False;

    SQLQuery.Free;
    SQLTransaction.Free;
    SQLConnection.Free;
    SQLConnection := nil;
  end;
end;

var
  sl,slm:TStringList;
  lpet:tpetinfo;
  i:integer;
begin
  sl :=TStringList.Create;
  slm:=TStringList.Create;

  CycleDir(sl,'.');

  OpenDatabase('tl2db.db');
  writeln(sl.count);
  if sl.Count>0 then
  begin
    SQLTransaction.StartTransaction;
    SQLQuery.SQL.Text:='INSERT INTO Pets (id,title,name,pettype,scale,textures) '+
                       ' VALUES (:id,:title,:name,:pettype,:scale,:textures)';
    for i:=0 to sl.Count-1 do
    begin
      if ReadPetInfo(sl[i],lpet) then
      begin
        SQLQuery.Params.ParamByName('id'      ).AsLargeInt:=int64(lpet.id);
        SQLQuery.Params.ParamByName('title'   ).AsString :=lpet.title;
        SQLQuery.Params.ParamByName('name'    ).AsString :=lpet.name;
        SQLQuery.Params.ParamByName('pettype' ).AsInteger:=(lpet.atype);
        SQLQuery.Params.ParamByName('scale'   ).AsString :=(lpet.scale);
        SQLQuery.Params.ParamByName('textures').AsSmallInt:=smallint(lpet.textures);
        SQLQuery.ExecSQL;

        slm.Add(IntToHex(lpet.id,16)+#9+lpet.title+#9+lpet.name+#9+
                IntToStr(lpet.atype)+#9+lpet.scale+#9+IntToStr(lpet.textures));
      end;
    end;
    SQLTransaction.Commit;
//    slm.SaveToFile('petlist.csv');
  end;

  CloseDatabase;
  sl.Free;
  slm.Free;
end.
