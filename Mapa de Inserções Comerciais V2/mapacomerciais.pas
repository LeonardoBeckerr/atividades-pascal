unit mapacomerciais;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Variants, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Spin, Grids, ComCtrls, LCLIntf, JvInterpreter;

type
  TFaixa = record
    Nome: string;
    Preco30: real;
    LimiteMin: integer;
  end;

  { TForm1 }

  TForm1 = class(TForm)
    btnAgendar: TButton;
    btnExportar: TButton;
    btnHtml: TButton;
    btnRelatorio: TButton;
    btnRestaurarScript: TButton;
    btnSalvarScript: TButton;
    cbDuracao: TComboBox;
    cbFaixa: TComboBox;
    cbScript: TComboBox;
    edtNome: TEdit;
    gbNovo: TGroupBox;
    grade: TStringGrid;
    JvInterpreterProgram1: TJvInterpreterProgram;
    lblDuracao: TLabel;
    lblEscolhaScript: TLabel;
    lblFaixa: TLabel;
    lblInsercoes: TLabel;
    lblNome: TLabel;
    lblOcupado: TLabel;
    lblSubtitulo: TLabel;
    lblTitulo: TLabel;
    memScript: TMemo;
    pbOcupado: TProgressBar;
    pgcPrincipal: TPageControl;
    pnlCadastro: TPanel;
    pnlCentro: TPanel;
    pnlRodape: TPanel;
    pnlScriptTopo: TPanel;
    pnlTopo: TPanel;
    sbStatus: TStatusBar;
    spInsercoes: TSpinEdit;
    tsMapa: TTabSheet;
    tsScripts: TTabSheet;
    procedure btnAgendarClick(Sender: TObject);
    procedure btnExportarClick(Sender: TObject);
    procedure btnHtmlClick(Sender: TObject);
    procedure btnRelatorioClick(Sender: TObject);
    procedure btnRestaurarScriptClick(Sender: TObject);
    procedure btnSalvarScriptClick(Sender: TObject);
    procedure cbFaixaChange(Sender: TObject);
    procedure cbScriptChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure JvInterpreterProgram1GetValue(Sender: TObject; Identifier: string;
      var Value: Variant; Args: TJvInterpreterArgs; var Done: Boolean);
  private
    function PastaScripts: string;
    function CaminhoScript(indice: integer): string;
    function ScriptPadrao(indice: integer): string;
    procedure GarantirScriptsPadrao;
    procedure CarregarScriptNoEditor(indice: integer);
    function TempoOcupado(faixa: integer): integer;
    function ValidarAgendamento: boolean;
    function FaturamentoTotal: real;
    function FaturamentoPorFaixa(faixa: integer): real;
    function AnuncianteMaisInvestiu: string;
    function FaixaMaisLivre: integer;
    function MontarRelatorio: string;
    procedure AdicionarNaGrade(valor: real);
    procedure TrocarLinhas(linhaA, linhaB: integer);
    procedure OrdenarGrade;
    procedure AtualizarOcupacao;
    procedure LimparCampos;
  public

  end;

var
  Form1: TForm1;
  Grade_Radio: array[0..4] of TFaixa;

implementation

{$R *.lfm}

function SegundosDaDuracao(indice: integer): integer;
begin
  case indice of
    0: SegundosDaDuracao := 15;
    1: SegundosDaDuracao := 30;
    2: SegundosDaDuracao := 60;
  else
    SegundosDaDuracao := 0;
  end;
end;

function IndiceDaFaixa(nomeFaixa: string): integer;
var
  i: integer;
begin
  Result := -1;
  for i := 0 to 4 do
  begin
    if Grade_Radio[i].Nome = nomeFaixa then
    begin
      Result := i;
      Exit;
    end;
  end;
end;

function TForm1.PastaScripts: string;
begin
  Result := ExtractFilePath(Application.ExeName) + 'scripts' + PathDelim;
end;

function TForm1.CaminhoScript(indice: integer): string;
begin
  case indice of
    0: Result := PastaScripts + 'regras_comerciais.pas';
    1: Result := PastaScripts + 'exportacao.pas';
    2: Result := PastaScripts + 'relatorio_html.pas';
  else
    Result := PastaScripts + 'regras_comerciais.pas';
  end;
end;

