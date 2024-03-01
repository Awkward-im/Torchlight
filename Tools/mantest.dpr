uses
  rgglobal,
  rgman;
var
  man:TRGManifest;
begin
   man.init;

   MANtoFile('init.man',man);

   man.AddPath('zero');
   MANtoFile('0.man',man);

   man.AddPath('first\second\third');
   MANtoFile('1.man',man);

   man.AddFile('first\second','one.dat');
   MANtoFile('2.man',man);

   man.AddFile('first\second\third\forth\','two.dat');
   MANtoFile('3.man',man);

   man.AddFile('','three.dat');
   MANtoFile('4.man',man);

   man.DeletePath('first\second');
   MANtoFile('5.man',man);

   man.AddPath('first\five');
   MANtoFile('6.man',man);

   man.AddFile('first\second\bla-bla\forth','four.dat');
   man.RenameDir('first\second\bla-bla','next');
   MANtoFile('7.man',man);

   man.AddPath('subzero');
   MANtoFile('00.man',man);

   man.Free;
end.
