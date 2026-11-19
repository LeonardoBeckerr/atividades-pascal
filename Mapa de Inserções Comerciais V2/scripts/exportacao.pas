unit ExportacaoMapa;

// Chamada para cada linha da grade. Devolva '' para ignorar uma linha na exportação.
function FormatarLinha(Anunciante, Faixa: string; Duracao, Insercoes: integer; Valor: double): string;
begin
  Result := Faixa + ' | ' + Anunciante + ' | ' + IntToStr(Duracao) + 's | ' +
            IntToStr(Insercoes) + 'x | R$ ' + FormatFloat('0.00', Valor);
end;

end.