function TForm1.ScriptPadrao(indice: integer): string;
begin
  case indice of
    0:
      Result :=
        'unit RegrasComerciais;' + sLineBreak +
        sLineBreak +
        '// Devolva '''' (vazio) para liberar, ou uma mensagem para bloquear o agendamento.' + sLineBreak +
        'function PodeAgendar(Cliente, Faixa: string; DuracaoSeg, Insercoes, OcupadoSeg, LimiteSeg: integer): string;' + sLineBreak +
        'var' + sLineBreak +
        '  restante: integer;' + sLineBreak +
        'begin' + sLineBreak +
        '  Result := '''';' + sLineBreak +
        '  if OcupadoSeg + (DuracaoSeg * Insercoes) > LimiteSeg then' + sLineBreak +
        '  begin' + sLineBreak +
        '    restante := LimiteSeg - OcupadoSeg;' + sLineBreak +
        '    Result := ''Tempo máximo da faixa ultrapassado! Ainda restam '' +' + sLineBreak +
        '              IntToStr(restante div 60) + '' min e '' +' + sLineBreak +
        '              IntToStr(restante mod 60) + '' seg.'';' + sLineBreak +
        '  end;' + sLineBreak +
        'end;' + sLineBreak +
        sLineBreak +
        '// Calcule o valor final do anúncio sem recompilar o .exe.' + sLineBreak +
        'function CalcularPrecoFinal(Cliente, Faixa: string; Preco30: double; DuracaoSeg, Insercoes: integer): double;' + sLineBreak +
        'var' + sLineBreak +
        '  fator, total: double;' + sLineBreak +
        'begin' + sLineBreak +
        '  if DuracaoSeg = 15 then' + sLineBreak +
        '    fator := 0.6' + sLineBreak +
        '  else if DuracaoSeg = 60 then' + sLineBreak +
        '    fator := 2.0' + sLineBreak +
        '  else' + sLineBreak +
        '    fator := 1.0;' + sLineBreak +
        sLineBreak +
        '  total := Preco30 * fator;' + sLineBreak +
        '  total := total * Insercoes;' + sLineBreak +
        sLineBreak +
        '  if Insercoes > 20 then' + sLineBreak +
        '    total := total * 0.85;' + sLineBreak +
        sLineBreak +
        '  Result := total;' + sLineBreak +
        'end;' + sLineBreak +
        sLineBreak +
        'end.';
    1:
      Result :=
        'unit ExportacaoMapa;' + sLineBreak +
        sLineBreak +
        '// Chamada para cada linha da grade. Devolva '''' para ignorar uma linha na exportação.' + sLineBreak +
        'function FormatarLinha(Anunciante, Faixa: string; Duracao, Insercoes: integer; Valor: double): string;' + sLineBreak +
        'begin' + sLineBreak +
        '  Result := Faixa + '' | '' + Anunciante + '' | '' + IntToStr(Duracao) + ''s | '' +' + sLineBreak +
        '            IntToStr(Insercoes) + ''x | R$ '' + FormatFloat(''0.00'', Valor);' + sLineBreak +
        'end;' + sLineBreak +
        sLineBreak +
        'end.';
    2:
      Result :=
        'var' + sLineBreak +
        '  i, qtd: integer;' + sLineBreak +
        '  html, linhas: string;' + sLineBreak +
        'begin' + sLineBreak +
        '  qtd := QtdLinhas;' + sLineBreak +
        '  linhas := '''';' + sLineBreak +
        '  for i := 1 to qtd do' + sLineBreak +
        '  begin' + sLineBreak +
        '    linhas := linhas +' + sLineBreak +
        '      ''<tr>'' +' + sLineBreak +
        '      ''<td>'' + Celula(0, i) + ''</td>'' +' + sLineBreak +
        '      ''<td>'' + Celula(1, i) + ''</td>'' +' + sLineBreak +
        '      ''<td class="num">'' + Celula(2, i) + ''s</td>'' +' + sLineBreak +
        '      ''<td class="num">'' + Celula(3, i) + ''</td>'' +' + sLineBreak +
        '      ''<td class="num">R$ '' + Celula(4, i) + ''</td>'' +' + sLineBreak +
        '      ''</tr>'';' + sLineBreak +
        '  end;' + sLineBreak +
        sLineBreak +
        '  html := ''<!DOCTYPE html><html lang="pt-BR"><head><meta charset="UTF-8">'' +' + sLineBreak +
        '    ''<title>Comprovante de Inserções — Rádio FM</title><style>'' +' + sLineBreak +
        '    ''body{font-family:Segoe UI,Arial,sans-serif;margin:32px;background:#f4f6f9;color:#1e293b}'' +' + sLineBreak +
        '    ''.card{max-width:900px;margin:auto;background:#fff;padding:24px;border-radius:8px;box-shadow:0 2px 8px rgba(0,0,0,.08)}'' +' + sLineBreak +
        '    ''h1{margin:0 0 4px;color:#1e3a5f;font-size:22px}.sub{color:#64748b;margin-bottom:20px;font-size:13px}'' +' + sLineBreak +
        '    ''table{width:100%;border-collapse:collapse;margin-bottom:20px}th{background:#1e3a5f;color:#fff;text-align:left;padding:10px}'' +' + sLineBreak +
        '    ''td{padding:9px 10px;border-bottom:1px solid #e2e8f0}.num{text-align:right}'' +' + sLineBreak +
        '    ''.resumo{background:#f8fafc;padding:14px;border-left:4px solid #1e3a5f;line-height:1.7}'' +' + sLineBreak +
        '    ''</style></head><body><div class="card">'' +' + sLineBreak +
        '    ''<h1>Comprovante Geral de Inserções Comerciais</h1>'' +' + sLineBreak +
        '    ''<div class="sub">Emitido em '' + FormatDateTime(''dd/mm/yyyy hh:nn:ss'', Now) + '' via JvInterpreter</div>'' +' + sLineBreak +
        '    ''<table><thead><tr><th>Anunciante</th><th>Faixa Horária</th><th class="num">Duração</th><th class="num">Inserções</th><th class="num">Valor</th></tr></thead>'' +' + sLineBreak +
        '    ''<tbody>'' + linhas + ''</tbody></table>'' +' + sLineBreak +
        '    ''<div class="resumo">'' +' + sLineBreak +
        '    ''<strong>Faturamento Total:</strong> R$ '' + FormatFloat(''0.00'', TotalFaturamento) + ''<br>'' +' + sLineBreak +
        '    ''<strong>Maior Investidor:</strong> '' + CampeaoInvestimento + ''<br>'' +' + sLineBreak +
        '    ''<strong>Faixa com Mais Tempo Livre:</strong> '' + NomeFaixaMaisLivre +' + sLineBreak +
        '    ''</div></div></body></html>'';' + sLineBreak +
        sLineBreak +
        '  Result := html;' + sLineBreak +
        'end;';
  else
    Result := '';
  end;
