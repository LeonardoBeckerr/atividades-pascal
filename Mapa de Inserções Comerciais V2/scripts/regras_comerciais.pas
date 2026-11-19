unit RegrasComerciais;

// Devolva '' (vazio) para liberar, ou uma mensagem para bloquear o agendamento.
function PodeAgendar(Cliente, Faixa: string; DuracaoSeg, Insercoes, OcupadoSeg, LimiteSeg: integer): string;
var
  restante: integer;
begin
  Result := '';
  if OcupadoSeg + (DuracaoSeg * Insercoes) > LimiteSeg then
  begin
    restante := LimiteSeg - OcupadoSeg;
    Result := 'Tempo máximo da faixa ultrapassado! Ainda restam ' +
              IntToStr(restante div 60) + ' min e ' +
              IntToStr(restante mod 60) + ' seg.';
  end;
end;

// Calcule o valor final do anúncio sem recompilar o .exe.
function CalcularPrecoFinal(Cliente, Faixa: string; Preco30: double; DuracaoSeg, Insercoes: integer): double;
var
  fator, total: double;
begin
  if DuracaoSeg = 15 then
    fator := 0.6
  else if DuracaoSeg = 60 then
    fator := 2.0
  else
    fator := 1.0;

  total := Preco30 * fator;
  total := total * Insercoes;

  if Insercoes > 20 then
    total := total * 0.85;

  Result := total;
end;

end.
