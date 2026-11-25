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
    btnTestarBanco: TButton;
    chkHabilitar: TCheckBox;
    dlgAbrirPas: TOpenDialog;
    dlgSalvarPas: TSaveDialog;
    edtBanco: TEdit;
    edtCliente: TEdit;
    gbDados: TGroupBox;
    ibConexao: TIBConnection;
    JvInterpreterProgram1: TJvInterpreterProgram;
    lblBanco: TLabel;
    lblCliente: TLabel;
    lblSaida: TLabel;
    lblScript: TLabel;
    lblStatus: TLabel;
    lblSubtitulo: TLabel;
    lblTitulo: TLabel;
    memCodigo: TMemo;
    memSaida: TMemo;
    pbProgresso: TProgressBar;
    pnlCentro: TPanel;
    pnlCodigo: TPanel;
    pnlDados: TPanel;
    pnlProgresso: TPanel;
    pnlSaida: TPanel;
    pnlTopo: TPanel;
    sbStatus: TStatusBar;
    splDivisor: TSplitter;
    sqlQuery: TSQLQuery;
    sqlTransacao: TSQLTransaction;
    procedure btnCarregarTxtClick(Sender: TObject);
    procedure btnExecutarClick(Sender: TObject);
    procedure btnSalvarTxtClick(Sender: TObject);
    procedure btnTestarBancoClick(Sender: TObject);
    procedure edtClienteChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure JvInterpreterProgram1GetValue(Sender: TObject; Identifier: string;
      var Value: Variant; Args: TJvInterpreterArgs; var Done: Boolean);
  private
    function PastaScripts: string;
    procedure GarantirScriptsPadrao;
    procedure GarantirBancoETabela;
    function NomeJaExisteNoBanco(const ANome: string): Boolean;
    procedure GravarNomeNoBanco(const ANome: string);
    procedure ExecutarProcessamentoApp(QtdRegistros: integer);
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

function TForm1.PastaScripts: string;
begin
  Result := ExtractFilePath(Application.ExeName) + 'scripts' + PathDelim;
end;

procedure TForm1.GarantirScriptsPadrao;
var
  sl: TStringList;
  arq1, arq2: string;
