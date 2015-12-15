program p2;

{$mode objfpc}{$H+}
{$APPTYPE console}
uses {$IFDEF UNIX} {$IFDEF UseCThreads}
  cthreads, {$ENDIF} {$ENDIF}
  Classes,
  SysUtils,
  sql { you can add units after this };

var
  db: sql.TDb;
  command: string;
begin
    db := TDb.Create;

    while True do
    begin
      ReadLn(command);
      if command = 'exit' then break;
      if command <> '' then
        WriteLn(DB.Exec(command));
    end;
    DB.Destroy;
end.
