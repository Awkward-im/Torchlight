{%REGION Wardrobe}

{TODO: gender from class info (not all names ends from M and F)}
{NOTE: TL1 don't have it}

type
  twardrobeinfo = record
    id    :string;
    name  :string;
    atype :string;
    gender:string;
  end;

function AddWardrobeToBase(ams:pointer; var adata:twardrobeinfo):integer;
var
  lmodid,lSQL:string;
begin
  lmodid:=CheckIdForMod(ams,'wardrobe', adata.id);
  if lmodid<>'' then
  begin
    lSQL:='REPLACE INTO wardrobe (id, name, type, gender, modid) VALUES ('+
        adata.id+', '+FixedText(adata.name)+', '+FixedText(adata.atype)+', '''+adata.gender+
        ''', '+lmodid+')';

    if ExecuteDirect(PModScanner(ams)^.db,lSQL) then
      result:=1
    else
      result:=0;
  end
  else
    result:=-1;
end;

function ScanWardrobeNode(ams:pointer; anode:pointer):integer;
var
  pp,lnode:pointer;
  pcw:PWideChar;
  ls:string;
  ldata:twardrobeinfo;
  i,j,lcnt:integer;
begin
  result:=0;
  lcnt:=0;

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
          ls:=UpCase(FastWideToStr(asString(lnode)));
          ldata.gender:=ls[length(ls)];
          if not (ldata.gender[1] in ['F','M']) then
            if Pos('_F',ls)>0 then ldata.gender:='F'
            else ldata.gender:='M';
        end;
      end;

      i:=AddWardrobeToBase(ams,ldata);
           if i>0 then inc(result)
      else if i<0 then inc(lcnt)
      else if RGDebugLevel=dlDetailed then
        RGLog.Add('can''t update '+ldata.name);
    end;
  end;
  if (result=0) and (lcnt>0) then result:=-lcnt;
end;

function ProcessWardrobe(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):cardinal;
var
  p:pointer;
  i:integer;
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

           if i>0 then result:=i
      else if i<0 then result:=0
      else if RGDebugLevel=dlDetailed then
        RGLog.Add('can''t update '+aname);

      DeleteNode(p);
    end;

    RGLog.Reserve('');
  end;
end;

function CheckNameWard(const adir,aname:string; aparam:pointer):cardinal;
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

function CreateWardrobeTable(adb:PSQLite3; aver:integer):boolean;
begin
  if aver=verTL1 then exit(false);

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