begin
  ForceDirectories(PastaScripts);
  arq1 := PastaScripts + 'teste1_laco.pas';
  arq2 := PastaScripts + 'teste2_bidirecional.pas';

  sl := TStringList.Create;
  try
    if not FileExists(arq1) then
    begin
      sl.Text :=
        'var' + sLineBreak +
        '  i: integer;' + sLineBreak +
        '  nome: string;' + sLineBreak +
        'begin' + sLineBreak +
        '  if not OperacaoHabilitada() then' + sLineBreak +
        '  begin' + sLineBreak +
        '    AdicionarLog(''Execução cancelada: CheckBox desmarcado.'');' + sLineBreak +
        '    MostrarMensagem(''Marque "Habilitar operação"!'');' + sLineBreak +
        '    Exit;' + sLineBreak +
        '  end;' + sLineBreak +
        sLineBreak +
        '  nome := LerNome();' + sLineBreak +
        '  HabilitarBotao(False);' + sLineBreak +
        '  DefinirStatus(''Processando'');' + sLineBreak +
        '  AdicionarLog(''Iniciando processamento para: '' + nome);' + sLineBreak +
        sLineBreak +
        '  for i := 1 to 100 do' + sLineBreak +
        '  begin' + sLineBreak +
        '    DefinirProgresso(i);' + sLineBreak +
        '    if (i mod 10) = 0 then' + sLineBreak +
        '      AdicionarLog(''Etapa '' + IntToStr(i) + ''% concluída'');' + sLineBreak +
        '    Pausar(15);' + sLineBreak +
        '  end;' + sLineBreak +
        sLineBreak +
        '  if nome <> '''' then' + sLineBreak +
        '    GravarNomeNoBanco(nome);' + sLineBreak +
        sLineBreak +
        '  DefinirStatus(''Concluído'');' + sLineBreak +
        '  HabilitarBotao(True);' + sLineBreak +
        '  MostrarMensagem(''Processamento concluído para '' + nome + ''!'');' + sLineBreak +
        'end;';
      sl.SaveToFile(arq1);
    end;

    if not FileExists(arq2) then
    begin
      sl.Text :=
        'var' + sLineBreak +
        '  nome: string;' + sLineBreak +
        'begin' + sLineBreak +
        '  nome := LerNome();' + sLineBreak +
        '  AdicionarLog(''Script solicitando processamento para: '' + nome);' + sLineBreak +
        '  ExecutarProcessamento(50);' + sLineBreak +
        '  MostrarMensagem(''Rotina da aplicação finalizada!'');' + sLineBreak +
        'end;';
      sl.SaveToFile(arq2);
    end;
  finally
    sl.Free;
  end;
end;

procedure TForm1.GarantirBancoETabela;
var
  caminho, pasta: string;
  tabelaExiste: boolean;
begin
  caminho := Trim(edtBanco.Text);
  if caminho = '' then
    raise Exception.Create('Informe o caminho da base Firebird (.fdb).');

  if ibConexao.Connected and (not SameText(ibConexao.DatabaseName, caminho)) then
    ibConexao.Connected := False;

  if not ibConexao.Connected then
  begin
    pasta := ExtractFilePath(caminho);
    if pasta <> '' then
      ForceDirectories(pasta);

    ibConexao.HostName := 'localhost';
    ibConexao.UserName := 'SYSDBA';
    ibConexao.Password := 'masterkey';
    ibConexao.CharSet := 'UTF8';
    ibConexao.Dialect := 3;
    ibConexao.DatabaseName := caminho;

    if not FileExists(caminho) then
      ibConexao.CreateDB;

    ibConexao.Connected := True;
  end;

  sqlQuery.Close;
  sqlQuery.SQL.Text :=
    'SELECT COUNT(*) AS QTD FROM RDB$RELATIONS ' +
    'WHERE TRIM(RDB$RELATION_NAME) = ''NOMES''';
  sqlQuery.Open;
  tabelaExiste := sqlQuery.FieldByName('QTD').AsInteger > 0;
  sqlQuery.Close;

  if not tabelaExiste then
  begin
    sqlQuery.SQL.Text :=
      'CREATE TABLE NOMES (' +
      '  CODIGO INTEGER NOT NULL PRIMARY KEY,' +
      '  NOME VARCHAR(255) NOT NULL' +
      ')';
    sqlQuery.ExecSQL;
    sqlTransacao.Commit;
  end;
end;

function TForm1.NomeJaExisteNoBanco(const ANome: string): Boolean;
var
  nomeLimpo: string;
begin
  nomeLimpo := Trim(ANome);
  if nomeLimpo = '' then
    Exit(False);

  GarantirBancoETabela;

  sqlQuery.Close;
  sqlQuery.SQL.Text :=
    'SELECT COUNT(*) AS QTD FROM NOMES ' +
    'WHERE UPPER(TRIM(NOME)) = UPPER(:P_NOME)';
  sqlQuery.ParamByName('P_NOME').AsString := nomeLimpo;
  sqlQuery.Open;
  Result := sqlQuery.FieldByName('QTD').AsInteger > 0;
  sqlQuery.Close;
end;

procedure TForm1.GravarNomeNoBanco(const ANome: string);
var
  nomeLimpo: string;
  proxCodigo: integer;
begin
  nomeLimpo := Trim(ANome);
  if nomeLimpo = '' then
    Exit;

  if NomeJaExisteNoBanco(nomeLimpo) then
  begin
    memSaida.Lines.Add('Firebird: o nome "' + nomeLimpo +
      '" já está cadastrado (registro duplicado bloqueado).');
    Exit;
  end;

  GarantirBancoETabela;

  sqlQuery.Close;
  sqlQuery.SQL.Text := 'SELECT COALESCE(MAX(CODIGO), 0) + 1 AS PROX FROM NOMES';
  sqlQuery.Open;
  proxCodigo := sqlQuery.FieldByName('PROX').AsInteger;
  sqlQuery.Close;

  sqlQuery.SQL.Text := 'INSERT INTO NOMES (CODIGO, NOME) VALUES (:P_COD, :P_NOME)';
  sqlQuery.ParamByName('P_COD').AsInteger := proxCodigo;
  sqlQuery.ParamByName('P_NOME').AsString := nomeLimpo;
  sqlQuery.ExecSQL;
  sqlTransacao.CommitRetaining;

  memSaida.Lines.Add('Firebird: gravado CODIGO=' + IntToStr(proxCodigo) +
    ', NOME="' + nomeLimpo + '".');
