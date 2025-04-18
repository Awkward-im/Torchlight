{}

procedure TRGMDL.ReadMeshInfo0E();
var
  i:integer;
begin
  Log('size',160); // 15+19+6+17

  for i:=0 to FSubMeshes-1 do
  begin
    Log('name',ReadText(FStream));
    Log('{00} w mesh #' ,FStream.ReadWord());
    Log('{01} w' ,FStream.ReadWord());         // maybe this part of number
    Log('{02} w' ,FStream.ReadWord());
    Log('{03} w' ,FStream.ReadWord());
    Log('{04} w' ,FStream.ReadWord());
    Log('{05} w' ,FStream.ReadWord());
    Log('{06} w' ,FStream.ReadWord());
    Log('{07} w' ,FStream.ReadWord());
    Log('{08} w' ,FStream.ReadWord());
    Log('{09} w' ,FStream.ReadWord());
    Log('{10} w' ,FStream.ReadWord());
    Log('{11} w' ,FStream.ReadWord());
    Log('{12} w' ,FStream.ReadWord());
    Log('{13} w' ,FStream.ReadWord());
    Log('{14} w' ,FStream.ReadWord());

    Log('{00} w' ,FStream.ReadWord());
    Log('{01} w' ,FStream.ReadWord());
    Log('{02} w' ,FStream.ReadWord());
    Log('{03} w' ,FStream.ReadWord());
    Log('{04} w' ,FStream.ReadWord());
    Log('{05} w' ,FStream.ReadWord());
    Log('{06} w' ,FStream.ReadWord());
    Log('{07} w' ,FStream.ReadWord());
    Log('{08} w' ,FStream.ReadWord());
    Log('{09} w' ,FStream.ReadWord());
    Log('{10} w' ,FStream.ReadWord());
    Log('{11} w' ,FStream.ReadWord());
    Log('{12} w' ,FStream.ReadWord());
    Log('{13} w' ,FStream.ReadWord());
    Log('{14} w' ,FStream.ReadWord());
    Log('{15} w' ,FStream.ReadWord());
    Log('{16} w' ,FStream.ReadWord());
    Log('{17} w' ,FStream.ReadWord());
    Log('{18} w' ,FStream.ReadWord());

    Log('{00} f' ,FStream.ReadFloat());
    Log('{01} f' ,FStream.ReadFloat());
    Log('{02} f' ,FStream.ReadFloat());
    Log('{03} f' ,FStream.ReadFloat());
    Log('{04} f' ,FStream.ReadFloat());
    Log('{05} f' ,FStream.ReadFloat());

    Log('>textures','');
    LogTexture( 0,Integer(FStream.ReadDWord())); // base/diffuse
    LogTexture( 1,Integer(FStream.ReadDWord()));
    LogTexture( 2,Integer(FStream.ReadDWord())); //
    LogTexture( 3,Integer(FStream.ReadDWord())); // glow?
    LogTexture( 4,Integer(FStream.ReadDWord())); // normal?
    LogTexture( 5,Integer(FStream.ReadDWord())); // normal?
    LogTexture( 6,Integer(FStream.ReadDWord()));
    LogTexture( 7,Integer(FStream.ReadDWord()));
    LogTexture( 8,Integer(FStream.ReadDWord())); // spec?
    LogTexture( 9,Integer(FStream.ReadDWord()));
    LogTexture(10,Integer(FStream.ReadDWord()));
    LogTexture(11,Integer(FStream.ReadDWord()));
    LogTexture(12,Integer(FStream.ReadDWord()));
    LogTexture(13,Integer(FStream.ReadDWord()));
    LogTexture(14,Integer(FStream.ReadDWord()));
    LogTexture(15,Integer(FStream.ReadDWord()));
    LogTexture(16,Integer(FStream.ReadDWord()));
  end;
end;

procedure TRGMDL.ReadMeshInfo09();
var
  i:integer;
