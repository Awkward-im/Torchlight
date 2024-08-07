{$IFDEF Interface}

type
  tPetArray = array of record
    id   :TRGID;
    name :string;
    title:string;
    scale:single;
    icon :string;
  end;

function GetTL2Pet (const aid:TRGID; out amods:string):string; overload;
function GetTL2Pet (const aid:TRGID                  ):string; overload;

function GetPetMods(const aid:TRGID):string;
function GetPetIcon(const aid:TRGID):string;

procedure GetPetList(out alist:tPetArray);
function  GetDefaultPet:TRGID;

{$ELSE}

const
  dbPetTable = 'pets';

const
  DefaultPets: tPetArray = (
    (id:-8880591480184383566; name:'Pet_Cat'        ; title:'Cat'        ; scale:0.65; icon:'lynxicon'),
    (id:-8742058185063171412; name:'Pet_Jackalbeast'; title:'Jackalbeast'; scale:0.75; icon:''),
    (id:-6861078633348114419; name:'Pet_Hawk'       ; title:'Hawk'       ; scale:1   ; icon:'hawkicon'),
    (id:-6861072635378114419; name:'Pet_Flyer'      ; title:'Swampflyer' ; scale:1   ; icon:''),
    (id:-6082309300095414029; name:'Pet_Falcor'     ; title:'Papillon'   ; scale:0.8 ; icon:'falcoricon'),
    (id:-4272058185063171412; name:'Pet_Crab'       ; title:'Crab'       ; scale:1   ; icon:''),
    (id:-2472058185064571412; name:'Pet_Wolf'       ; title:'Wolf'       ; scale:0.75; icon:'dogicon'),
    (id:-2472058185064571327; name:'Pet_BigCat'     ; title:'Panther'    ; scale:1   ; icon:'bigcaticon'),
    (id:-2472058185032171412; name:'Pet_Warbeast'   ; title:'Warbeast'   ; scale:0.8 ; icon:''),
    (id:-2412341850671171412; name:'Pet_Molebeast'  ; title:'Molebeast'  ; scale:1.15; icon:''),
    (id:-1672582398143053873; name:'Pet_Alpaca'     ; title:'Alpaca'     ; scale:1   ; icon:'alpacaicon'),
    (id:-1144795368701180224; name:'Pet_Chakawary'  ; title:'Chakawary'  ; scale:0.75; icon:'chakawaryicon'),
    (id:-18242231495209399  ; name:'Pet_HeadcrabA'  ; title:'Headcrab'   ; scale:1   ; icon:'headcrabicon'),
    (id:2236371573517850133 ; name:'Pet_torso'      ; title:'Torso'      ; scale:1.25; icon:''),
    (id:2846508072355823983 ; name:'Pet_Bulldog'    ; title:'Bulldog'    ; scale:1   ; icon:'bulldogicon'),
    (id:2947367154991955139 ; name:'Pet_PandaA'     ; title:'Panda'      ; scale:1   ; icon:'pandaicon'),
    (id:6085265292355965406 ; name:'Pet_Ferret'     ; title:'Ferret'     ; scale:1   ; icon:'ferreticon'),
    (id:6212525112683485562 ; name:'Pet_Deer'       ; title:'Stag'       ; scale:1   ; icon:'deericon'),
    (id:6516037093941808301 ; name:'Pet_Owl'        ; title:'Owl'        ; scale:1   ; icon:'owlicon'),
    (id:7002609406216574240 ; name:'Pet_Spider'     ; title:'Spider'     ; scale:0.8 ; icon:''),
    (id:7846508072355823983 ; name:'Pet_HoneyBadger'; title:'Badger'     ; scale:1   ; icon:'badgericon')
  );

function GetTL2Pet(const aid:TRGID; out amods:string):string;
var
  lname:string;
  i:integer;
begin
  if db=nil then
  begin
    amods:='';
    for i:=0 to High(DefaultPets) do
    begin
      if DefaultPets[i].id=aid then
      begin
        result:=DefaultPets[i].title;
        exit;
      end;
    end;
    result:='';
  end
  else
    result:=GetById(aid,dbPetTable,'',amods,lname);
end;

function GetTL2Pet(const aid:TRGID):string;
var
  lmods:string;
begin
  result:=GetTL2Pet(aid,lmods);
end;

function GetPetIcon(const aid:TRGID):string;
begin
  result:=GetTextValue(aid,dbPetTable,'icon');
end;

function GetPetMods(const aid:TRGID):string;
begin
  result:=GetTextValue(aid,dbPetTable,'modid');
end;

//----- List -----

procedure GetPetList(out alist:tPetArray);
var
  lwhere,lSQL:string;
  vm:pointer;
  i:integer;
begin
  if db<>nil then
  begin
    if ModFilter<>'' then
      lwhere:=' WHERE '+ModFilter
    else
      lwhere:='';
    i:=0;
    lSQL:='SELECT count(*) FROM '+dbPetTable+lwhere;
    if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        i:=sqlite3_column_int(vm,0);
      end;
      sqlite3_finalize(vm);
    end;

    if i>0 then
    begin
      SetLength(alist,i);
      lSQL:='SELECT id, name, title, scale, icon FROM '+dbPetTable+lwhere;

      if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
      begin
        i:=0;
        while sqlite3_step(vm)=SQLITE_ROW do
        begin
          alist[i].id   :=sqlite3_column_int64 (vm,0);
          alist[i].name :=sqlite3_column_text  (vm,1);
          alist[i].title:=sqlite3_column_text  (vm,2);
          alist[i].scale:=sqlite3_column_double(vm,3);
          alist[i].icon :=sqlite3_column_text  (vm,4);
          inc(i);
        end;
        sqlite3_finalize(vm);
      end;
    end;
  end
  else
  begin
    alist:=Copy(DefaultPets);
  end;
end;

function GetDefaultPet:TRGID;
begin
  result:=DefaultPets[0].id;
end;

{$ENDIF}