end;

procedure TForm1.GarantirScriptsPadrao;
var
  i: integer;
  sl: TStringList;
begin
  ForceDirectories(PastaScripts);
  sl := TStringList.Create;
  try
    for i := 0 to 2 do
    begin
      if not FileExists(CaminhoScript(i)) then
      begin
        sl.Text := ScriptPadrao(i);
        sl.SaveToFile(CaminhoScript(i));
      end;
    end;
  finally
    sl.Free;
  end;
end;

procedure TForm1.CarregarScriptNoEditor(indice: integer);
begin
  if FileExists(CaminhoScript(indice)) then
    memScript.Lines.LoadFromFile(CaminhoScript(indice))
  else
    memScript.Lines.Text := ScriptPadrao(indice);
end;

function TForm1.TempoOcupado(faixa: integer): integer;
var
  i, totalSeg, dur, ins: integer;
begin
  totalSeg := 0;

  for i := 1 to grade.RowCount - 1 do
  begin
    if grade.Cells[1, i] = Grade_Radio[faixa].Nome then
    begin
      dur := StrToInt(grade.Cells[2, i]);
      ins := StrToInt(grade.Cells[3, i]);
      totalSeg := totalSeg + (dur * ins);
    end;
  end;

  Result := totalSeg;
end;

function TForm1.ValidarAgendamento: boolean;
begin
  Result := True;

  if Trim(edtNome.Text) = '' then
  begin
    ShowMessage('Informe o nome do anunciante.');
    edtNome.SetFocus;
    Result := False;
    Exit;
  end;

  if cbDuracao.ItemIndex = -1 then
  begin
    ShowMessage('Selecione a duração do spot.');
    cbDuracao.SetFocus;
    Result := False;
    Exit;
  end;

  if cbFaixa.ItemIndex = -1 then
  begin
    ShowMessage('Selecione a faixa horária.');
    cbFaixa.SetFocus;
    Result := False;
    Exit;
  end;

  if spInsercoes.Value <= 0 then
  begin
    ShowMessage('Informe pelo menos 1 inserção.');
    spInsercoes.SetFocus;
    Result := False;
    Exit;
  end;