begin
  Log('size',118); // 12+17+5+10

  for i:=0 to FSubMeshes-1 do
  begin
    Log('name',ReadText(FStream));
    Log('{00} w mesh #' ,FStream.ReadWord());
    Log('{01} w' ,FStream.ReadWord());
    Log('{02} w' ,FStream.ReadWord());
    Log('{03} w' ,FStream.ReadWord());
    Log('{04} w' ,FStream.ReadWord());
    Log('{05} w' ,FStream.ReadWord());
    Log('{06} w' ,FStream.ReadWord());
    Log('{07} w' ,FStream.ReadWord());
    Log('{08} w' ,FStream.ReadWord());
    Log('{09} w' ,FStream.ReadWord());
    Log('{10} w' ,FStream.ReadWord());
    Log('{11} w' ,FStream.ReadWord());

    Log('{00} w' ,FStream.ReadWord());
    Log('{01} w' ,FStream.ReadWord());
    Log('{02} w' ,FStream.ReadWord());
    Log('{03} w' ,FStream.ReadWord());
    Log('{04} w' ,FStream.ReadWord());
    Log('{05} w' ,FStream.ReadWord());
    Log('{06} w' ,FStream.ReadWord());
    Log('{07} w' ,FStream.ReadWord());
    Log('{08} w' ,FStream.ReadWord());
    Log('{09} w' ,FStream.ReadWord());
    Log('{10} w' ,FStream.ReadWord());
    Log('{11} w' ,FStream.ReadWord());
    Log('{12} w' ,FStream.ReadWord());
    Log('{13} w' ,FStream.ReadWord());
    Log('{14} w' ,FStream.ReadWord());
    Log('{15} w' ,FStream.ReadWord());
    Log('{16} w' ,FStream.ReadWord());

    Log('{00} f' ,FStream.ReadFloat());
    Log('{01} f' ,FStream.ReadFloat());
    Log('{02} f' ,FStream.ReadFloat());
    Log('{03} f' ,FStream.ReadFloat());
    Log('{04} f' ,FStream.ReadFloat());

    Log('>textures','');
    LogTexture(0,Integer(FStream.ReadDWord())); // base/diffuse
    LogTexture(1,Integer(FStream.ReadDWord()));
    LogTexture(2,Integer(FStream.ReadDWord())); // env:dark
    LogTexture(3,Integer(FStream.ReadDWord())); // env:pref
    LogTexture(4,Integer(FStream.ReadDWord())); // glow
    LogTexture(5,Integer(FStream.ReadDWord())); // normal
    LogTexture(6,Integer(FStream.ReadDWord()));
    LogTexture(7,Integer(FStream.ReadDWord()));
    LogTexture(8,Integer(FStream.ReadDWord())); // spec
    LogTexture(9,Integer(FStream.ReadDWord()));
  end;
end;

procedure TRGMDL.ReadMeshInfo08();
var
  i:integer;
begin
  Log('size',114); // 10+17+5+10

  for i:=0 to FSubMeshes-1 do
  begin
    Log('name',ReadText(FStream));
    Log('{00} w mesh #' ,FStream.ReadWord());
    Log('{01} w' ,FStream.ReadWord());
    Log('{02} w' ,FStream.ReadWord());
    Log('{03} w' ,FStream.ReadWord());
    Log('{04} w' ,FStream.ReadWord());
    Log('{05} w' ,FStream.ReadWord());
    Log('{06} w' ,FStream.ReadWord());
    Log('{07} w' ,FStream.ReadWord());
    Log('{08} w' ,FStream.ReadWord());
    Log('{09} w' ,FStream.ReadWord());

    Log('{00} w' ,FStream.ReadWord());
    Log('{01} w' ,FStream.ReadWord());
    Log('{02} w' ,FStream.ReadWord());
    Log('{03} w' ,FStream.ReadWord());
    Log('{04} w' ,FStream.ReadWord());
    Log('{05} w' ,FStream.ReadWord());
    Log('{06} w' ,FStream.ReadWord());
    Log('{07} w' ,FStream.ReadWord());
    Log('{08} w' ,FStream.ReadWord());
    Log('{09} w' ,FStream.ReadWord());
    Log('{10} w' ,FStream.ReadWord());
    Log('{11} w' ,FStream.ReadWord());
    Log('{12} w' ,FStream.ReadWord());
    Log('{13} w' ,FStream.ReadWord());
    Log('{14} w' ,FStream.ReadWord());
    Log('{15} w' ,FStream.ReadWord());
    Log('{16} w' ,FStream.ReadWord());

    Log('{00} f' ,FStream.ReadFloat());
    Log('{01} f' ,FStream.ReadFloat());
    Log('{02} f' ,FStream.ReadFloat());
    Log('{03} f' ,FStream.ReadFloat());
    Log('{04} f' ,FStream.ReadFloat());

    Log('>textures','');
    LogTexture(0,Integer(FStream.ReadDWord())); // base/diffuse
    LogTexture(1,Integer(FStream.ReadDWord()));
    LogTexture(2,Integer(FStream.ReadDWord()));
    LogTexture(3,Integer(FStream.ReadDWord()));
    LogTexture(4,Integer(FStream.ReadDWord())); // glow
    LogTexture(5,Integer(FStream.ReadDWord())); // normal
    LogTexture(6,Integer(FStream.ReadDWord()));
    LogTexture(7,Integer(FStream.ReadDWord()));
    LogTexture(8,Integer(FStream.ReadDWord()));
    LogTexture(9,Integer(FStream.ReadDWord()));
  end;
