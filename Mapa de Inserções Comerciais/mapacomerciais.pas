unit mapacomerciais;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Spin, Grids, ComCtrls, Buttons, Types;

type
  TFaixa = record
    Nome: string;
    Preco30: real;
    LimiteMin: integer;
  end;

  { TForm1 }

  TForm1 = class(TForm)
    btnAgendar: TButton;
    btnRelatorio: TButton;
    cbDuracao: TComboBox;
    cbFaixa: TComboBox;
    edtNome: TEdit;
    gbNovo: TGroupBox;
    grade: TStringGrid;
    lblOcupado: TLabel;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    pbOcupado: TProgressBar;
    pnlTopo: TPanel;
    pnlCadastro: TPanel;
    pnlRodape: TPanel;
    pnlCentro: TPanel;
    spInsercoes: TSpinEdit;
    procedure btnAgendarClick(Sender: TObject);
    procedure btnRelatorioClick(Sender: TObject);
    procedure cbDuracaoChange(Sender: TObject);
    procedure cbFaixaChange(Sender: TObject);
    procedure edtNomeChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure gbNovoClick(Sender: TObject);
    procedure lblOcupadoClick(Sender: TObject);
    procedure pbOcupadoContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure spInsercoesChange(Sender: TObject);
  private
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

function CalcularValor(faixa, duracaoSeg, insercoes: integer): real;
var
  fator, total: real;
begin
  if duracaoSeg = 15 then
    fator := 0.6
  else if duracaoSeg = 60 then
    fator := 2
  else
    fator := 1;

  total := Grade_Radio[faixa].Preco30 * fator * insercoes;

  if insercoes > 20 then
    total := total * 0.85;

  CalcularValor := total;
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
  begin
    soma := soma + StrToFloat(grade.Cells[4, i]);
  end;
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
  txt := 'RELATÓRIO DO DIA ' + sLineBreak + sLineBreak;
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

procedure TForm1.edtNomeChange(Sender: TObject);
begin

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

  cbDuracao.Style := csDropDownList;
  cbFaixa.Style := csDropDownList;
  spInsercoes.MinValue := 1;
  spInsercoes.Value := 1;

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
  grade.ColWidths[0] := 150;
  grade.ColWidths[1] := 160;

  AtualizarOcupacao;
end;

procedure TForm1.gbNovoClick(Sender: TObject);
begin

end;

procedure TForm1.lblOcupadoClick(Sender: TObject);
begin

end;

procedure TForm1.pbOcupadoContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
begin

end;

procedure TForm1.spInsercoesChange(Sender: TObject);
begin

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

procedure TForm1.btnAgendarClick(Sender: TObject);
var
  faixa, duracao, tempoNovo, ocupado, limiteSeg, restante: integer;
  valor: real;
begin
  if not ValidarAgendamento then
    Exit;

  faixa := cbFaixa.ItemIndex;
  duracao := SegundosDaDuracao(cbDuracao.ItemIndex);
  tempoNovo := duracao * spInsercoes.Value;
  ocupado := TempoOcupado(faixa);
  limiteSeg := Grade_Radio[faixa].LimiteMin * 60;

  if ocupado + tempoNovo > limiteSeg then
  begin
    restante := limiteSeg - ocupado;
    ShowMessage('Tempo máximo da faixa ultrapassado! Ainda restam ' +
      IntToStr(restante div 60) + ' min e ' +
      IntToStr(restante mod 60) + ' seg.');
    Exit;
  end;

  valor := CalcularValor(faixa, duracao, spInsercoes.Value);

  AdicionarNaGrade(valor);
  OrdenarGrade;
  AtualizarOcupacao;
  LimparCampos;
end;

procedure TForm1.cbDuracaoChange(Sender: TObject);
begin

end;

procedure TForm1.cbFaixaChange(Sender: TObject);
begin
  AtualizarOcupacao;
end;

end.