end;

function TForm1.FaturamentoTotal: real;
var
  soma: real;
  i: integer;
begin
  soma := 0;
  for i := 1 to grade.RowCount - 1 do
    soma := soma + StrToFloat(grade.Cells[4, i]);
  Result := soma;
end;

function TForm1.FaturamentoPorFaixa(faixa: integer): real;
var
  soma: real;
  i: integer;
begin
  soma := 0;
  for i := 1 to grade.RowCount - 1 do
  begin
    if grade.Cells[1, i] = Grade_Radio[faixa].Nome then
      soma := soma + StrToFloat(grade.Cells[4, i]);
  end;
  Result := soma;
end;

function TForm1.AnuncianteMaisInvestiu: string;
var
  i, j: integer;
  nomeAtual, campeao: string;
  somaAtual, maiorSoma: real;
begin
  if grade.RowCount <= 1 then
  begin
    Result := 'Nenhum';
    Exit;
  end;

  maiorSoma := -1;
  campeao := '';

  for i := 1 to grade.RowCount - 1 do
  begin
    nomeAtual := grade.Cells[0, i];
    somaAtual := 0;

    for j := 1 to grade.RowCount - 1 do
    begin
      if SameText(grade.Cells[0, j], nomeAtual) then
        somaAtual := somaAtual + StrToFloat(grade.Cells[4, j]);
    end;

    if somaAtual > maiorSoma then
    begin
      maiorSoma := somaAtual;
      campeao := nomeAtual;
    end;
  end;

  Result := campeao + ' (R$ ' + FormatFloat('0.00', maiorSoma) + ')';
end;

function TForm1.FaixaMaisLivre: integer;
var
  i, indiceMelhor, livre, maiorLivre: integer;
begin
  indiceMelhor := 0;
  maiorLivre := -1;

  for i := 0 to 4 do
  begin
    livre := (Grade_Radio[i].LimiteMin * 60) - TempoOcupado(i);
    if livre > maiorLivre then
    begin
      maiorLivre := livre;
      indiceMelhor := i;
    end;
  end;

  Result := indiceMelhor;
end;

function TForm1.MontarRelatorio: string;
var
  i, idxLivre, livreSeg: integer;
  txt: string;
begin
  txt := 'RELATÓRIO DO DIA' + sLineBreak + sLineBreak;
  txt := txt + 'Faturamento Total: R$ ' + FormatFloat('0.00', FaturamentoTotal) + sLineBreak + sLineBreak;
  txt := txt + 'Faturamento por Faixa:' + sLineBreak;

  for i := 0 to 4 do
    txt := txt + '- ' + Grade_Radio[i].Nome + ': R$ ' +
      FormatFloat('0.00', FaturamentoPorFaixa(i)) + sLineBreak;

  txt := txt + sLineBreak + 'Anunciante que mais investiu: ' +
    AnuncianteMaisInvestiu + sLineBreak;

  idxLivre := FaixaMaisLivre;
  livreSeg := (Grade_Radio[idxLivre].LimiteMin * 60) - TempoOcupado(idxLivre);
  txt := txt + 'Faixa com mais tempo livre: ' + Grade_Radio[idxLivre].Nome +
    ' (' + IntToStr(livreSeg div 60) + ' min e ' +
    IntToStr(livreSeg mod 60) + ' seg livres)';

  Result := txt;
end;

procedure TForm1.AdicionarNaGrade(valor: real);
var
  linha: integer;
begin
  grade.RowCount := grade.RowCount + 1;
  linha := grade.RowCount - 1;

  grade.Cells[0, linha] := Trim(edtNome.Text);
  grade.Cells[1, linha] := Grade_Radio[cbFaixa.ItemIndex].Nome;
  grade.Cells[2, linha] := IntToStr(SegundosDaDuracao(cbDuracao.ItemIndex));
  grade.Cells[3, linha] := IntToStr(spInsercoes.Value);
  grade.Cells[4, linha] := FormatFloat('0.00', valor);
end;

