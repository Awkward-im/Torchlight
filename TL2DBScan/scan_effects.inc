{%REGION Effects}

type
  TEffectInfo = record
    name     : PUnicodeChar;
    gooddes  : PUnicodeChar;
    gooddesot: PUnicodeChar;
    baddes   : PUnicodeChar;
    baddesot : PUnicodeChar;
    precision: integer;                    // display precision for values
    values: array [1..5] of PUnicodeChar;  // affix parameter names
  end;

{TODO: add modid field?}
function AddEffectToBase(ams:pointer; aid:integer; const aefi:TEffectInfo):boolean;
begin
  result:=false;

  result:=ExecuteDirect(PModScanner(ams)^.db,
    'INSERT OR FAIL INTO effects (id, name, gooddes, gooddesot, baddes, baddesot, precision,'+
        ' value1, value2, value3, value4, value5) VALUES ('+
      IntToStr(aid)+', ?1, ?2, ?3, ?4, ?5, '+IntToStr (aefi.precision)+', ?6, ?7, ?8, ?9, ?10)',
      [aefi.name,aefi.gooddes,aefi.gooddesot,aefi.baddes,aefi.baddesot,
       aefi.values[1],aefi.values[2],aefi.values[3],aefi.values[4],aefi.values[5]]);
end;

function AddEffectNode(ams:pointer; anode:pointer):integer;
var
  lefi:TEffectInfo;
  lnode, llnode:pointer;
  pcw:PWideChar;
  i,j,lmask:integer;
begin
  result:=0;

  for i:=0 to GetChildCount(anode)-1 do
  begin
    lnode:=GetChild(anode,i); // 'EFFECT'
    lmask     :=0;
    lefi.name     :=nil;
    lefi.gooddes  :=nil;
    lefi.gooddesot:=nil;
    lefi.baddes   :=nil;
    lefi.baddesot :=nil;
    lefi.precision:= 0;
    lefi.values[1]:=nil;
    lefi.values[2]:=nil;
    lefi.values[3]:=nil;
    lefi.values[4]:=nil;
    lefi.values[5]:=nil;

    for j:=0 to GetChildCount(lnode)-1 do
    begin
      llnode:=GetChild(lnode,j);

      pcw:=GetNodeName(llnode);
      if      CompareWide(pcw,'NAME')=0 then
      begin
        lefi.name:=AsString(llnode);
        lmask:=lmask or 1;
      end
      else if CompareWide(pcw,'GOODDES')=0 then
      begin
        lefi.gooddes:=AsTranslate(llnode);
        lmask:=lmask or 2;
      end
      else if CompareWide(pcw,'GOODDESOT')=0 then
      begin
        lefi.gooddesot:=AsTranslate(llnode);
        lmask:=lmask or 4;
      end
      else if CompareWide(pcw,'BADDES')=0 then
      begin
        lefi.baddes:=AsTranslate(llnode);
        lmask:=lmask or 8;
      end
      else if CompareWide(pcw,'BADDESOT')=0 then
      begin
        lefi.baddesot:=AsTranslate(llnode);
        lmask:=lmask or 16;
      end

      else if CompareWide(pcw,'DISPLAYPRECISION')=0 then
      begin
        lefi.precision:=AsInteger(llnode);
      end

      else if CompareWide(pcw,'VALUE1')=0 then
      begin
        pcw:=AsString(llnode);
        if CompareWide(pcw,'NA')<>0 then lefi.values[1]:=AsString(llnode);
      end
      else if CompareWide(pcw,'VALUE2')=0 then
      begin
        pcw:=AsString(llnode);
        if CompareWide(pcw,'NA')<>0 then lefi.values[2]:=AsString(llnode);
      end
      else if CompareWide(pcw,'VALUE3')=0 then
      begin
        pcw:=AsString(llnode);
        if CompareWide(pcw,'NA')<>0 then lefi.values[3]:=AsString(llnode);
      end
      else if CompareWide(pcw,'VALUE4')=0 then
      begin
        pcw:=AsString(llnode);
        if CompareWide(pcw,'NA')<>0 then lefi.values[4]:=AsString(llnode);
      end
      else if CompareWide(pcw,'VALUE5')=0 then
      begin
        pcw:=AsString(llnode);
        if CompareWide(pcw,'NA')<>0 then lefi.values[5]:=AsString(llnode);
      end;
{
      if lmask=31 then
      begin
        if AddEffectToBase(ams,i,lefi) then inc(result);
        break;
      end;
    end;
}
    end;
    // let id start from 1
    if AddEffectToBase(ams,i+1,lefi) then inc(result);

  end;

end;

function ScanEffects(ams:pointer):integer;
var
  p:pointer;
begin
  if RGDebugLevel<>dlNone then RGLog.Add('Scanning effects');

  result:=sres_fail;

  LoadFile(ams,'MEDIA/EFFECTSLIST.DAT',p);
  if (p=nil) and (PModScanner(ams)^.gamever=verTL1) then
    LoadFile(ams,'MEDIA/EFFECTSLIST.DAT.ADM',p);

  if p<>nil then
  begin
    result:=AddEffectNode(ams,p);
    if result=0 then
    begin
      if RGDebugLevel=dlDetailed then RGLog.Add('can''t update EFFECTSLIST.DAT');
    end
    else
      if RGDebugLevel<>dlNone then RGLog.Add(IntToStr(result)+' records added');

    DeleteNode(p);
  end;
end;

function CreateEffectsTable(adb:PSQLite3; aver:integer):boolean;
begin
  if not IsTableExists(adb,'effects') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE effects ('+
      '  id        INTEGER PRIMARY KEY,'+
      '  name      TEXT,'+
      '  gooddes   TEXT,'+
      '  gooddesot TEXT,'+
      '  baddes    TEXT,'+
      '  baddesot  TEXT,'+
      '  precision INTEGER,'+
      '  value1    TEXT,'+
      '  value2    TEXT,'+
      '  value3    TEXT,'+
      '  value4    TEXT,'+
      '  value5    TEXT);')
  else
    result:=true;
end;

{%ENDREGION Effects}
