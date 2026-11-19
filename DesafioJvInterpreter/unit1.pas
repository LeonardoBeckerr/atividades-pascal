unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Variants, IBConnection, SQLDB, Forms, Controls, Graphics,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, JvInterpreter;

type

  { TForm1 }

  TForm1 = class(TForm)
    btnCarregarTxt: TButton;
    btnExecutar: TButton;
    btnSalvarTxt: TButton;
    edtCliente: TEdit;
    gbDados: TGroupBox;
    ibConexao: TIBConnection;
    JvInterpreterProgram1: TJvInterpreterProgram;
    lblCliente: TLabel;
    lblSaida: TLabel;
    lblScript: TLabel;
    lblSubtitulo: TLabel;
    lblTitulo: TLabel;
    memCodigo: TMemo;
    memSaida: TMemo;
    pnlCentro: TPanel;
    pnlCodigo: TPanel;
    pnlDados: TPanel;
    pnlSaida: TPanel;
    pnlTopo: TPanel;
    sbStatus: TStatusBar;
    splDivisor: TSplitter;
    sqlQuery: TSQLQuery;
    sqlTransacao: TSQLTransaction;
    procedure btnCarregarTxtClick(Sender: TObject);
    procedure btnExecutarClick(Sender: TObject);
    procedure btnSalvarTxtClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure JvInterpreterProgram1GetValue(Sender: TObject; Identifier: string;
      var Value: Variant; Args: TJvInterpreterArgs; var Done: Boolean);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  memCodigo.Lines.Clear;
  memCodigo.Lines.Add('var');
  memCodigo.Lines.Add('  desconto, total: double;');
  memCodigo.Lines.Add('begin');
  memCodigo.Lines.Add('  if ValorBruto > 500 then');
  memCodigo.Lines.Add('    desconto := ValorBruto * 0.10');
  memCodigo.Lines.Add('  else');
  memCodigo.Lines.Add('    desconto := 0;');
  memCodigo.Lines.Add('');
  memCodigo.Lines.Add('  total := ValorBruto - desconto;');
  memCodigo.Lines.Add('');
  memCodigo.Lines.Add('  Result := ''Cliente: '' + NomeCliente + #13#10 +');
  memCodigo.Lines.Add('            ''Valor Bruto: R$ '' + FormatFloat(''0.00'', ValorBruto) + #13#10 +');
  memCodigo.Lines.Add('            ''Desconto: R$ '' + FormatFloat(''0.00'', desconto) + #13#10 +');
  memCodigo.Lines.Add('            ''Total Final: R$ '' + FormatFloat(''0.00'', total);');
  memCodigo.Lines.Add('end;');

  btnExecutarClick(nil);
end;

procedure TForm1.JvInterpreterProgram1GetValue(Sender: TObject;
  Identifier: string; var Value: Variant; Args: TJvInterpreterArgs;
  var Done: Boolean);
begin
  if CompareText(Identifier, 'NomeCliente') = 0 then
  begin
    Value := edtCliente.Text;
    Done := True;
  end
  else if CompareText(Identifier, 'ValorBruto') = 0 then
  begin
    Value := StrToFloatDef(edtValor.Text, 0);
    Done := True;
  end
  else if (CompareText(Identifier, 'FormatFloat') = 0) and (Args.Count = 2) then
  begin
    Value := FormatFloat(VarToStr(Args.Values[0]), Double(Args.Values[1]));
    Done := True;
  end
  else if (CompareText(Identifier, 'ShowMessage') = 0) and (Args.Count = 1) then
  begin
    ShowMessage(VarToStr(Args.Values[0]));
    Value := Null;
    Done := True;
  end;
end;

procedure TForm1.btnExecutarClick(Sender: TObject);
begin
  memSaida.Clear;
  JvInterpreterProgram1.Pas.Assign(memCodigo.Lines);

  try
    JvInterpreterProgram1.Run;
    memSaida.Text := VarToStr(JvInterpreterProgram1.VResult);
    sbStatus.SimpleText := 'Script executado com sucesso às ' + FormatDateTime('hh:nn:ss', Now) + ' (sem recompilar o .exe)';
  except
    on E: Exception do
    begin
      sbStatus.SimpleText := 'Erro no script: ' + E.Message;
      ShowMessage('Erro no script: ' + E.Message);
    end;
  end;
end;

procedure TForm1.btnSalvarTxtClick(Sender: TObject);
begin
  memCodigo.Lines.SaveToFile('script.txt');
  sbStatus.SimpleText := 'Script salvo em script.txt na pasta do executável.';
  ShowMessage('Salvo em script.txt na pasta do executável!');
end;

procedure TForm1.btnCarregarTxtClick(Sender: TObject);
begin
  if FileExists('script.txt') then
  begin
    memCodigo.Lines.LoadFromFile('script.txt');
    sbStatus.SimpleText := 'Script carregado de script.txt.';
  end
  else
    ShowMessage('Arquivo script.txt ainda não existe.');
end;

end.