procedure TForm1.TrocarLinhas(linhaA, linhaB: integer);
var
  col: integer;
  temp: string;
begin
  for col := 0 to grade.ColCount - 1 do
  begin
    temp := grade.Cells[col, linhaA];
    grade.Cells[col, linhaA] := grade.Cells[col, linhaB];
    grade.Cells[col, linhaB] := temp;
  end;
end;

procedure TForm1.OrdenarGrade;
var
  i: integer;
begin
  for i := grade.RowCount - 1 downto 2 do
  begin
    if IndiceDaFaixa(grade.Cells[1, i]) < IndiceDaFaixa(grade.Cells[1, i - 1]) then
      TrocarLinhas(i, i - 1)
    else
      Break;
  end;
end;

procedure TForm1.AtualizarOcupacao;
var
  faixa, ocupado, limiteSeg: integer;
begin
  if cbFaixa.ItemIndex = -1 then
  begin
    pbOcupado.Position := 0;
    lblOcupado.Caption := 'Selecione uma faixa';
    Exit;
  end;

  faixa := cbFaixa.ItemIndex;
  ocupado := TempoOcupado(faixa);
  limiteSeg := Grade_Radio[faixa].LimiteMin * 60;

  pbOcupado.Min := 0;
  pbOcupado.Max := limiteSeg;
  pbOcupado.Position := ocupado;

  lblOcupado.Caption := 'Ocupado: ' +
    IntToStr(ocupado div 60) + ' min ' +
    IntToStr(ocupado mod 60) + ' seg / ' +
    IntToStr(Grade_Radio[faixa].LimiteMin) + ' min';
end;

procedure TForm1.LimparCampos;
begin
  edtNome.Clear;
  spInsercoes.Value := 1;
  edtNome.SetFocus;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  i: integer;
begin
  Grade_Radio[0].Nome := 'Jornal da Manhã 06h–09h';
  Grade_Radio[0].Preco30 := 120;
  Grade_Radio[0].LimiteMin := 12;

  Grade_Radio[1].Nome := 'Show da Manhã 09h–12h';
  Grade_Radio[1].Preco30 := 80;
  Grade_Radio[1].LimiteMin := 10;

  Grade_Radio[2].Nome := 'Esporte no Almoço 12h–14h';
  Grade_Radio[2].Preco30 := 100;
  Grade_Radio[2].LimiteMin := 10;

  Grade_Radio[3].Nome := 'Tarde Musical 14h–18h';
  Grade_Radio[3].Preco30 := 50;
  Grade_Radio[3].LimiteMin := 8;

  Grade_Radio[4].Nome := 'Volta pra Casa 18h–20h';
  Grade_Radio[4].Preco30 := 110;
  Grade_Radio[4].LimiteMin := 12;

  cbDuracao.Items.Add('15s');
  cbDuracao.Items.Add('30s');
  cbDuracao.Items.Add('60s');

  for i := 0 to 4 do
    cbFaixa.Items.Add(Grade_Radio[i].Nome);

  grade.ColCount := 5;
  grade.RowCount := 1;
  grade.Cells[0, 0] := 'Anunciante';
  grade.Cells[1, 0] := 'Faixa';
  grade.Cells[2, 0] := 'Duração (s)';
  grade.Cells[3, 0] := 'Inserções';
  grade.Cells[4, 0] := 'Valor';

  GarantirScriptsPadrao;

  cbScript.Items.Add('1. Regras de Negócio (scripts\regras_comerciais.pas)');
  cbScript.Items.Add('2. Exportação Playout/CSV (scripts\exportacao.pas)');
  cbScript.Items.Add('3. Comprovante HTML (scripts\relatorio_html.pas)');
  cbScript.ItemIndex := 0;
  CarregarScriptNoEditor(0);

  AtualizarOcupacao;
end;

procedure TForm1.JvInterpreterProgram1GetValue(Sender: TObject;
  Identifier: string; var Value: Variant; Args: TJvInterpreterArgs;
  var Done: Boolean);
var
  col, lin: integer;