end;

procedure TForm1.ExecutarProcessamentoApp(QtdRegistros: integer);
var
  i: integer;
  nomeAtual: string;
begin
  if not chkHabilitar.Checked then
  begin
    memSaida.Lines.Add('Operação desabilitada pelo usuário (CheckBox desmarcado).');
    lblStatus.Caption := 'Status: Operação desabilitada';
    Exit;
  end;

  if QtdRegistros <= 0 then
    Exit;

  btnExecutar.Enabled := False;
  lblStatus.Caption := 'Status: Processando (' + IntToStr(QtdRegistros) + ' registros)...';
  pbProgresso.Position := 0;
  Application.ProcessMessages;

  try
    for i := 1 to QtdRegistros do
    begin
      pbProgresso.Position := Round((i * 100) / QtdRegistros);
      if ((i mod 10) = 0) or (i = QtdRegistros) then
        memSaida.Lines.Add('Registro ' + IntToStr(i) + ' de ' +
          IntToStr(QtdRegistros) + ' processado pela aplicação.');
      Sleep(20);
      Application.ProcessMessages;
    end;

    nomeAtual := Trim(edtCliente.Text);
    if nomeAtual <> '' then
      GravarNomeNoBanco(nomeAtual);

    lblStatus.Caption := 'Status: Concluído';
  finally
    btnExecutar.Enabled := True;
    Application.ProcessMessages;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  memSaida.Clear;
  lblStatus.Caption := 'Status: Aguardando';
  pbProgresso.Min := 0;
  pbProgresso.Max := 100;
  pbProgresso.Position := 0;
  edtBanco.Text := ExtractFilePath(Application.ExeName) + 'TESTE.FDB';

  GarantirScriptsPadrao;
  dlgAbrirPas.InitialDir := PastaScripts;
  dlgSalvarPas.InitialDir := PastaScripts;

  if FileExists(PastaScripts + 'teste1_laco.pas') then
    memCodigo.Lines.LoadFromFile(PastaScripts + 'teste1_laco.pas');
end;

procedure TForm1.JvInterpreterProgram1GetValue(Sender: TObject;
  Identifier: string; var Value: Variant; Args: TJvInterpreterArgs;
  var Done: Boolean);
begin
  if CompareText(Identifier, 'LerNome') = 0 then
  begin
    Value := Trim(edtCliente.Text);
    Done := True;
  end
  else if CompareText(Identifier, 'OperacaoHabilitada') = 0 then
  begin
    Value := chkHabilitar.Checked;
    Done := True;
  end
  else if (CompareText(Identifier, 'MostrarMensagem') = 0) and (Args.Count = 1) then
  begin
    ShowMessage(VarToStr(Args.Values[0]));
    Value := Null;
    Done := True;
  end
  else if (CompareText(Identifier, 'AdicionarLog') = 0) and (Args.Count = 1) then
  begin
    memSaida.Lines.Add(VarToStr(Args.Values[0]));
    Application.ProcessMessages;
    Value := Null;
    Done := True;
  end
  else if (CompareText(Identifier, 'DefinirProgresso') = 0) and (Args.Count = 1) then
  begin
    pbProgresso.Position := Integer(Args.Values[0]);
    Application.ProcessMessages;
    Value := Null;
    Done := True;
  end
  else if (CompareText(Identifier, 'DefinirStatus') = 0) and (Args.Count = 1) then
  begin
    lblStatus.Caption := 'Status: ' + VarToStr(Args.Values[0]);
    Application.ProcessMessages;
    Value := Null;
    Done := True;
  end
  else if (CompareText(Identifier, 'HabilitarBotao') = 0) and (Args.Count = 1) then
  begin
    btnExecutar.Enabled := Boolean(Args.Values[0]);
    Application.ProcessMessages;
    Value := Null;
    Done := True;
  end
  else if (CompareText(Identifier, 'ExecutarProcessamento') = 0) and (Args.Count = 1) then
  begin
    ExecutarProcessamentoApp(Integer(Args.Values[0]));
    Value := Null;
    Done := True;
  end
  else if (CompareText(Identifier, 'GravarNomeNoBanco') = 0) and (Args.Count = 1) then
  begin
    GravarNomeNoBanco(VarToStr(Args.Values[0]));
    Value := Null;
    Done := True;
  end
  else if (CompareText(Identifier, 'NomeJaCadastrado') = 0) and (Args.Count = 1) then
  begin
    Value := NomeJaExisteNoBanco(VarToStr(Args.Values[0]));
    Done := True;
  end
  else if (CompareText(Identifier, 'IntToStr') = 0) and (Args.Count = 1) then
  begin
    Value := IntToStr(Integer(Args.Values[0]));
    Done := True;
  end
  else if (CompareText(Identifier, 'Pausar') = 0) and (Args.Count = 1) then
  begin
    Sleep(Integer(Args.Values[0]));
    Application.ProcessMessages;
    Value := Null;
    Done := True;
  end;