end;

procedure TRGMDL.ReadMeshInfo07();
var
  i:integer;
begin
  Log('size',104); // 10+14+5+9

  for i:=0 to FSubMeshes-1 do
  begin
    Log('name',ReadText(FStream));
    Log('{00} w mesh #' ,FStream.ReadWord());
    Log('{01} w' ,FStream.ReadWord());
    Log('{02} w' ,FStream.ReadWord());
    Log('{03} w' ,FStream.ReadWord());
    Log('{04} w' ,FStream.ReadWord());
    Log('{05} w' ,FStream.ReadWord());
    Log('{06} w' ,FStream.ReadWord());
    Log('{07} w' ,FStream.ReadWord());
    Log('{08} w' ,FStream.ReadWord());
    Log('{09} w' ,FStream.ReadWord());

    Log('{00} w' ,FStream.ReadWord());
    Log('{01} w' ,FStream.ReadWord());
    Log('{02} w' ,FStream.ReadWord());
    Log('{03} w' ,FStream.ReadWord());
    Log('{04} w' ,FStream.ReadWord());
    Log('{05} w' ,FStream.ReadWord());
    Log('{06} w' ,FStream.ReadWord());
    Log('{07} w' ,FStream.ReadWord());
    Log('{08} w' ,FStream.ReadWord());
    Log('{09} w' ,FStream.ReadWord());
    Log('{10} w' ,FStream.ReadWord());
    Log('{11} w' ,FStream.ReadWord());
    Log('{12} w' ,FStream.ReadWord());
    Log('{13} w' ,FStream.ReadWord());

    Log('{00} f' ,FStream.ReadFloat());
    Log('{01} f' ,FStream.ReadFloat());
    Log('{02} f' ,FStream.ReadFloat());
    Log('{03} f' ,FStream.ReadFloat());
    Log('{04} f' ,FStream.ReadFloat());

    Log('>textures','');
    LogTexture(0,Integer(FStream.ReadDWord())); // base/diffuse
    LogTexture(1,Integer(FStream.ReadDWord()));
    LogTexture(2,Integer(FStream.ReadDWord())); // envmap
    LogTexture(3,Integer(FStream.ReadDWord())); // glow
    LogTexture(4,Integer(FStream.ReadDWord())); // normal
    LogTexture(5,Integer(FStream.ReadDWord()));
    LogTexture(6,Integer(FStream.ReadDWord()));
    LogTexture(7,Integer(FStream.ReadDWord()));
    LogTexture(8,Integer(FStream.ReadDWord()));
  end;
end;

procedure TRGMDL.ReadMeshInfo03();
var
  i:integer;
begin
  Log('size',94); // 8+13+5+8

  for i:=0 to FSubMeshes-1 do
  begin
    Log('name',ReadText(FStream));
    Log('{00} w mesh #' ,FStream.ReadWord());
    Log('{01} w' ,FStream.ReadWord());
    Log('{02} w' ,FStream.ReadWord());
    Log('{03} w' ,FStream.ReadWord());
    Log('{04} w' ,FStream.ReadWord());
    Log('{05} w' ,FStream.ReadWord());
    Log('{06} w' ,FStream.ReadWord());
    Log('{07} w' ,FStream.ReadWord());

    Log('{00} w' ,FStream.ReadWord());
    Log('{01} w' ,FStream.ReadWord());
    Log('{02} w' ,FStream.ReadWord());
    Log('{03} w' ,FStream.ReadWord());
    Log('{04} w' ,FStream.ReadWord());
    Log('{05} w' ,FStream.ReadWord());
    Log('{06} w' ,FStream.ReadWord());
    Log('{07} w' ,FStream.ReadWord());
    Log('{08} w' ,FStream.ReadWord());
    Log('{09} w' ,FStream.ReadWord());
    Log('{10} w' ,FStream.ReadWord());
    Log('{11} w' ,FStream.ReadWord());
    Log('{12} w' ,FStream.ReadWord());

    Log('{00} f' ,FStream.ReadFloat());
    Log('{01} f' ,FStream.ReadFloat());
    Log('{02} f' ,FStream.ReadFloat());
    Log('{03} f' ,FStream.ReadFloat());
    Log('{04} f' ,FStream.ReadFloat());

    Log('>textures','');
    LogTexture(0,Integer(FStream.ReadDWord())); // base/diffuse
    LogTexture(1,Integer(FStream.ReadDWord()));
    LogTexture(2,Integer(FStream.ReadDWord()));
    LogTexture(3,Integer(FStream.ReadDWord())); // glow
    LogTexture(4,Integer(FStream.ReadDWord())); // normal
    LogTexture(5,Integer(FStream.ReadDWord()));
    LogTexture(6,Integer(FStream.ReadDWord()));
    LogTexture(7,Integer(FStream.ReadDWord()));
  end;