begin
  if (CompareText(Identifier, 'IntToStr') = 0) and (Args.Count = 1) then
  begin
    Value := IntToStr(Integer(Args.Values[0]));
    Done := True;
  end
  else if (CompareText(Identifier, 'FormatFloat') = 0) and (Args.Count = 2) then
  begin
    Value := FormatFloat(VarToStr(Args.Values[0]), Double(Args.Values[1]));
    Done := True;
  end
  else if (CompareText(Identifier, 'UpperCase') = 0) and (Args.Count = 1) then
  begin
    Value := UpperCase(VarToStr(Args.Values[0]));
    Done := True;
  end
  else if (CompareText(Identifier, 'SameText') = 0) and (Args.Count = 2) then
  begin
    Value := SameText(VarToStr(Args.Values[0]), VarToStr(Args.Values[1]));
    Done := True;
  end
  else if CompareText(Identifier, 'Now') = 0 then
  begin
    Value := Now;
    Done := True;
  end
  else if (CompareText(Identifier, 'FormatDateTime') = 0) and (Args.Count = 2) then
  begin
    Value := FormatDateTime(VarToStr(Args.Values[0]), TDateTime(Args.Values[1]));
    Done := True;
  end
  else if (CompareText(Identifier, 'ShowMessage') = 0) and (Args.Count = 1) then
  begin
    ShowMessage(VarToStr(Args.Values[0]));
    Value := Null;
    Done := True;
  end
  else if CompareText(Identifier, 'QtdLinhas') = 0 then
  begin
    Value := Integer(grade.RowCount - 1);
    Done := True;
  end
  else if (CompareText(Identifier, 'Celula') = 0) and (Args.Count = 2) then
  begin
    col := Integer(Args.Values[0]);
    lin := Integer(Args.Values[1]);
    if (col >= 0) and (col < grade.ColCount) and (lin >= 0) and (lin < grade.RowCount) then
      Value := grade.Cells[col, lin]
    else
      Value := '';
    Done := True;
  end
  else if CompareText(Identifier, 'TotalFaturamento') = 0 then
  begin
    Value := Double(FaturamentoTotal);
    Done := True;
  end
  else if CompareText(Identifier, 'CampeaoInvestimento') = 0 then
  begin
    Value := AnuncianteMaisInvestiu;
    Done := True;
  end
  else if CompareText(Identifier, 'NomeFaixaMaisLivre') = 0 then
  begin
    Value := Grade_Radio[FaixaMaisLivre].Nome;
    Done := True;
  end;
end;

procedure TForm1.btnAgendarClick(Sender: TObject);
var
  faixa, duracao, ocupado, limiteSeg: integer;
  valor: real;
  msgErro, cliente: string;
begin
  if not ValidarAgendamento then
    Exit;

  GarantirScriptsPadrao;
  faixa := cbFaixa.ItemIndex;
  duracao := SegundosDaDuracao(cbDuracao.ItemIndex);
  ocupado := TempoOcupado(faixa);
  limiteSeg := Grade_Radio[faixa].LimiteMin * 60;
  cliente := Trim(edtNome.Text);

  try
    JvInterpreterProgram1.Pas.LoadFromFile(CaminhoScript(0));
    JvInterpreterProgram1.Compile;

    msgErro := VarToStr(JvInterpreterProgram1.CallFunction('PodeAgendar', nil, [
      cliente,
      Grade_Radio[faixa].Nome,
      duracao,
      spInsercoes.Value,
      ocupado,
      limiteSeg
    ]));

    if Trim(msgErro) <> '' then
    begin
      sbStatus.SimpleText := 'Agendamento recusado pelo script: ' + msgErro;
      ShowMessage(msgErro);
      Exit;
    end;

    valor := Double(JvInterpreterProgram1.CallFunction('CalcularPrecoFinal', nil, [
      cliente,
      Grade_Radio[faixa].Nome,
      Grade_Radio[faixa].Preco30,
      duracao,
      spInsercoes.Value
    ]));
  except
    on E: Exception do
    begin
      sbStatus.SimpleText := 'Erro em regras_comerciais.pas: ' + E.Message;
      ShowMessage('Erro no script regras_comerciais.pas: ' + E.Message);
      Exit;
    end;
  end;

  AdicionarNaGrade(valor);
  OrdenarGrade;
  AtualizarOcupacao;
  LimparCampos;
  sbStatus.SimpleText := 'Agendamento de "' + cliente + '" calculado via JvInterpreter (R$ ' + FormatFloat('0.00', valor) + ').';
end;

procedure TForm1.btnExportarClick(Sender: TObject);
var
  i: integer;
  linhaTxt, caminhoSaida: string;
  saida: TStringList;