end;

procedure TForm1.btnExecutarClick(Sender: TObject);
var
  nomeDigitado: string;
begin
  memSaida.Clear;
  pbProgresso.Position := 0;

  try
    try
      nomeDigitado := Trim(edtCliente.Text);
      if (nomeDigitado <> '') and NomeJaExisteNoBanco(nomeDigitado) then
      begin
        lblStatus.Caption := 'Status: Nome já cadastrado';
        memSaida.Lines.Add('Aviso: o nome "' + nomeDigitado +
          '" já está cadastrado no banco de dados.');
        sbStatus.SimpleText := 'Nome duplicado: ' + nomeDigitado;
        ShowMessage('O nome "' + nomeDigitado +
          '" já está cadastrado no banco de dados!');
        Exit;
      end;

      JvInterpreterProgram1.Pas.Text := memCodigo.Text;
      JvInterpreterProgram1.Run;
      sbStatus.SimpleText := 'Script executado com sucesso às ' +
        FormatDateTime('hh:nn:ss', Now);
    except
      on E: Exception do
      begin
        lblStatus.Caption := 'Status: Erro no script';
        memSaida.Lines.Add('ERRO: ' + E.Message);
        sbStatus.SimpleText := 'Erro no script: ' + E.Message;
        ShowMessage('Erro no script: ' + E.Message);
      end;
    end;
  finally
    btnExecutar.Enabled := True;
  end;
end;

procedure TForm1.btnTestarBancoClick(Sender: TObject);
begin
  try
    GarantirBancoETabela;
    sbStatus.SimpleText := 'Conectado ao Firebird: ' + edtBanco.Text;
    memSaida.Lines.Add('Base conectada e tabela NOMES verificada: ' + edtBanco.Text);
    ShowMessage('Base conectada e tabela NOMES pronta!');
  except
    on E: Exception do
    begin
      sbStatus.SimpleText := 'Erro ao conectar no Firebird: ' + E.Message;
      ShowMessage('Erro ao conectar no Firebird: ' + E.Message);
    end;
  end;
end;

procedure TForm1.edtClienteChange(Sender: TObject);
begin

end;

procedure TForm1.btnSalvarTxtClick(Sender: TObject);
begin
  if dlgSalvarPas.Execute then
  begin
    memCodigo.Lines.SaveToFile(dlgSalvarPas.FileName);
    sbStatus.SimpleText := 'Script salvo: ' + ExtractFileName(dlgSalvarPas.FileName);
  end;
end;

procedure TForm1.btnCarregarTxtClick(Sender: TObject);
begin
  if dlgAbrirPas.Execute then
  begin
    memCodigo.Lines.LoadFromFile(dlgAbrirPas.FileName);
    sbStatus.SimpleText := 'Script carregado: ' + ExtractFileName(dlgAbrirPas.FileName);
  end;
end;

end.