end;

procedure TRGMDL.ReadMeshInfo02();
var
  i:integer;
begin
  Log('size',92); // 7+13+5+8

  for i:=0 to FSubMeshes-1 do
  begin
    Log('name',ReadText(FStream));
    Log('{00} w mesh #' ,FStream.ReadWord());
    Log('{01} w' ,FStream.ReadWord());
    Log('{02} w' ,FStream.ReadWord());
    Log('{03} w' ,FStream.ReadWord());
    Log('{04} w' ,FStream.ReadWord());
    Log('{05} w' ,FStream.ReadWord());
    Log('{06} w' ,FStream.ReadWord());

    Log('{00} w' ,FStream.ReadWord());
    Log('{01} w' ,FStream.ReadWord());
    Log('{02} w' ,FStream.ReadWord());
    Log('{03} w' ,FStream.ReadWord());
    Log('{04} w' ,FStream.ReadWord());
    Log('{05} w' ,FStream.ReadWord());
    Log('{06} w' ,FStream.ReadWord());
    Log('{07} w' ,FStream.ReadWord());
    Log('{08} w' ,FStream.ReadWord());
    Log('{09} w' ,FStream.ReadWord());
    Log('{10} w' ,FStream.ReadWord());
    Log('{11} w' ,FStream.ReadWord());
    Log('{12} w' ,FStream.ReadWord());

    Log('{00} f' ,FStream.ReadFloat());
    Log('{01} f' ,FStream.ReadFloat());
    Log('{02} f' ,FStream.ReadFloat());
    Log('{03} f' ,FStream.ReadFloat());
    Log('{04} f' ,FStream.ReadFloat());

    Log('>textures','');
    LogTexture(0,Integer(FStream.ReadDWord())); // base/diffuse
    LogTexture(1,Integer(FStream.ReadDWord()));
    LogTexture(2,Integer(FStream.ReadDWord()));
    LogTexture(3,Integer(FStream.ReadDWord()));
    LogTexture(4,Integer(FStream.ReadDWord())); // normal?
    LogTexture(5,Integer(FStream.ReadDWord()));
    LogTexture(6,Integer(FStream.ReadDWord()));
    LogTexture(7,Integer(FStream.ReadDWord()));
  end;
end;

procedure TRGMDL.ReadMeshInfo01();
var
  i:integer;
begin
  Log('size',80); // 7+13+2+8

  for i:=0 to FSubMeshes-1 do
  begin
    Log('name',ReadText(FStream));
    Log('{00} w mesh #' ,FStream.ReadWord());
    Log('{01} w' ,FStream.ReadWord());
    Log('{02} w' ,FStream.ReadWord());
    Log('{03} w' ,FStream.ReadWord());
    Log('{04} w' ,FStream.ReadWord());
    Log('{05} w' ,FStream.ReadWord());
    Log('{06} w' ,FStream.ReadWord());

    Log('{00} w' ,FStream.ReadWord());
    Log('{01} w' ,FStream.ReadWord());
    Log('{02} w' ,FStream.ReadWord());
    Log('{03} w' ,FStream.ReadWord());
    Log('{04} w' ,FStream.ReadWord());
    Log('{05} w' ,FStream.ReadWord());
    Log('{06} w' ,FStream.ReadWord());
    Log('{07} w' ,FStream.ReadWord());
    Log('{08} w' ,FStream.ReadWord());
    Log('{09} w' ,FStream.ReadWord());
    Log('{10} w' ,FStream.ReadWord());
    Log('{11} w' ,FStream.ReadWord());
    Log('{12} w' ,FStream.ReadWord());

    Log('{00} f' ,FStream.ReadFloat());
    Log('{01} f' ,FStream.ReadFloat());

    Log('>textures','');
    LogTexture(0,Integer(FStream.ReadDWord())); // base/diffuse
    LogTexture(1,Integer(FStream.ReadDWord()));
    LogTexture(2,Integer(FStream.ReadDWord()));
    LogTexture(3,Integer(FStream.ReadDWord())); // glow
    LogTexture(4,Integer(FStream.ReadDWord())); // normal
    LogTexture(5,Integer(FStream.ReadDWord()));
    LogTexture(6,Integer(FStream.ReadDWord()));
    LogTexture(7,Integer(FStream.ReadDWord()));
  end;
end;
