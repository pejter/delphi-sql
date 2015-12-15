unit sql;

{$mode objfpc}{$H+}

interface
uses
	Classes, SysUtils, LCLProc;

type
	TStringArray = Array of String;
	PRow = ^TRow;
	TRow = record
		data: String; //<value>;<value>;...
		next: PRow;
	end;

	TDb = class(TObject)
		private
			listFirst: TRow;
			listStruct: String; //<name>;<name>;... sample struct "id int;name string"
			function isField(str: String): Boolean;
			procedure CreateStruct(str: String);
			function Insert(row:String):Integer;
			function Serialize(str:String):String;
			procedure Delete(n:Byte);
			procedure Sort(field:String; ascending: Boolean);
			procedure SetValue(var row:TRow; field:String; val:string);
			function GetValue(row:TRow; field:String):String;
			function Split(const aString, aSeparator: String; aMax: Integer = 0): TStringArray;
		public
			function Exec(str: String):String;
			constructor Create;
			destructor Destroy; override;
	end;

implementation
{ Quick Sort courtesy of http://pascal-programming.info/articles/sorting.php }
Procedure QSort(numbers : Array of Integer;
                left : Integer; right : Integer);
Var pivot, l_ptr, r_ptr : Integer;


Begin
 l_ptr := left;
 r_ptr := right;
 pivot := numbers[left];
 While (left < right) do
  Begin
   While ((numbers[right] >= pivot) AND (left < right)) do
    right := right - 1;
   If (left <> right) then
    Begin
     numbers[left] := numbers[right];
     left := left + 1;
    End;
   While ((numbers[left] <= pivot) AND (left < right)) do
    left := left + 1;
   If (left <> right) then
    Begin
     numbers[right] := numbers[left];
     right := right - 1;
    End;
  End;
 numbers[left] := pivot;
 pivot := left;
 left := l_ptr;
 right := r_ptr;
 If (left < pivot) then
  QSort(numbers, left, pivot-1);
 If (right > pivot) then
  QSort(numbers, pivot+1, right);
End;
 Procedure QuickSort(numbers : Array of Integer; size : Integer);
Begin
 QSort(numbers, 0, size-1);
End;
{ Split function courtesy of http://stackoverflow.com/a/2626991 }
function TDb.Split(const aString, aSeparator: String; aMax: Integer = 0): TStringArray;
var
	i, strt, cnt: Integer;
	sepLen: Integer;

procedure AddString(aEnd: Integer = -1);
var
	endPos: Integer;
begin
	if (aEnd = -1) then
	endPos := i
	else
	endPos := aEnd + 1;

	if (strt < endPos) then
	result[cnt] := Copy(aString, strt, endPos - strt)
	else
	result[cnt] := '';

	Inc(cnt);
end;

begin
if (aString = '') or (aMax < 0) then
begin
	SetLength(result, 0);
	EXIT;
end;

if (aSeparator = '') then
begin
	SetLength(result, 1);
	result[0] := aString;
	EXIT;
end;

sepLen := Length(aSeparator);
SetLength(result, (Length(aString) div sepLen) + 1);

i     := 1;
strt  := i;
cnt   := 0;
while (i <= (Length(aString)- sepLen + 1)) do
begin
	if (aString[i] = aSeparator[1]) then
	if (Copy(aString, i, sepLen) = aSeparator) then
	begin
		AddString;

		if (cnt = aMax) then
		begin
		Inc(i, sepLen - 1);
		strt := i + 1;
		AddString(Length(aString));
		SetLength(result, cnt);
		EXIT;
		end;

		Inc(i, sepLen - 1);
		strt := i + 1;
	end;

	Inc(i);
end;

AddString(Length(aString));

SetLength(result, cnt);
end;

{ Class functions }
function TDb.isField(str: String): Boolean;
var
	fields : TStringArray;
	i : Integer;
begin
	fields := Split(listStruct, ';');
	for i := Low(fields) to High(fields) do
		if fields[i] = str then Exit(True);
	exit(False);
end;
procedure TDb.CreateStruct(str: String);
begin
	listStruct := str;
	while (listFirst.next <> nil) do
	begin
		Delete(0);
	end;
end;

function Tdb.Insert(row:String):Integer;
var
	elem: PRow;
	i: Integer;
begin
	elem := @listFirst;
	i := 0;
	while (elem^.next <> nil) do
	begin
		elem := elem^.next;
		inc(i);
	end;
	elem^.next := New(PRow);
	elem^.next^.data := row;
	Exit(i);
end;

procedure TDb.Delete(n:Byte);
var
	prev,elem: PRow;
	i: Integer;
begin
	elem := @listFirst;
	i := -1;
	while (i <> n) do
	begin
		prev := elem;
		elem := elem^.next;
		inc(i);
	end;
	prev^.next := elem^.next;
	Dispose(elem);
end;

procedure Tdb.Sort(field:String; ascending: Boolean);
var
	minBefore, min, prev, elem: PRow;
	oldFirst: TRow;
begin
	oldFirst := listFirst;
	listFirst.next := nil;
	while (True) do
	begin
		if (oldFirst.next = nil) then Exit;
		elem := @oldFirst;
		min := elem;
		while (elem^.next <> nil) do
		begin
			prev := elem;
			elem := elem^.next;
			if ( (min = @oldFirst) or
				((not ascending) and (GetValue(min^, field) < GetValue(elem^, field))) or
				((ascending) and (GetValue(min^, field) > GetValue(elem^, field)))
				) then
			begin
				minBefore := prev;
				min := elem;
			end;
		end;
		minBefore^.next := min^.next;
		Insert(min^.data);
		Dispose(min);
	end;
end;

procedure TDb.SetValue(var row:TRow; field:String; val:string);
var
	fields, rowFields: TStringArray;
	i : Integer;
begin
	fields := Split(listStruct, ';');
	rowFields := Split(row.data, ';');
	row.data := '';
	for i := 0 to High(fields) do
	begin
		if (field = fields[i]) then rowFields[i] := val;
		row.data := row.data + rowFields[i] + ';';
	end;
	SetLength(row.data, Length(row.data) - 1);
end;

function TDb.GetValue(row:TRow; field:String):String;
var
	structFields, rowFields: TStringArray;
	i : Integer;
begin
	structFields := Split(listStruct, ';');
	rowFields := Split(row.data, ';');
	row.data := '';
	for i := 0 to High(structFields) do
		if (field = Split(structFields[i], ' ')[0]) then
		begin
			Exit(rowFields[i]);
		end;
end;

function TDb.Serialize(str:String):String;
var
	fields, rowFields: TStringArray;
	outString : String;
	i, j : Integer;
begin
	fields := Split(listStruct, ';');
	rowFields := Split(str, ';');
	outString := '';
	for i := 0 to High(fields) do
	begin
		for j := 0 to High(rowFields) do
		begin
			if (Split(rowFields[j], '=')[0] = fields[i]) then
			outString := outString + Split(rowFields[j], '=')[1];
		end;
		 outString := outString + ';';
	end;
	SetLength(outString, Length(outString) - 1);
	Exit(outString);
end;

constructor TDb.Create();
var
	fd: TextFile;
	buffer: string;
begin
	try
	AssignFile(fd, 'struct.dat');
	Reset(fd);
	if not Eof(fd) then Readln(fd, listStruct);
	CloseFile(fd);
	except on e : EInOutError do
		Writeln('No struct file. Create the table structure with "create <struct>"');
	end;
	try
	AssignFile(fd, 'db.dat');
	Reset(fd);
	while not Eof(fd) do
	begin
		Readln(fd, buffer);
		Insert(buffer);
	end;
	CloseFile(fd);
	except on e : EInOutError do
		Writeln('No data file. Insert date with "insert <field>=<value>;<field>=<value>"');
	end;
end;

destructor TDb.Destroy();
var
	fd: TextFile;
begin
	AssignFile(fd, 'struct.dat');
	ReWrite(fd);
	Writeln(fd, listStruct);
	CloseFile(fd);
	AssignFile(fd, 'db.dat');
	ReWrite(fd);
	while (listFirst.next <> nil) do
	begin
		Writeln(fd, listFirst.next^.data);
		Delete(0);
	end;
	CloseFile(fd);
end;

function TDb.Exec(str: String):String;
var
	args, sortList, selFields, buffer, updateConditions, updateValues: TStringArray;
	delIndex: Array of Integer;
	elem: PRow;
	i, k : Integer;
	sortDirection : Boolean;
begin
	args := Split(str, ' ', 1);

	//try
		case LowerCase(args[0]) of
		'insert':
		begin
			Exit('Created item with id: ' + InttoStr(Insert(Serialize(args[1]))));
		end;
		'create':
		begin
			Writeln('Creating structure with: ', args[1]);
			CreateStruct(args[1]);
			Exit('Structure created');
		end;
		'update':
		begin
			buffer := Split(args[1], ' where ', 1);
			if Length(buffer) < 2 then Exit('Can''t update without sonditions');
			updateValues := Split(buffer[0], ';');
			updateConditions := Split(buffer[1], ';');
			i := Length(updateConditions);
			elem := @listFirst;
			while (elem^.next <> nil) do
			begin
				elem := elem^.next;
				for k := Low(updateConditions) to High(updateConditions) do
					if GetValue(elem^, Split(updateConditions[k], '=')[0]) = Split(updateConditions[k], '=')[1] then
						dec(i);

				if i = 0 then
				for k := Low(updateValues) to High(updateValues) do
					SetValue(elem^, Split(updateValues[k], '=')[0], Split(updateValues[k], '=')[1]);

			end;
		end;
		'sort':
		begin
			sortList := Split(args[1], ' ');
			i := Low(sortList);
			while i <= High(sortList) do
			begin
				sortDirection := True;

				if i < High(sortList) then if LowerCase(sortList[i+1]) = 'desc' then sortDirection := False;
				sort(sortList[i], sortDirection);

				if i < High(sortList) then if not isField(sortList[i+1]) then inc(i);
				Inc(i);
			end;
			Exit('Sorted');
		end;
		'select':
		begin
			selFields := Split(args[1], ',');
			elem := @listFirst;
			i := 0;
			while (elem^.next <> nil) do
			begin
				elem := elem^.next;
				Write(i, ': ');
				if Length(selFields) = 0 then Write(elem^.data) else
				for k := Low(selFields) to High(selFields) do Write(selFields[k], '=', GetValue(elem^, selFields[k]), ';');
				Writeln;
				inc(i);
			end;
			Exit('Done');
		end;
		'delete':
		begin
			buffer := Split(args[1], ',');
			{ Conversion to array of integers }
			SetLength(delIndex, 1);
			for i := Low(buffer) to High(buffer) do
			begin
				delIndex[Length(delIndex)] := StrToInt(buffer[i]);
				SetLength(delIndex, Length(delIndex) + 1);
			end;
			{ Sort the array to delete form the end of the list }
			QuickSort(delIndex, Length(delIndex));
			for i := Low(delIndex) to High(delIndex) do Delete(delIndex[i]);
			Exit('Deleted items with indexes: ' + args[1]);
		end;
		else Exit('Invalid command: '+ args[0]);
		end;
{ 	except on e : Exception do Exit(e.Message);
	end; }
end;

begin
end.
