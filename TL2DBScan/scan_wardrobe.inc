{%REGION Wardrobe}

{NOTE: TL1 don't have it}

type
  twardrobeinfo = record
    id    :string;
    name  :string;
    atype :string;
    gender:string;
  end;

function AddWardrobeToBase(ams:pointer; var adata:twardrobeinfo):boolean;
var
  lmodid,lSQL:string;
begin
  result:=false;

  lmodid:=CheckIdForMod(ams,'wardrobe', adata.id);
  if lmodid<>'' then
  begin
    lSQL:='REPLACE INTO wardrobe (id, name, type, gender, modid) VALUES ('+
        adata.id+', '+FixedText(adata.name)+', '+FixedText(adata.atype)+', '''+adata.gender+
        ''', '+lmodid+')';

    result:=ExecuteDirect(PModScanner(ams)^.db,lSQL);
  end;
end;

function ScanWardrobeNode(ams:pointer; anode:pointer):integer;
var
  pp,lnode:pointer;
  pcw:PWideChar;
  ls:string;
  ldata:twardrobeinfo;
  i,j:integer;
begin
  result:=0;

  for j:=0 to GetChildCount(anode)-1 do
  begin
    pp:=GetChild(anode,j);
    if (GetNodeType(pp)=rgGroup) and
       (CompareWide(GetNodeName(pp),'FEATURE')=0) then
    begin
      for i:=0 to GetChildCount(pp)-1 do
      begin
        lnode:=GetChild(pp,i);
        pcw:=GetNodeName(lnode);
        if      CompareWide(pcw,'NAME' )=0 then ldata.name :=AsString(lnode)
        else if CompareWide(pcw,'TYPE' )=0 then ldata.atype:=AsString(lnode)
        else if CompareWide(pcw,'GUID' )=0 then Str(AsInteger64(lnode),ldata.id)
        else if CompareWide(pcw,'CLASS')=0 then
        begin
          ls:=asString(lnode);
          ldata.gender:=UpCase(ls[length(ls)]);
        end;
      end;

      if not AddWardrobeToBase(ams,ldata) then
      begin
        if RGDebugLevel=dlDetailed then
          RGLog.Add('can''t update '+ldata.name);
      end
      else
        inc(result);
    end;
  end;

end;

function ProcessWardrobe(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):integer;
var
  p:pointer;
  i:int64;
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
      i:=ScanWardrobeNode(aparam,p);

      if i=0 then if RGDebugLevel=dlDetailed then RGLog.Add('can''t update '+aname);
//      if i=-1 then if RGDebugLevel=dlDetailed then RGLog.Add('don''t added ' +aname);
      if i>0 then result:=i;

      DeleteNode(p);
    end;

    RGLog.Reserve('');
  end;
end;

function CheckNameWard(const adir,aname:string; aparam:pointer):integer;
begin
  // no need to check subdirs content and don't increase count
  if (Length(adir)>15) or (aname[Length(aname)]='/') then exit(sres_nocheck+sres_fail);

	result:=1;
end;

function ScanWardrobe(ams:pointer):integer;
begin
  if PModScanner(ams)^.gamever=verTL1 then
  begin
    RGLog.Add('TL1 don''t support Wardrobe setup');
    exit(0);
  end;

  if RGDebugLevel<>dlNone then RGLog.Add('Scanning wardrobe');
  result:=DoRGScan(PModScanner(ams)^.scan, 'MEDIA/WARDROBE/', @ProcessWardrobe, @CheckNameWard);
  if RGDebugLevel<>dlNone then RGLog.Add(IntToStr(result)+' records added');
end;

function CreateWardrobeTable(adb:PSQLite3):boolean;
begin
  if not IsTableExists(adb,'wardrobe') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE wardrobe ('+
      '    id     INTEGER PRIMARY KEY,'+
      '    name   TEXT,'+
      '    title  TEXT,'+
      '    modid  TEXT,'+
      '    type   TEXT,'+
      '    gender CHAR );')
  else
    result:=true;
end;

{%ENDREGION}
