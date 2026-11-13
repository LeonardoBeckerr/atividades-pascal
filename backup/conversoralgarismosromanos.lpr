
                                     program conversoralgarismosromanos;

function Romano(valor: integer): string;
var
  resultado: string;
begin
  resultado := '';

  while valor > 0 do
  begin

    if valor < 4 then
    begin
      resultado := resultado + 'I';
      valor := valor - 1;
    end

    else if valor < 5 then
    begin
      resultado := resultado + 'IV';
      valor := valor - 4;
    end

    else if valor < 9 then
    begin
      resultado := resultado + 'V';
      valor := valor - 5;
    end

    else if valor < 10 then
    begin
      resultado := resultado + 'IX';
      valor := valor - 9;
    end

    else if valor < 40 then
    begin
      resultado := resultado + 'X';
      valor := valor - 10;
    end

    else if valor < 50 then
    begin
      resultado := resultado + 'XL';
      valor := valor - 40;
    end

    else if valor < 90 then
    begin
      resultado := resultado + 'L';
      valor := valor - 50;
    end

    else if valor < 100 then
    begin
      resultado := resultado + 'XC';
      valor := valor - 90;
    end

    else if valor < 400 then
    begin
      resultado := resultado + 'C';
      valor := valor - 100;
    end

    else if valor < 500 then
    begin
      resultado := resultado + 'CD';
      valor := valor - 400;
    end

    else if valor < 900 then
    begin
      resultado := resultado + 'D';
      valor := valor - 500;
    end

    else if valor < 1000 then
    begin
      resultado := resultado + 'CM';
      valor := valor - 900;
    end

    else
    begin
      resultado := resultado + 'M';
      valor := valor - 1000;
    end;

  end;

  Romano := resultado;
end;

var

    numero: integer = 0;

begin

  writeln('Digite o numero para converter para algarismo romano');
  readln(numero);
  writeln('Numero em algarismo romano: ',Romano(numero));
  readln;
end.

