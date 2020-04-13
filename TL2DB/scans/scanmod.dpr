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
          CycleDir(sl, lname);
      end
      else
      begin
        if UpCase(ExtractFileExt(lname))='.MOD' then
        begin
          sl.Add(lname);
        end;
      end;
    until FindNext(sr)<>0;
    FindClose(sr);
  end;
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
  lmod:TTL2ModInfo;
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
    SQLQuery.SQL.Text:='INSERT INTO Mods (id,title,version,gamever,author,descr,website,download) '+
                       ' VALUES (:id,:title,:version,:gamever,:author,:descr,:website,:download)';
    for i:=0 to sl.Count-1 do
    begin
      if ReadModInfo(sl[i],lmod) then
      begin
        SQLQuery.Params.ParamByName('id'      ).AsLargeInt:=int64(lmod.modid);
        SQLQuery.Params.ParamByName('title'   ).AsString  :=lmod.title;
        SQLQuery.Params.ParamByName('version' ).AsInteger :=lmod.modver;
        SQLQuery.Params.ParamByName('gamever' ).AsLargeInt:=int64(lmod.gamever);
        SQLQuery.Params.ParamByName('author'  ).AsString  :=lmod.author;
        SQLQuery.Params.ParamByName('descr'   ).AsString  :=lmod.descr;
        SQLQuery.Params.ParamByName('website' ).AsString  :=lmod.website;
        SQLQuery.Params.ParamByName('download').AsString  :=lmod.download;
        SQLQuery.ExecSQL;

        slm.Add(IntToHex(lmod.modid,16)+#9+lmod.title+#9+IntToStr(lmod.modver)+
             #9+IntToHex(lmod.gamever,16));
      end;
    end;
    SQLTransaction.Commit;
    //    slm.SaveToFile('modlist.csv');
  end;

  CloseDatabase;
  sl.Free;
  slm.Free;
end.
