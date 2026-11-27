unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows, WinINet, DB, IBConnection, SQLDB,
  fpjson, jsonparser, LazUTF8,
  Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls, ComCtrls, DBGrids;

type

  { TForm1 }

  TForm1 = class(TForm)
    btnConsultar: TButton;
    btnEditarSelecionado: TButton;
    btnExcluir: TButton;
    btnExcluirSelecionado: TButton;
    btnListarTodos: TButton;
    btnNovo: TButton;
    btnPesquisar: TButton;
    btnSalvar: TButton;
    btnTestarBanco: TButton;
    dbgClientes: TDBGrid;
    dsClientes: TDataSource;
    edtAtividade: TEdit;
    edtBairro: TEdit;
    edtBanco: TEdit;
    edtCep: TEdit;
    edtCnae: TEdit;
    edtCnpj: TEdit;
    edtCnpjFicha: TEdit;
    edtDataAbertura: TEdit;
    edtEmail: TEdit;
    edtEndereco: TEdit;
    edtEstado: TEdit;
    edtMunicipio: TEdit;
    edtNomeFantasia: TEdit;
    edtNumero: TEdit;
    edtPesquisa: TEdit;
    edtRazaoSocial: TEdit;
    edtSituacao: TEdit;
    edtTelefone: TEdit;
    gbDados: TGroupBox;
    gbFichaCliente: TGroupBox;
    ibConexao: TIBConnection;
    lblAtividade: TLabel;
    lblBairro: TLabel;
    lblBanco: TLabel;
    lblCep: TLabel;
    lblCnae: TLabel;
    lblCnpj: TLabel;
    lblCnpjFicha: TLabel;
    lblDataAbertura: TLabel;
    lblEmail: TLabel;
    lblEndereco: TLabel;
    lblEstado: TLabel;
    lblJson: TLabel;
    lblMunicipio: TLabel;
    lblNomeFantasia: TLabel;
    lblNumero: TLabel;
    lblObservacoes: TLabel;
    lblPesquisa: TLabel;
    lblRazaoSocial: TLabel;
    lblSituacao: TLabel;
    lblStatus: TLabel;
    lblSubtitulo: TLabel;
    lblTelefone: TLabel;
    lblTitulo: TLabel;
    memJson: TMemo;
    memObservacoes: TMemo;
    pbProgresso: TProgressBar;
    pnlCampos: TPanel;
    pnlCentro: TPanel;
    pnlClientes: TPanel;
    pnlDados: TPanel;
    pnlJson: TPanel;
    pnlPesquisa: TPanel;
    pnlProgresso: TPanel;
    pnlSuperior: TPanel;
    pnlTopo: TPanel;
    sbStatus: TStatusBar;
    splDivisor: TSplitter;
    splHorizontal: TSplitter;
    sqlClientes: TSQLQuery;
    sqlQuery: TSQLQuery;
    sqlTransacao: TSQLTransaction;
    procedure btnConsultarClick(Sender: TObject);
    procedure btnEditarSelecionadoClick(Sender: TObject);
    procedure btnExcluirClick(Sender: TObject);
    procedure btnExcluirSelecionadoClick(Sender: TObject);
    procedure btnListarTodosClick(Sender: TObject);
    procedure btnNovoClick(Sender: TObject);
    procedure btnPesquisarClick(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
    procedure btnTestarBancoClick(Sender: TObject);
    procedure dbgClientesDblClick(Sender: TObject);
    procedure edtCnpjKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure edtPesquisaKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
    procedure lblCnaeClick(Sender: TObject);
  private
    FClienteEditandoId: Integer;

    // Utilitários de validação e formatação
    function SomenteDigitos(const ATexto: string): string;
    function ValidarCNPJ(const ACNPJ: string): Boolean;
    function FormatarCNPJ(const ACNPJ: string): string;
    function FormatarCEP(const ACEP: string): string;
    function FormatarTelefone(const ATelefone: string): string;
    function FormatarCNAE(const ACnae: string): string;
    function FormatarDataISO(const ADataISO: string): string;
    function LimitarTexto(const ATexto: string; AMaxChars: Integer): string;
    function LerCampoJsonStr(AObj: TJSONObject; const AChave: string): string;

    // Comunicação HTTP com BrasilAPI e preenchimento da tela
    function ExecutarRequisicaoHTTP(const AUrl: string;
      out AStatusCode: Integer; out ACorpo: string; out AErro: string): Boolean;
    procedure PreencherCamposComJson(AObj: TJSONObject);
    procedure ExibirResumoJsonDoFormulario;

    // Camada de Banco de Dados Firebird (SQLDB)
    procedure GarantirBancoETabela;
    function CnpjJaExisteNoBanco(const ACnpjLimpo: string;
      AIgnorarId: Integer; out AIdExistente: Integer): Boolean;
    procedure CarregarClientes(const AFiltro: string = '');
    procedure ConfigurarColunasGrid;
    procedure CnpjFieldGetText(Sender: TField; var aText: string;
      DisplayText: Boolean);
    procedure CarregarRegistroSelecionadoParaEdicao;
    procedure ExcluirClientePorId(AId: Integer; const ARazaoSocial, ACnpj: string);

    // Controle visual do formulário
    procedure LimparFormulario(ALimparBuscaCnpj: Boolean = True);
    procedure AtualizarStatus(const AMensagem: string; AProgresso: Integer = 0);
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

const
  URL_BRASIL_API_CNPJ = 'https://brasilapi.com.br/api/cnpj/v1/';
  TIMEOUT_HTTP_MS = 15000;

{ TForm1 }

function TForm1.SomenteDigitos(const ATexto: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(ATexto) do
    if (ATexto[i] >= '0') and (ATexto[i] <= '9') then
      Result := Result + ATexto[i];
end;

function TForm1.ValidarCNPJ(const ACNPJ: string): Boolean;
const
  Pesos1: array[1..12] of Integer = (5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2);
  Pesos2: array[1..13] of Integer = (6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2);
var
  Cnpj: string;
  i, Soma, Resto, Digito1, Digito2: Integer;
  TodosIguais: Boolean;
begin
  Cnpj := SomenteDigitos(ACNPJ);
  if Length(Cnpj) <> 14 then
    Exit(False);

  TodosIguais := True;
  for i := 2 to 14 do
    if Cnpj[i] <> Cnpj[1] then
    begin
      TodosIguais := False;
      Break;
    end;
  if TodosIguais then
    Exit(False);

  Soma := 0;
  for i := 1 to 12 do
    Soma := Soma + (Ord(Cnpj[i]) - Ord('0')) * Pesos1[i];
  Resto := Soma mod 11;
  if Resto < 2 then
    Digito1 := 0
  else
    Digito1 := 11 - Resto;

  if Digito1 <> (Ord(Cnpj[13]) - Ord('0')) then
    Exit(False);

  Soma := 0;
  for i := 1 to 13 do
    Soma := Soma + (Ord(Cnpj[i]) - Ord('0')) * Pesos2[i];
  Resto := Soma mod 11;
  if Resto < 2 then
    Digito2 := 0
  else
    Digito2 := 11 - Resto;

  Result := Digito2 = (Ord(Cnpj[14]) - Ord('0'));
end;

function TForm1.FormatarCNPJ(const ACNPJ: string): string;
var
  D: string;
begin
  D := SomenteDigitos(ACNPJ);
  if Length(D) = 14 then
    Result := Copy(D, 1, 2) + '.' + Copy(D, 3, 3) + '.' + Copy(D, 6, 3) + '/' +
      Copy(D, 9, 4) + '-' + Copy(D, 13, 2)
  else
    Result := Trim(ACNPJ);
end;

function TForm1.FormatarCEP(const ACEP: string): string;
var
  D: string;
begin
  D := SomenteDigitos(ACEP);
  if Length(D) = 8 then
    Result := Copy(D, 1, 5) + '-' + Copy(D, 6, 3)
  else
    Result := Trim(ACEP);
end;

function TForm1.FormatarTelefone(const ATelefone: string): string;
var
  D: string;
begin
  D := SomenteDigitos(ATelefone);
  if Length(D) = 10 then
    Result := '(' + Copy(D, 1, 2) + ') ' + Copy(D, 3, 4) + '-' + Copy(D, 7, 4)
  else if Length(D) = 11 then
    Result := '(' + Copy(D, 1, 2) + ') ' + Copy(D, 3, 5) + '-' + Copy(D, 8, 4)
  else
    Result := Trim(ATelefone);
end;

function TForm1.FormatarCNAE(const ACnae: string): string;
var
  D: string;
begin
  D := SomenteDigitos(ACnae);
  if Length(D) = 7 then
    Result := Copy(D, 1, 4) + '-' + Copy(D, 5, 1) + '/' + Copy(D, 6, 2)
  else
    Result := Trim(ACnae);
end;

function TForm1.FormatarDataISO(const ADataISO: string): string;
var
  S: string;
begin
  S := Trim(ADataISO);
  if (Length(S) >= 10) and (S[5] = '-') and (S[8] = '-') then
    Result := Copy(S, 9, 2) + '/' + Copy(S, 6, 2) + '/' + Copy(S, 1, 4)
  else
    Result := S;
end;

function TForm1.LimitarTexto(const ATexto: string; AMaxChars: Integer): string;
var
  Limpo: string;
begin
  Limpo := Trim(ATexto);
  if UTF8Length(Limpo) > AMaxChars then
    Result := UTF8Copy(Limpo, 1, AMaxChars)
  else
    Result := Limpo;
end;

function TForm1.LerCampoJsonStr(AObj: TJSONObject; const AChave: string): string;
var
  Item: TJSONData;
begin
  Result := '';
  if AObj = nil then
    Exit;

  Item := AObj.Find(AChave);
  if (Item = nil) or (Item.JSONType = jtNull) then
    Exit;

  case Item.JSONType of
    jtString: Result := Trim(Item.AsString);
    jtNumber: Result := Trim(Item.AsJSON);
    jtBoolean: Result := BoolToStr(Item.AsBoolean, True);
  else
    Result := Trim(Item.AsJSON);
  end;
end;

function TForm1.ExecutarRequisicaoHTTP(const AUrl: string;
  out AStatusCode: Integer; out ACorpo: string; out AErro: string): Boolean;
var
  hSession, hUrl: HINTERNET;
  Flags, StatusCode, BufLen, Index, BytesLidos, TimeoutVal, LastErr: DWORD;
  Headers: AnsiString;
  Buffer: array[0..8191] of Byte;
  Stream: TMemoryStream;
  RawUtf8: RawByteString;
begin
  Result := False;
  AStatusCode := 0;
  ACorpo := '';
  AErro := '';

  hSession := InternetOpenA('CadastroClientesRadioLazarus/1.0',
    INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if hSession = nil then
  begin
    AErro := 'Não foi possível inicializar a biblioteca HTTP do Windows (WinINet).';
    Exit;
  end;

  try
    TimeoutVal := TIMEOUT_HTTP_MS;
    InternetSetOptionA(hSession, INTERNET_OPTION_CONNECT_TIMEOUT,
      @TimeoutVal, SizeOf(TimeoutVal));
    InternetSetOptionA(hSession, INTERNET_OPTION_RECEIVE_TIMEOUT,
      @TimeoutVal, SizeOf(TimeoutVal));
    InternetSetOptionA(hSession, INTERNET_OPTION_SEND_TIMEOUT,
      @TimeoutVal, SizeOf(TimeoutVal));

    Flags := INTERNET_FLAG_RELOAD or INTERNET_FLAG_NO_CACHE_WRITE or
      INTERNET_FLAG_PRAGMA_NOCACHE or INTERNET_FLAG_SECURE;
    Headers := 'Accept: application/json' + #13#10;

    hUrl := InternetOpenUrlA(hSession, PAnsiChar(AnsiString(AUrl)),
      PAnsiChar(Headers), Length(Headers), Flags, 0);
    if hUrl = nil then
    begin
      LastErr := GetLastError;
      case LastErr of
        12002: AErro := 'Tempo limite esgotado ao conectar na BrasilAPI. Verifique sua conexão ou tente novamente.';
        12007: AErro := 'Sem conexão com a internet ou falha ao localizar o servidor da BrasilAPI (DNS).';
        12029: AErro := 'Não foi possível conectar ao servidor da BrasilAPI (serviço indisponível ou sem internet).';
        12030, 12031: AErro := 'A conexão com a BrasilAPI foi interrompida durante a consulta.';
      else
        AErro := 'Falha de conexão com a internet ou erro de rede (código ' +
          IntToStr(LastErr) + ').';
      end;
      Exit;
    end;

    try
      StatusCode := 0;
      BufLen := SizeOf(StatusCode);
      Index := 0;
      if HttpQueryInfoA(hUrl, HTTP_QUERY_STATUS_CODE or HTTP_QUERY_FLAG_NUMBER,
        @StatusCode, BufLen, Index) then
        AStatusCode := Integer(StatusCode);

      Stream := TMemoryStream.Create;
      try
        repeat
          BytesLidos := 0;
          if not InternetReadFile(hUrl, @Buffer[0], SizeOf(Buffer), BytesLidos) then
          begin
            LastErr := GetLastError;
            AErro := 'Erro ao ler a resposta da BrasilAPI (código ' +
              IntToStr(LastErr) + ').';
            Exit;
          end;
          if BytesLidos > 0 then
            Stream.WriteBuffer(Buffer[0], BytesLidos);
        until BytesLidos = 0;

        if Stream.Size > 0 then
        begin
          SetString(RawUtf8, PAnsiChar(Stream.Memory), Stream.Size);
          SetCodePage(RawUtf8, CP_UTF8, False);
          ACorpo := string(RawUtf8);
        end;
      finally
        Stream.Free;
      end;

      Result := True;
    finally
      InternetCloseHandle(hUrl);
    end;
  finally
    InternetCloseHandle(hSession);
  end;
end;

procedure TForm1.PreencherCamposComJson(AObj: TJSONObject);
var
  TipoLogr, Logradouro, Complemento, EnderecoCompleto: string;
  Tel1, Tel2, Telefones, Situacao: string;
begin
  edtCnpjFicha.Text := FormatarCNPJ(LerCampoJsonStr(AObj, 'cnpj'));
  edtRazaoSocial.Text := LerCampoJsonStr(AObj, 'razao_social');
  edtNomeFantasia.Text := LerCampoJsonStr(AObj, 'nome_fantasia');

  Situacao := LerCampoJsonStr(AObj, 'descricao_situacao_cadastral');
  if Situacao = '' then
    Situacao := LerCampoJsonStr(AObj, 'situacao_cadastral');
  edtSituacao.Text := Situacao;

  edtDataAbertura.Text := FormatarDataISO(LerCampoJsonStr(AObj, 'data_inicio_atividade'));
  edtCnae.Text := FormatarCNAE(LerCampoJsonStr(AObj, 'cnae_fiscal'));
  edtAtividade.Text := LerCampoJsonStr(AObj, 'cnae_fiscal_descricao');

  TipoLogr := LerCampoJsonStr(AObj, 'descricao_tipo_de_logradouro');
  Logradouro := LerCampoJsonStr(AObj, 'logradouro');
  Complemento := LerCampoJsonStr(AObj, 'complemento');

  EnderecoCompleto := Trim(TipoLogr + ' ' + Logradouro);
  if Complemento <> '' then
    EnderecoCompleto := EnderecoCompleto + ' - ' + Complemento;
  edtEndereco.Text := EnderecoCompleto;

  edtNumero.Text := LerCampoJsonStr(AObj, 'numero');
  edtBairro.Text := LerCampoJsonStr(AObj, 'bairro');
  edtMunicipio.Text := LerCampoJsonStr(AObj, 'municipio');
  edtEstado.Text := UpperCase(LerCampoJsonStr(AObj, 'uf'));
  edtCep.Text := FormatarCEP(LerCampoJsonStr(AObj, 'cep'));

  Tel1 := FormatarTelefone(LerCampoJsonStr(AObj, 'ddd_telefone_1'));
  Tel2 := FormatarTelefone(LerCampoJsonStr(AObj, 'ddd_telefone_2'));
  Telefones := Tel1;
  if (Tel2 <> '') and (Tel2 <> Tel1) then
  begin
    if Telefones <> '' then
      Telefones := Telefones + ' / ' + Tel2
    else
      Telefones := Tel2;
  end;
  edtTelefone.Text := Telefones;

  edtEmail.Text := LerCampoJsonStr(AObj, 'email');
end;

procedure TForm1.ExibirResumoJsonDoFormulario;
var
  Obj: TJSONObject;
begin
  Obj := TJSONObject.Create;
  try
    Obj.Add('id', FClienteEditandoId);
    Obj.Add('cnpj', SomenteDigitos(edtCnpjFicha.Text));
    Obj.Add('razao_social', Trim(edtRazaoSocial.Text));
    Obj.Add('nome_fantasia', Trim(edtNomeFantasia.Text));
    Obj.Add('situacao_cadastral', Trim(edtSituacao.Text));
    Obj.Add('data_abertura', Trim(edtDataAbertura.Text));
    Obj.Add('cnae_principal', Trim(edtCnae.Text));
    Obj.Add('descricao_atividade', Trim(edtAtividade.Text));
    Obj.Add('endereco', Trim(edtEndereco.Text));
    Obj.Add('numero', Trim(edtNumero.Text));
    Obj.Add('bairro', Trim(edtBairro.Text));
    Obj.Add('municipio', Trim(edtMunicipio.Text));
    Obj.Add('estado', Trim(edtEstado.Text));
    Obj.Add('cep', Trim(edtCep.Text));
    Obj.Add('telefone', Trim(edtTelefone.Text));
    Obj.Add('email', Trim(edtEmail.Text));
    Obj.Add('observacoes', Trim(memObservacoes.Text));

    memJson.Text := Obj.FormatJSON([], 2);
    memJson.SelStart := 0;
  finally
    Obj.Free;
  end;
end;

procedure TForm1.GarantirBancoETabela;
var
  Caminho, Pasta: string;
  TabelaExiste, GeneratorExiste, TriggerExiste: Boolean;
  MaxId: Integer;
begin
  Caminho := Trim(edtBanco.Text);
  if Caminho = '' then
    raise Exception.Create('Informe o caminho da base Firebird (.fdb).');

  if ibConexao.Connected and (not SameText(ibConexao.DatabaseName, Caminho)) then
  begin
    sqlClientes.Close;
    sqlQuery.Close;
    if sqlTransacao.Active then
      sqlTransacao.Commit;
    ibConexao.Connected := False;
  end;

  if not ibConexao.Connected then
  begin
    Pasta := ExtractFilePath(Caminho);
    if Pasta <> '' then
      ForceDirectories(Pasta);

    ibConexao.HostName := 'localhost';
    ibConexao.UserName := 'SYSDBA';
    ibConexao.Password := 'masterkey';
    ibConexao.CharSet := 'UTF8';
    ibConexao.Dialect := 3;
    ibConexao.DatabaseName := Caminho;

    if not FileExists(Caminho) then
      ibConexao.CreateDB;

    ibConexao.Connected := True;
  end;

  // 1. Garante a tabela CLIENTES com CNPJ único
  sqlQuery.Close;
  sqlQuery.SQL.Text :=
    'SELECT COUNT(*) AS QTD FROM RDB$RELATIONS ' +
    'WHERE TRIM(RDB$RELATION_NAME) = ''CLIENTES''';
  sqlQuery.Open;
  TabelaExiste := sqlQuery.FieldByName('QTD').AsInteger > 0;
  sqlQuery.Close;

  if not TabelaExiste then
  begin
    sqlQuery.SQL.Text :=
      'CREATE TABLE CLIENTES (' +
      '  ID INTEGER NOT NULL PRIMARY KEY,' +
      '  CNPJ VARCHAR(14) NOT NULL UNIQUE,' +
      '  RAZAO_SOCIAL VARCHAR(200) NOT NULL,' +
      '  NOME_FANTASIA VARCHAR(200),' +
      '  SITUACAO_CADASTRAL VARCHAR(50),' +
      '  DATA_ABERTURA VARCHAR(20),' +
      '  CNAE_PRINCIPAL VARCHAR(20),' +
      '  DESCRICAO_ATIVIDADE VARCHAR(300),' +
      '  ENDERECO VARCHAR(250),' +
      '  NUMERO VARCHAR(30),' +
      '  BAIRRO VARCHAR(120),' +
      '  MUNICIPIO VARCHAR(120),' +
      '  ESTADO VARCHAR(2),' +
      '  CEP VARCHAR(10),' +
      '  TELEFONE VARCHAR(60),' +
      '  EMAIL VARCHAR(150),' +
      '  OBSERVACOES VARCHAR(1000),' +
      '  DATA_CADASTRO TIMESTAMP DEFAULT CURRENT_TIMESTAMP' +
      ')';
    sqlQuery.ExecSQL;
    sqlTransacao.Commit;
  end;

  // 2. Garante o generator GEN_CLIENTES_ID
  sqlQuery.Close;
  sqlQuery.SQL.Text :=
    'SELECT COUNT(*) AS QTD FROM RDB$GENERATORS ' +
    'WHERE TRIM(RDB$GENERATOR_NAME) = ''GEN_CLIENTES_ID''';
  sqlQuery.Open;
  GeneratorExiste := sqlQuery.FieldByName('QTD').AsInteger > 0;
  sqlQuery.Close;

  if not GeneratorExiste then
  begin
    sqlQuery.SQL.Text := 'CREATE GENERATOR GEN_CLIENTES_ID';
    sqlQuery.ExecSQL;
    sqlTransacao.Commit;

    sqlQuery.SQL.Text := 'SELECT COALESCE(MAX(ID), 0) AS MAXID FROM CLIENTES';
    sqlQuery.Open;
    MaxId := sqlQuery.FieldByName('MAXID').AsInteger;
    sqlQuery.Close;

    if MaxId > 0 then
    begin
      sqlQuery.SQL.Text := 'SET GENERATOR GEN_CLIENTES_ID TO ' + IntToStr(MaxId);
      sqlQuery.ExecSQL;
      sqlTransacao.Commit;
    end;
  end;

  // 3. Garante a trigger CLIENTES_BI para autoincremento do ID
  sqlQuery.Close;
  sqlQuery.SQL.Text :=
    'SELECT COUNT(*) AS QTD FROM RDB$TRIGGERS ' +
    'WHERE TRIM(RDB$TRIGGER_NAME) = ''CLIENTES_BI''';
  sqlQuery.Open;
  TriggerExiste := sqlQuery.FieldByName('QTD').AsInteger > 0;
  sqlQuery.Close;

  if not TriggerExiste then
  begin
    sqlQuery.SQL.Text :=
      'CREATE TRIGGER CLIENTES_BI FOR CLIENTES ' +
      'ACTIVE BEFORE INSERT POSITION 0 ' +
      'AS ' +
      'BEGIN ' +
      '  IF (NEW.ID IS NULL) THEN ' +
      '    NEW.ID = GEN_ID(GEN_CLIENTES_ID, 1); ' +
      'END';
    sqlQuery.ExecSQL;
    sqlTransacao.Commit;
  end;
end;

function TForm1.CnpjJaExisteNoBanco(const ACnpjLimpo: string;
  AIgnorarId: Integer; out AIdExistente: Integer): Boolean;
begin
  Result := False;
  AIdExistente := 0;
  if ACnpjLimpo = '' then
    Exit;

  GarantirBancoETabela;

  sqlQuery.Close;
  sqlQuery.SQL.Text :=
    'SELECT ID FROM CLIENTES ' +
    'WHERE CNPJ = :P_CNPJ AND ID <> :P_IGNORAR_ID';
  sqlQuery.ParamByName('P_CNPJ').AsString := ACnpjLimpo;
  sqlQuery.ParamByName('P_IGNORAR_ID').AsInteger := AIgnorarId;
  sqlQuery.Open;
  if not sqlQuery.EOF then
  begin
    AIdExistente := sqlQuery.FieldByName('ID').AsInteger;
    Result := True;
  end;
  sqlQuery.Close;
end;

procedure TForm1.CnpjFieldGetText(Sender: TField; var aText: string;
  DisplayText: Boolean);
begin
  if DisplayText then
    aText := FormatarCNPJ(Sender.AsString)
  else
    aText := Sender.AsString;
end;

procedure TForm1.ConfigurarColunasGrid;
  procedure AjustarColuna(const ACampo, ATitulo: string; ALargura: Integer;
    AVisivel: Boolean = True);
  var
    i: Integer;
    Col: TColumn;
    Campo: TField;
  begin
    Campo := sqlClientes.FindField(ACampo);
    if Campo <> nil then
    begin
      Campo.DisplayLabel := ATitulo;
      Campo.Visible := AVisivel;
    end;

    for i := 0 to dbgClientes.Columns.Count - 1 do
    begin
      Col := dbgClientes.Columns[i];
      if SameText(Col.FieldName, ACampo) then
      begin
        Col.Title.Caption := ATitulo;
        Col.Width := ALargura;
        Col.Visible := AVisivel;
        Exit;
      end;
    end;
  end;
begin
  if sqlClientes.FindField('CNPJ') <> nil then
    sqlClientes.FieldByName('CNPJ').OnGetText := @CnpjFieldGetText;

  AjustarColuna('ID', 'ID', 45);
  AjustarColuna('CNPJ', 'CNPJ', 140);
  AjustarColuna('RAZAO_SOCIAL', 'Razão Social', 240);
  AjustarColuna('NOME_FANTASIA', 'Nome Fantasia', 180);
  AjustarColuna('SITUACAO_CADASTRAL', 'Situação', 85);
  AjustarColuna('MUNICIPIO', 'Município', 130);
  AjustarColuna('ESTADO', 'UF', 40);
  AjustarColuna('TELEFONE', 'Telefone', 135);
  AjustarColuna('EMAIL', 'E-mail', 165);
  AjustarColuna('OBSERVACOES', 'Observações', 200);
  AjustarColuna('DATA_ABERTURA', 'Abertura', 85);
  AjustarColuna('CNAE_PRINCIPAL', 'CNAE', 80);
  AjustarColuna('DESCRICAO_ATIVIDADE', 'Atividade Econômica', 220);
  AjustarColuna('ENDERECO', 'Endereço', 200);
  AjustarColuna('NUMERO', 'Nº', 55);
  AjustarColuna('BAIRRO', 'Bairro', 120);
  AjustarColuna('CEP', 'CEP', 80);
  AjustarColuna('DATA_CADASTRO', 'Cadastro', 130);
end;

procedure TForm1.CarregarClientes(const AFiltro: string);
var
  FiltroLimpo, DigitosFiltro: string;
begin
  GarantirBancoETabela;

  FiltroLimpo := Trim(AFiltro);
  DigitosFiltro := SomenteDigitos(FiltroLimpo);

  sqlClientes.Close;
  if FiltroLimpo = '' then
  begin
    sqlClientes.SQL.Text :=
      'SELECT ID, CNPJ, RAZAO_SOCIAL, NOME_FANTASIA, SITUACAO_CADASTRAL, ' +
      '       DATA_ABERTURA, CNAE_PRINCIPAL, DESCRICAO_ATIVIDADE, ' +
      '       ENDERECO, NUMERO, BAIRRO, MUNICIPIO, ESTADO, CEP, ' +
      '       TELEFONE, EMAIL, OBSERVACOES, DATA_CADASTRO ' +
      'FROM CLIENTES ' +
      'ORDER BY RAZAO_SOCIAL';
  end
  else
  begin
    sqlClientes.SQL.Text :=
      'SELECT ID, CNPJ, RAZAO_SOCIAL, NOME_FANTASIA, SITUACAO_CADASTRAL, ' +
      '       DATA_ABERTURA, CNAE_PRINCIPAL, DESCRICAO_ATIVIDADE, ' +
      '       ENDERECO, NUMERO, BAIRRO, MUNICIPIO, ESTADO, CEP, ' +
      '       TELEFONE, EMAIL, OBSERVACOES, DATA_CADASTRO ' +
      'FROM CLIENTES ' +
      'WHERE UPPER(RAZAO_SOCIAL) LIKE UPPER(:P_TEXTO) ' +
      '   OR UPPER(COALESCE(NOME_FANTASIA, '''')) LIKE UPPER(:P_TEXTO) ' +
      '   OR CNPJ LIKE :P_CNPJ ' +
      'ORDER BY RAZAO_SOCIAL';
    sqlClientes.ParamByName('P_TEXTO').AsString := '%' + FiltroLimpo + '%';
    if DigitosFiltro <> '' then
      sqlClientes.ParamByName('P_CNPJ').AsString := '%' + DigitosFiltro + '%'
    else
      sqlClientes.ParamByName('P_CNPJ').AsString := '%' + FiltroLimpo + '%';
  end;

  sqlClientes.Open;
  ConfigurarColunasGrid;
  sbStatus.SimpleText := 'Clientes listados: ' + IntToStr(sqlClientes.RecordCount);
end;

procedure TForm1.CarregarRegistroSelecionadoParaEdicao;
begin
  if (not sqlClientes.Active) or sqlClientes.IsEmpty then
  begin
    ShowMessage('Selecione um cliente na grade para editar.');
    Exit;
  end;

  FClienteEditandoId := sqlClientes.FieldByName('ID').AsInteger;
  edtCnpj.Text := FormatarCNPJ(sqlClientes.FieldByName('CNPJ').AsString);
  edtCnpjFicha.Text := FormatarCNPJ(sqlClientes.FieldByName('CNPJ').AsString);
  edtRazaoSocial.Text := sqlClientes.FieldByName('RAZAO_SOCIAL').AsString;
  edtNomeFantasia.Text := sqlClientes.FieldByName('NOME_FANTASIA').AsString;
  edtSituacao.Text := sqlClientes.FieldByName('SITUACAO_CADASTRAL').AsString;
  edtDataAbertura.Text := sqlClientes.FieldByName('DATA_ABERTURA').AsString;
  edtCnae.Text := sqlClientes.FieldByName('CNAE_PRINCIPAL').AsString;
  edtAtividade.Text := sqlClientes.FieldByName('DESCRICAO_ATIVIDADE').AsString;
  edtEndereco.Text := sqlClientes.FieldByName('ENDERECO').AsString;
  edtNumero.Text := sqlClientes.FieldByName('NUMERO').AsString;
  edtBairro.Text := sqlClientes.FieldByName('BAIRRO').AsString;
  edtMunicipio.Text := sqlClientes.FieldByName('MUNICIPIO').AsString;
  edtEstado.Text := sqlClientes.FieldByName('ESTADO').AsString;
  edtCep.Text := sqlClientes.FieldByName('CEP').AsString;
  edtTelefone.Text := sqlClientes.FieldByName('TELEFONE').AsString;
  edtEmail.Text := sqlClientes.FieldByName('EMAIL').AsString;
  memObservacoes.Text := sqlClientes.FieldByName('OBSERVACOES').AsString;

  btnSalvar.Caption := 'Atualizar Cliente';
  ExibirResumoJsonDoFormulario;
  AtualizarStatus('Editando cliente ID ' + IntToStr(FClienteEditandoId) + ' — ' +
    edtRazaoSocial.Text, 100);
end;

procedure TForm1.ExcluirClientePorId(AId: Integer; const ARazaoSocial, ACnpj: string);
begin
  if AId <= 0 then
    Exit;

  if MessageDlg('Confirmar Exclusão',
    'Deseja realmente excluir o cliente "' + ARazaoSocial + '"' + LineEnding +
    'CNPJ: ' + FormatarCNPJ(ACnpj) + '?',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  try
    GarantirBancoETabela;
    sqlQuery.Close;
    sqlQuery.SQL.Text := 'DELETE FROM CLIENTES WHERE ID = :P_ID';
    sqlQuery.ParamByName('P_ID').AsInteger := AId;
    sqlQuery.ExecSQL;
    sqlTransacao.Commit;

    if FClienteEditandoId = AId then
      LimparFormulario(True);

    CarregarClientes(edtPesquisa.Text);
    AtualizarStatus('Cliente excluído com sucesso.', 100);
    ShowMessage('Cliente "' + ARazaoSocial + '" excluído com sucesso!');
  except
    on E: Exception do
    begin
      if sqlTransacao.Active then
        sqlTransacao.RollbackRetaining;
      AtualizarStatus('Erro ao excluir cliente.', 0);
      ShowMessage('Erro ao excluir cliente no Firebird: ' + E.Message);
    end;
  end;
end;

procedure TForm1.LimparFormulario(ALimparBuscaCnpj: Boolean);
begin
  FClienteEditandoId := 0;
  if ALimparBuscaCnpj then
    edtCnpj.Clear;

  edtCnpjFicha.Clear;
  edtRazaoSocial.Clear;
  edtNomeFantasia.Clear;
  edtSituacao.Clear;
  edtDataAbertura.Clear;
  edtCnae.Clear;
  edtAtividade.Clear;
  edtEndereco.Clear;
  edtNumero.Clear;
  edtBairro.Clear;
  edtMunicipio.Clear;
  edtEstado.Clear;
  edtCep.Clear;
  edtTelefone.Clear;
  edtEmail.Clear;
  memObservacoes.Clear;
  memJson.Clear;

  btnSalvar.Caption := 'Salvar Cliente';
  AtualizarStatus('Aguardando consulta ou seleção de cliente.', 0);
end;

procedure TForm1.AtualizarStatus(const AMensagem: string; AProgresso: Integer);
begin
  lblStatus.Caption := 'Status: ' + AMensagem;
  pbProgresso.Position := AProgresso;
  sbStatus.SimpleText := AMensagem;
  Application.ProcessMessages;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FClienteEditandoId := 0;
  pbProgresso.Min := 0;
  pbProgresso.Max := 100;
  pbProgresso.Position := 0;
  edtBanco.Text := ExtractFilePath(Application.ExeName) + 'CLIENTES_RADIO.FDB';

  LimparFormulario(True);

  try
    GarantirBancoETabela;
    CarregarClientes('');
    AtualizarStatus('Conectado ao Firebird. Pronto para consultar CNPJ.', 0);
  except
    on E: Exception do
    begin
      AtualizarStatus('Aguardando conexão com Firebird: ' + E.Message, 0);
    end;
  end;
end;

procedure TForm1.lblCnaeClick(Sender: TObject);
begin

end;

procedure TForm1.btnConsultarClick(Sender: TObject);
var
  CnpjLimpo, Url, Corpo, ErroHttp, MsgApi: string;
  StatusCode, IdExistente: Integer;
  JsonData: TJSONData;
  JsonObj: TJSONObject;
begin
  CnpjLimpo := SomenteDigitos(edtCnpj.Text);
  if CnpjLimpo = '' then
  begin
    ShowMessage('Informe um CNPJ para realizar a consulta.');
    edtCnpj.SetFocus;
    Exit;
  end;

  if not ValidarCNPJ(CnpjLimpo) then
  begin
    AtualizarStatus('CNPJ inválido informado: ' + edtCnpj.Text, 0);
    ShowMessage('CNPJ inválido! Verifique os 14 dígitos e tente novamente.');
    edtCnpj.SetFocus;
    Exit;
  end;

  edtCnpj.Text := FormatarCNPJ(CnpjLimpo);
  Url := URL_BRASIL_API_CNPJ + CnpjLimpo;

  btnConsultar.Enabled := False;
  Screen.Cursor := crHourGlass;
  try
    AtualizarStatus('Consultando CNPJ ' + FormatarCNPJ(CnpjLimpo) + ' na BrasilAPI...', 30);

    if not ExecutarRequisicaoHTTP(Url, StatusCode, Corpo, ErroHttp) then
    begin
      memJson.Text := '// Erro na requisição HTTP:' + LineEnding + '// ' + ErroHttp;
      AtualizarStatus('Falha na consulta à BrasilAPI.', 0);
      ShowMessage('Não foi possível consultar a BrasilAPI:' + LineEnding + ErroHttp);
      Exit;
    end;

    AtualizarStatus('Resposta recebida (HTTP ' + IntToStr(StatusCode) + '). Processando JSON...', 70);

    // Exibe o JSON retornado no TMemo (formatado quando válido)
    JsonData := nil;
    try
      if Trim(Corpo) <> '' then
      begin
        try
          JsonData := GetJSON(Corpo);
          memJson.Text := JsonData.FormatJSON([], 2);
        except
          memJson.Text := Corpo;
        end;
        memJson.SelStart := 0;
      end
      else
        memJson.Clear;

      if StatusCode <> 200 then
      begin
        MsgApi := '';
        if (JsonData <> nil) and (JsonData is TJSONObject) then
          MsgApi := LerCampoJsonStr(TJSONObject(JsonData), 'message');

        AtualizarStatus('BrasilAPI retornou HTTP ' + IntToStr(StatusCode), 0);
        case StatusCode of
          400:
            ShowMessage('CNPJ inválido segundo a BrasilAPI.' + LineEnding + MsgApi);
          404:
            ShowMessage('CNPJ não encontrado na base da BrasilAPI.' + LineEnding + MsgApi);
          429:
            ShowMessage('Muitas consultas em sequência na BrasilAPI (HTTP 429). Aguarde alguns segundos e tente novamente.');
          500..599:
            ShowMessage('A BrasilAPI está temporariamente indisponível (HTTP ' +
              IntToStr(StatusCode) + '). Tente novamente mais tarde.');
        else
          ShowMessage('Erro inesperado ao consultar a BrasilAPI (HTTP ' +
            IntToStr(StatusCode) + ').' + LineEnding + MsgApi);
        end;
        Exit;
      end;

      if (JsonData = nil) or (not (JsonData is TJSONObject)) then
      begin
        AtualizarStatus('Resposta JSON inválida recebida da BrasilAPI.', 0);
        ShowMessage('A resposta da BrasilAPI não é um objeto JSON válido.');
        Exit;
      end;

      JsonObj := TJSONObject(JsonData);
      PreencherCamposComJson(JsonObj);

      // Verifica no Firebird se o CNPJ já existe (sem travar a consulta caso o banco esteja offline)
      try
        if FClienteEditandoId > 0 then
        begin
          if (not CnpjJaExisteNoBanco(CnpjLimpo, 0, IdExistente)) or
             (IdExistente <> FClienteEditandoId) then
          begin
            FClienteEditandoId := 0;
            btnSalvar.Caption := 'Salvar Cliente';
            memObservacoes.Clear;
          end;
        end;

        if (FClienteEditandoId = 0) and CnpjJaExisteNoBanco(CnpjLimpo, 0, IdExistente) then
        begin
          AtualizarStatus('Dados carregados (CNPJ já cadastrado no banco — ID ' +
            IntToStr(IdExistente) + ').', 100);
          ShowMessage('Dados consultados com sucesso!' + LineEnding +
            'Atenção: este CNPJ já está cadastrado no banco (ID ' +
            IntToStr(IdExistente) + '). Para alterar os dados, selecione o cliente na grade.');
        end
        else
        begin
          AtualizarStatus('Consulta concluída! Confira os dados, adicione observações e salve.', 100);
        end;
      except
        AtualizarStatus('Consulta concluída! Conecte ao Firebird para salvar o cliente.', 100);
      end;
    finally
      JsonData.Free;
    end;
  finally
    Screen.Cursor := crDefault;
    btnConsultar.Enabled := True;
  end;
end;

procedure TForm1.btnSalvarClick(Sender: TObject);
var
  CnpjLimpo, RazaoSocial: string;
  IdExistente, NovoId: Integer;
begin
  CnpjLimpo := SomenteDigitos(edtCnpjFicha.Text);
  if CnpjLimpo = '' then
    CnpjLimpo := SomenteDigitos(edtCnpj.Text);

  if not ValidarCNPJ(CnpjLimpo) then
  begin
    ShowMessage('Informe ou consulte um CNPJ válido antes de salvar.');
    edtCnpj.SetFocus;
    Exit;
  end;

  RazaoSocial := Trim(edtRazaoSocial.Text);
  if RazaoSocial = '' then
  begin
    ShowMessage('A Razão Social é obrigatória. Consulte um CNPJ ou preencha o campo.');
    edtRazaoSocial.SetFocus;
    Exit;
  end;

  try
    AtualizarStatus('Salvando cliente no Firebird...', 40);
    GarantirBancoETabela;

    if CnpjJaExisteNoBanco(CnpjLimpo, FClienteEditandoId, IdExistente) then
    begin
      AtualizarStatus('CNPJ duplicado bloqueado (ID ' + IntToStr(IdExistente) + ').', 0);
      ShowMessage('Já existe um cliente cadastrado com o CNPJ ' +
        FormatarCNPJ(CnpjLimpo) + ' (ID ' + IntToStr(IdExistente) + ').' + LineEnding +
        'O CNPJ deve ser único. Para alterar esse cliente, selecione-o na grade.');
      Exit;
    end;

    sqlQuery.Close;
    if FClienteEditandoId = 0 then
    begin
      sqlQuery.SQL.Text :=
        'INSERT INTO CLIENTES (' +
        '  CNPJ, RAZAO_SOCIAL, NOME_FANTASIA, SITUACAO_CADASTRAL, DATA_ABERTURA,' +
        '  CNAE_PRINCIPAL, DESCRICAO_ATIVIDADE, ENDERECO, NUMERO, BAIRRO,' +
        '  MUNICIPIO, ESTADO, CEP, TELEFONE, EMAIL, OBSERVACOES' +
        ') VALUES (' +
        '  :P_CNPJ, :P_RAZAO, :P_FANTASIA, :P_SITUACAO, :P_ABERTURA,' +
        '  :P_CNAE, :P_ATIVIDADE, :P_ENDERECO, :P_NUMERO, :P_BAIRRO,' +
        '  :P_MUNICIPIO, :P_ESTADO, :P_CEP, :P_TELEFONE, :P_EMAIL, :P_OBS' +
        ') RETURNING ID';
    end
    else
    begin
      sqlQuery.SQL.Text :=
        'UPDATE CLIENTES SET ' +
        '  CNPJ = :P_CNPJ,' +
        '  RAZAO_SOCIAL = :P_RAZAO,' +
        '  NOME_FANTASIA = :P_FANTASIA,' +
        '  SITUACAO_CADASTRAL = :P_SITUACAO,' +
        '  DATA_ABERTURA = :P_ABERTURA,' +
        '  CNAE_PRINCIPAL = :P_CNAE,' +
        '  DESCRICAO_ATIVIDADE = :P_ATIVIDADE,' +
        '  ENDERECO = :P_ENDERECO,' +
        '  NUMERO = :P_NUMERO,' +
        '  BAIRRO = :P_BAIRRO,' +
        '  MUNICIPIO = :P_MUNICIPIO,' +
        '  ESTADO = :P_ESTADO,' +
        '  CEP = :P_CEP,' +
        '  TELEFONE = :P_TELEFONE,' +
        '  EMAIL = :P_EMAIL,' +
        '  OBSERVACOES = :P_OBS ' +
        'WHERE ID = :P_ID';
      sqlQuery.ParamByName('P_ID').AsInteger := FClienteEditandoId;
    end;

    sqlQuery.ParamByName('P_CNPJ').AsString := CnpjLimpo;
    sqlQuery.ParamByName('P_RAZAO').AsString := LimitarTexto(RazaoSocial, 200);
    sqlQuery.ParamByName('P_FANTASIA').AsString := LimitarTexto(edtNomeFantasia.Text, 200);
    sqlQuery.ParamByName('P_SITUACAO').AsString := LimitarTexto(edtSituacao.Text, 50);
    sqlQuery.ParamByName('P_ABERTURA').AsString := LimitarTexto(edtDataAbertura.Text, 20);
    sqlQuery.ParamByName('P_CNAE').AsString := LimitarTexto(edtCnae.Text, 20);
    sqlQuery.ParamByName('P_ATIVIDADE').AsString := LimitarTexto(edtAtividade.Text, 300);
    sqlQuery.ParamByName('P_ENDERECO').AsString := LimitarTexto(edtEndereco.Text, 250);
    sqlQuery.ParamByName('P_NUMERO').AsString := LimitarTexto(edtNumero.Text, 30);
    sqlQuery.ParamByName('P_BAIRRO').AsString := LimitarTexto(edtBairro.Text, 120);
    sqlQuery.ParamByName('P_MUNICIPIO').AsString := LimitarTexto(edtMunicipio.Text, 120);
    sqlQuery.ParamByName('P_ESTADO').AsString := LimitarTexto(UpperCase(edtEstado.Text), 2);
    sqlQuery.ParamByName('P_CEP').AsString := LimitarTexto(FormatarCEP(edtCep.Text), 10);
    sqlQuery.ParamByName('P_TELEFONE').AsString := LimitarTexto(edtTelefone.Text, 60);
    sqlQuery.ParamByName('P_EMAIL').AsString := LimitarTexto(edtEmail.Text, 150);
    sqlQuery.ParamByName('P_OBS').AsString := LimitarTexto(memObservacoes.Text, 1000);

    if FClienteEditandoId = 0 then
    begin
      sqlQuery.Open;
      NovoId := sqlQuery.FieldByName('ID').AsInteger;
      sqlQuery.Close;
      sqlTransacao.Commit;

      FClienteEditandoId := NovoId;
      edtCnpjFicha.Text := FormatarCNPJ(CnpjLimpo);
      btnSalvar.Caption := 'Atualizar Cliente';
      CarregarClientes(edtPesquisa.Text);
      AtualizarStatus('Cliente cadastrado com sucesso (ID ' + IntToStr(NovoId) + ').', 100);
      ShowMessage('Cliente "' + RazaoSocial + '" cadastrado com sucesso! (ID ' +
        IntToStr(NovoId) + ')');
    end
    else
    begin
      sqlQuery.ExecSQL;
      sqlTransacao.Commit;

      edtCnpjFicha.Text := FormatarCNPJ(CnpjLimpo);
      CarregarClientes(edtPesquisa.Text);
      AtualizarStatus('Cliente ID ' + IntToStr(FClienteEditandoId) + ' atualizado com sucesso.', 100);
      ShowMessage('Alterações do cliente "' + RazaoSocial + '" salvas com sucesso!');
    end;
  except
    on E: Exception do
    begin
      if sqlTransacao.Active then
        sqlTransacao.RollbackRetaining;
      AtualizarStatus('Erro ao salvar cliente no Firebird.', 0);
      ShowMessage('Erro ao salvar no Firebird: ' + E.Message);
    end;
  end;
end;

procedure TForm1.btnNovoClick(Sender: TObject);
begin
  LimparFormulario(True);
  edtCnpj.SetFocus;
end;

procedure TForm1.btnExcluirClick(Sender: TObject);
begin
  if FClienteEditandoId > 0 then
    ExcluirClientePorId(FClienteEditandoId, edtRazaoSocial.Text, edtCnpjFicha.Text)
  else if sqlClientes.Active and (not sqlClientes.IsEmpty) then
    ExcluirClientePorId(
      sqlClientes.FieldByName('ID').AsInteger,
      sqlClientes.FieldByName('RAZAO_SOCIAL').AsString,
      sqlClientes.FieldByName('CNPJ').AsString)
  else
    ShowMessage('Selecione um cliente na grade ou carregue um cliente para excluir.');
end;

procedure TForm1.btnTestarBancoClick(Sender: TObject);
begin
  try
    AtualizarStatus('Conectando ao Firebird...', 50);
    GarantirBancoETabela;
    CarregarClientes('');
    AtualizarStatus('Base conectada e tabela CLIENTES verificada: ' + edtBanco.Text, 100);
    ShowMessage('Base conectada e tabela CLIENTES pronta!');
  except
    on E: Exception do
    begin
      AtualizarStatus('Erro ao conectar no Firebird.', 0);
      ShowMessage('Erro ao conectar no Firebird: ' + E.Message);
    end;
  end;
end;

procedure TForm1.btnPesquisarClick(Sender: TObject);
begin
  try
    CarregarClientes(edtPesquisa.Text);
    AtualizarStatus('Pesquisa aplicada (' + IntToStr(sqlClientes.RecordCount) +
      ' registro(s) encontrado(s)).', 100);
  except
    on E: Exception do
    begin
      AtualizarStatus('Erro ao pesquisar clientes.', 0);
      ShowMessage('Erro ao pesquisar no Firebird: ' + E.Message);
    end;
  end;
end;

procedure TForm1.btnListarTodosClick(Sender: TObject);
begin
  edtPesquisa.Clear;
  try
    CarregarClientes('');
    AtualizarStatus('Listando todos os clientes (' +
      IntToStr(sqlClientes.RecordCount) + ' registro(s)).', 100);
  except
    on E: Exception do
    begin
      AtualizarStatus('Erro ao listar clientes.', 0);
      ShowMessage('Erro ao consultar o Firebird: ' + E.Message);
    end;
  end;
end;

procedure TForm1.btnEditarSelecionadoClick(Sender: TObject);
begin
  CarregarRegistroSelecionadoParaEdicao;
end;

procedure TForm1.btnExcluirSelecionadoClick(Sender: TObject);
begin
  if (not sqlClientes.Active) or sqlClientes.IsEmpty then
  begin
    ShowMessage('Selecione um cliente na grade para excluir.');
    Exit;
  end;

  ExcluirClientePorId(
    sqlClientes.FieldByName('ID').AsInteger,
    sqlClientes.FieldByName('RAZAO_SOCIAL').AsString,
    sqlClientes.FieldByName('CNPJ').AsString);
end;

procedure TForm1.dbgClientesDblClick(Sender: TObject);
begin
  CarregarRegistroSelecionadoParaEdicao;
end;

procedure TForm1.edtCnpjKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    btnConsultarClick(Sender);
  end;
end;

procedure TForm1.edtPesquisaKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    btnPesquisarClick(Sender);
  end;
end;

end.
