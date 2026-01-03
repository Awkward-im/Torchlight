{%REGION Sounds}
type
  PSndArray = ^TSndArray;
  TSndArray = array [0..31] of PWideChar;

function AddSoundToBase(ams:pointer; var aname:string; aId:int64;
          const afiles:TSndArray; alen:integer):integer;
var
  lmodid,sid:string;
begin
  Str(aid,sid);
  lmodid:=CheckIdForMod(ams,'sounds', sid);
  if lmodid<>'' then
  begin
    if ExecuteDirect(PModScanner(ams)^.db,
      'REPLACE INTO sounds (id, name, files, modid) VALUES ('+
          sid+', ?1, ?2, '+lmodid+')',[aname,lfiles]) then
      result:=1
    else
      result:=0;
  end
  else
    result:=-1;
end;

function AddSoundNode(ams:pointer; anode:pointer; const fname:string):integer;
var
  lsnd:TSndArray;
  lsound,lnode,fnode:pointer;
  pcw:PWideChar;
  name:string;
  lid:int64;
  lcnt,k,i,j:integer;
begin
  result:=0;
  if CompareWide(GetNodeName(anode),'SOUNDDATA')=0 then
  begin
    for k:=0 to GetChildCount(anode)-1 do
    begin
      lsound:=GetChild(anode,k);
      if (GetNodeType(lsound)=rgGroup) and
         (CompareWide(GetNodeName(anode),'SOUND')=0) then
      begin
        lcnt:=0;
        for i:=0 to GetChildCount(lsound)-1 do
        begin
          lnode:=GetChild(lsound,i);

          if GetNodeType(lnode)<>rgGroup then
          begin
            pcw:=GetNodeName(lnode);
                 if CompareWide(pcw,'NAME'  )=0 then name :=AsString   (lnode)
            else if CompareWide(pcw,'GUID'  )=0 then lid  :=AsInteger64(lnode)
          end
          else if CompareWide(pcw,'FILES')=0 then
          begin
            for j:=0 to GetChildCount(lnode)-1 do
            begin
              fnode:=GetChild(lnode,j);
              if CompareWide(GetNodeName(fnode),'FILE')=0 then
              begin
                lsnd[lcnt]:=AsString(fnode);
                inc(lcnt);
              end;
            end;
          end;
        end;
        result:=result+ABS(AddSoundToBase(ams,name,lid,lsnd,lcnt));
      end;
    end;
  end;

end;

function ProcessSounds(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):cardinal;
var
  p:pointer;
  lres:integer;
begin
  result:=sres_fail;

  if asize>0 then
  begin
    RGLog.Reserve('Scan '+adir+aname);

    p:=ParseTextMem(abuf);
    if p=nil then
      p:=ParseDatMem(abuf);
    
    if p<>nil then
    begin
      lres:=AddSoundNode(aparam,p,aname);
           if lres>0 then result:=1
      else if lres<0 then result:=0
      else if RGDebugLevel=dlDetailed then
        RGLog.Add('can''t update '+aname);

      DeleteNode(p);
    end;

    RGLog.Reserve('');
  end;
end;

function ScanSounds(ams:pointer):integer;
begin
  if RGDebugLevel<>dlNone then RGLog.Add('Scanning sounds');
  result:=DoRGScan(PModScanner(ams)^.scan, 'MEDIA/SOUNDS', @ProcessSounds);
  if RGDebugLevel<>dlNone then RGLog.Add(IntToStr(result)+' records added');
end;

{
  1 - full file path
  2 - dir is in table, name as is
  3 - dir is in table, name is in table
  4 - dir+name in table too, index here
}
function CreateSoundsTable(adb:PSQLite3; aver:integer):boolean;
begin
  if not IsTableExists(adb,'dicsdirs') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE dicdirs ('+
      '  id   INTEGER PRIMARY KEY AUTOINCREMENT,'+
      '  value TEXT);')
  if not IsTableExists(adb,'dicsfiles') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE dicfiles ('+
      '  id    INTEGER PRIMARY KEY AUTOINCREMENT,'+
      '  iddir INTEGER'+
      '  value TEXT);')

  if not IsTableExists(adb,'sounds') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE sounds ('+
      '    id       INTEGER PRIMARY KEY,'+
      '    name     TEXT,'+
      '    files    TEXT,'+
      '    category TEXT,'+
      '    modid    TEXT );')
  else
    result:=true;
end;
{%ENDREGION Sounds}
