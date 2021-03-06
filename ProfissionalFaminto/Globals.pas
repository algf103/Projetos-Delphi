unit Globals;

interface

const
  TotTipRef   = 8;            // Tipos de Refei��es cadastradas
  TotTipEst   = 5;            // N�mero de Estabelecimentos para cada tipo de Refei��o
  TotUsuarios = 10;           // N�mero de Usu�rios cadastrados


type
  tpCodAutent = (UsuOK,SenNaoOK,UsuNaoEx,UsuVotou);

// Informa��es da Sess�o do Usu�rio
type
  recSessao = record
    HoraAtual:  String;
    DiaSAtual:  String;
    NomeUsu:    String;
    LoginUsu:   String;
    PodeVotar:  Boolean;
  end;

type
// Informa��es do restaurante Vencedor
  recVencedor = record
    Votos:  Integer;
    iTipo: Integer;         // �ndice do Tipo de Refei��o Vencedor
    iLocal: Integer;        // �ndice do Tipo de Estabelecimento Vencedor
  end;

// Categoria Estabelecimento
type
  recEstabelec = record
    Nome: String;
    Ender: String;
    Bloqueado: Boolean;
    NroVotos: Integer;
  end;

// Categoria Refei��o
type
  recTipRefeicao = record
    Tipo: String;
    Locais: array [1..TotTipEst] of recEstabelec;
  end;

// Categoria Usuario
type
  recCategUsuario = record
    Login: String;
    Senha: String;
    Nome:  String;
    Votou: Boolean;
  end;

function ObtDiaSemana(nDia:Integer):String;

implementation

////////////////////////////////////////////////////////////////////////////////
// ObtDiaSemana
//    nDia: dia da semana no formato num�rico
////////////////////////////////////////////////////////////////////////////////
function ObtDiaSemana(nDia:Integer):String;
begin
  case nDia of
    1:  Result:='Domingo';
    2:  Result:='Segunda-Feira';
    3:  Result:='Ter�a-Feira';
    4:  Result:='Quarta-Feira';
    5:  Result:='Quinta-Feira';
    6:  Result:='Sexta-Feira'
    else
        Result:='S�bado';
  end;
end;

end.
