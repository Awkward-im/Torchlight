{%REGION Props}

type
  TPropsInfo = object(TBaseUnitInfo)
    quest :string;
    states:integer;
    loop  :integer;
  end;

function AddPropToBase(ams:pointer; const api:TPropsInfo):boolean;
var
  lmodid,lSQL:string;
begin
  result:=false;

  lmodid:=CheckIdForMod(ams,'props', api.id);
  if lmodid<>'' then
  begin
    lSQL:='REPLACE INTO props ('+DefUnitColumns+', quest, states, loop, modid) VALUES ('+
        GetDefUnitValues(ams,@api)+', '+api.quest+', '+IntToStr(api.states)+', '+
        IntToStr(api.loop)+', '+lmodid+')';

    result:=ExecuteDirect(PModScanner(ams)^.db,lSQL);
  end;
end;

function AddPropNode(ams:pointer; anode:pointer; isquest:boolean; const fname:string):boolean;
var
  lpi:TPropsInfo;
  lnode:pointer;
  pcw:PWideChar;
  i:integer;
begin
  FillChar(lpi,SizeOf(lpi),0);

  for i:=0 to GetChildCount(anode)-1 do
  begin
    lnode:=GetChild(anode,i);
    if not SetUnitInfo(lnode,@lpi) then
    begin
      pcw:=GetNodeName(lnode);
      if CompareWide(pcw,'LOOPTYPE')=0 then
      begin
        pcw:=AsString(lnode);
        if      CompareWideI(pcw,'Cycle'         )=0 then lpi.loop:=1
        else if CompareWideI(pcw,'Back and Forth')=0 then lpi.loop:=2
//        else if CompareWideI(pcw,'No loop'       )=0 then lpi.loop:=0
      end
      else if CompareWide(pcw,'MAXSTATES')=0 then lpi.states:=AsInteger(lnode);
    end;
  end;
  if isquest then lpi.quest:='1' else lpi.quest:='0';
  lpi.fname:=FixFileExt(fname);

  result:=AddPropToBase(ams,lpi);
end;

function ProcessProps(
          abuf:PByte; asize:integer;
          const adir,aname:string;
          aparam:pointer):integer;
var
  p:pointer;
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
      if AddPropNode(aparam,p,Pos('MEDIA/UNITS/PROPS/QUESTPROPS',adir)>0,adir+aname) then
        result:=1
      else if RGDebugLevel=dlDetailed then
        RGLog.Add('can''t update '+aname);

      DeleteNode(p);
    end;

    RGLog.Reserve('');
  end;
end;

function ScanProps(ams:pointer):integer;
begin
  if RGDebugLevel<>dlNone then RGLog.Add('Scanning props');
  result:=DoRGScan(PModScanner(ams)^.scan, 'MEDIA/UNITS/PROPS', @ProcessProps);
  if RGDebugLevel<>dlNone then RGLog.Add(IntToStr(result)+' records added');
end;

function CreatePropsTable(adb:PSQLite3):boolean;
begin
  if not IsTableExists(adb,'props') then
    result:=ExecuteDirect(adb,
      'CREATE TABLE props ('+
      DefUnitDDL+
      '    quest  INTEGER (1),'+
      '    states INTEGER,'+
      '    loop   INTEGER);')
  else
    result:=true;
end;

{%ENDREGION}