begin
  if grade.RowCount <= 1 then
  begin
    ShowMessage('Nenhum comercial agendado para exportar.');
    Exit;
  end;

  GarantirScriptsPadrao;
  saida := TStringList.Create;
  try
    try
      JvInterpreterProgram1.Pas.LoadFromFile(CaminhoScript(1));
      JvInterpreterProgram1.Compile;

      for i := 1 to grade.RowCount - 1 do
      begin
        linhaTxt := VarToStr(JvInterpreterProgram1.CallFunction('FormatarLinha', nil, [
          grade.Cells[0, i],
          grade.Cells[1, i],
          StrToInt(grade.Cells[2, i]),
          StrToInt(grade.Cells[3, i]),
          StrToFloat(grade.Cells[4, i])
        ]));

        if Trim(linhaTxt) <> '' then
          saida.Add(linhaTxt);
      end;

      caminhoSaida := ExtractFilePath(Application.ExeName) + 'mapa_exportado.txt';
      saida.SaveToFile(caminhoSaida);
      sbStatus.SimpleText := 'Exportado para mapa_exportado.txt (' + IntToStr(saida.Count) + ' linhas).';
      OpenDocument(caminhoSaida);
    except
      on E: Exception do
      begin
        sbStatus.SimpleText := 'Erro em exportacao.pas: ' + E.Message;
        ShowMessage('Erro no script exportacao.pas: ' + E.Message);
      end;
    end;
  finally
    saida.Free;
  end;
end;

procedure TForm1.btnHtmlClick(Sender: TObject);
var
  slHtml: TStringList;
  caminhoHtml: string;
begin
  if grade.RowCount <= 1 then
  begin
    ShowMessage('Nenhum comercial agendado para gerar o comprovante.');
    Exit;
  end;

  GarantirScriptsPadrao;
  slHtml := TStringList.Create;
  try
    try
      JvInterpreterProgram1.Pas.LoadFromFile(CaminhoScript(2));
      JvInterpreterProgram1.Run;
      slHtml.Text := VarToStr(JvInterpreterProgram1.VResult);

      caminhoHtml := ExtractFilePath(Application.ExeName) + 'relatorio_dia.html';
      slHtml.SaveToFile(caminhoHtml);
      sbStatus.SimpleText := 'Comprovante HTML gerado e aberto no navegador.';
      OpenDocument(caminhoHtml);
    except
      on E: Exception do
      begin
        sbStatus.SimpleText := 'Erro em relatorio_html.pas: ' + E.Message;
        ShowMessage('Erro no script relatorio_html.pas: ' + E.Message);
      end;
    end;
  finally
    slHtml.Free;
  end;
end;

procedure TForm1.btnRelatorioClick(Sender: TObject);
begin
  if grade.RowCount <= 1 then
  begin
    ShowMessage('Nenhum comercial agendado ainda.');
    Exit;
  end;

  ShowMessage(MontarRelatorio);
end;

procedure TForm1.cbFaixaChange(Sender: TObject);
begin
  AtualizarOcupacao;
end;

procedure TForm1.cbScriptChange(Sender: TObject);
begin
  if cbScript.ItemIndex >= 0 then
    CarregarScriptNoEditor(cbScript.ItemIndex);
end;

procedure TForm1.btnSalvarScriptClick(Sender: TObject);
begin
  if cbScript.ItemIndex < 0 then
    Exit;

  ForceDirectories(PastaScripts);
  memScript.Lines.SaveToFile(CaminhoScript(cbScript.ItemIndex));
  sbStatus.SimpleText := 'Script salvo em ' + ExtractFileName(CaminhoScript(cbScript.ItemIndex)) + ' (já ativo sem recompilar!).';
  ShowMessage('Script salvo! As alterações já valem imediatamente.');
end;

procedure TForm1.btnRestaurarScriptClick(Sender: TObject);
begin
  if cbScript.ItemIndex < 0 then
    Exit;

  memScript.Lines.Text := ScriptPadrao(cbScript.ItemIndex);
  ForceDirectories(PastaScripts);
  memScript.Lines.SaveToFile(CaminhoScript(cbScript.ItemIndex));
  sbStatus.SimpleText := 'Script padrão restaurado para ' + ExtractFileName(CaminhoScript(cbScript.ItemIndex)) + '.';
end;

end.
