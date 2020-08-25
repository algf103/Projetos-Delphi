unit UPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.Variants, System.Classes, System.SysUtils, System.IniFiles,  System.StrUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls,
  Vcl.Grids, Vcl.Imaging.jpeg, Vcl.Buttons, Globals;


type
  TfrmPrincipal = class(TForm)
    sbTempo: TStatusBar;
    TimerContador: TTimer;
    btnVotar: TButton;
    panMsg: TPanel;
    labTitMsg: TLabel;
    Panel1: TPanel;
    edLogin: TEdit;
    stextLogin: TStaticText;
    edSenha: TEdit;
    StaticText1: TStaticText;
    btnAutentic: TButton;
    Panel2: TPanel;
    Image1: TImage;
    Panel3: TPanel;
    lbTipRefeicao: TLabel;
    cBoxTipRefeic: TComboBox;
    rgListEstabelec: TRadioGroup;
    sgLocEleitos: TStringGrid;
    Panel4: TPanel;
    ImgLogoVenc: TImage;
    lblVenc: TLabel;
    ImgPrincip: TImage;
    procedure TimerContadorTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnAutenticClick(Sender: TObject);
    procedure btnVotarClick(Sender: TObject);
    procedure cBoxTipRefeicChange(Sender: TObject);
    procedure edLoginKeyPress(Sender: TObject; var Key: Char);
    procedure edSenhaKeyPress(Sender: TObject; var Key: Char);
    procedure FormDestroy(Sender: TObject);

  private
    { Private declarations }
    Dia:Integer;

    IntervTempo:String;       // Tempo para avan�o do rel�gio
    IntervAdDia:String;       // Tempo de verifica��o para avan�o da semana
    IntervIniVot:String;      // Hor�rio para o in�cio da vota��o
    IntervFimVot:String;      // Hor�rio para o fim da vota��o

    Sessao:recSessao;         // Controle da Sess�o do Usu�rio

    LstUsuarios:array [1..TotUsuarios] of recCategUsuario;              // Usu�rios cadastrados
    LstVencedores:array of recVencedor;                                 // Restaurantes vencedores
    recRefeicao:array [1..TotTipRef] of recTipRefeicao;                 // Tipos de Refei��es Dispon�veis

    function VerLiberVotacao():Boolean;                                 // Verifica se est� liberada a vota��o
    function VerPermisUsuario(Login:String;Senha:String):tpCodAutent;   // Verifica se o usu�rio j� votou

    procedure InsereResultadoGrid(Nome:String;Ender:String;nVotos:Integer);  // Exibe restaurante eleito na tela
    procedure ExibeResultado();                                              // Prepara o resultado do restaurante vencedor
    procedure ApuraVotacao();                                                // Contagem de votos
    procedure BloqueiaUsuario(Login:String);                                 // Bloqueia usu�rio que j� votou
    procedure BloqueioInterface(nArea:Integer;Ativa:Boolean);                // Atualiza tela
    procedure CarregaTipoRefeicao();                                         // Carrega os dados dos tipos de refei��es dispon�veis
    procedure InicializaDados(LiberBloq:Boolean;ZeraVotos:Boolean);          // Inicializa��o dos dados dos restaurantes
    procedure InicializaGrid();                                              // Inicializa informa��es da tela de resultado
    procedure CarregaDados();                                                // Carrega informa��es dos restaurantes dispon�veis
    procedure CarregaArqIni();                                               // Carrega informa��es do arquivo Config.ini

  public
    { Public declarations }
  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

{$R *.dfm}


////////////////////////////////////////////////////////////////////////////////
// FormDestroy
////////////////////////////////////////////////////////////////////////////////
procedure TfrmPrincipal.FormDestroy(Sender: TObject);
begin
  Self.TimerContador.Enabled:=False;
end;


////////////////////////////////////////////////////////////////////////////////
// InsereResultadoGrid
//    Nome:    Nome do restaurante vencedor
//    Ender:   Endere�o do restaurante vencedor
//    nVotos:  N�mero de votos do restaurante vencedor
////////////////////////////////////////////////////////////////////////////////
procedure TfrmPrincipal.InsereResultadoGrid(Nome:String;Ender:String;nVotos:Integer);
var
  I:Integer;
begin
  for I := 1 to sgLocEleitos.RowCount-1 do
    if Self.sgLocEleitos.Cells[0,I]=Self.sbTempo.Panels[0].Text then
      begin
        Self.sgLocEleitos.Cells[1,I]:=Nome;
        Self.sgLocEleitos.Cells[2,I]:=Ender;
        if nVotos>0 then
          Self.sgLocEleitos.Cells[3,I]:=IntToStr(nVotos);
        Self.sgLocEleitos.Row:=I;
      end;
end;


////////////////////////////////////////////////////////////////////////////////
// ExibeResultado
////////////////////////////////////////////////////////////////////////////////
procedure TfrmPrincipal.ExibeResultado();
var
  iTip:Integer;
  iLoc:Integer;
  iVenc:Integer;
  TotVenc:Integer;
begin
  try
    if Self.LstVencedores<>nil then
      begin

        TotVenc:=Length(Self.LstVencedores);

        iVenc:=0;
        if TotVenc>1 then
         begin
           Randomize;
           iVenc:=Random(Length(Self.LstVencedores)); // Usado o sorteio, pois mais de um local foi vencedor
         end;

        iTip:=Self.LstVencedores[iVenc].iTipo;

        iLoc:=Self.LstVencedores[iVenc].iLocal;

        Self.LstVencedores:=nil;

        Self.BloqueioInterface(3,True);

        Self.lblVenc.Visible:=True;

        Self.ImgLogoVenc.Picture.LoadFromFile(ExtractFilePath(Application.ExeName)+'img\'+Self.recRefeicao[iTip].Locais[iLoc].Nome+'.jpg');

        Self.InsereResultadoGrid(Self.recRefeicao[iTip].Locais[iLoc].Nome,Self.recRefeicao[iTip].Locais[iLoc].Ender,Self.recRefeicao[iTip].Locais[iLoc].NroVotos);

        Self.recRefeicao[iTip].Locais[iLoc].Bloqueado:=True;

      end
    else
      begin

        Self.BloqueioInterface(3,True);

        Self.lblVenc.Visible:=False;

        Self.ImgLogoVenc.Picture.LoadFromFile(ExtractFilePath(Application.ExeName)+'img\CozinheiroTriste.jpg');

        InsereResultadoGrid('Nenhum estabelecimento foi votado!!!','',0);

      end;
  except
  end;
end;


////////////////////////////////////////////////////////////////////////////////
// ApuraVotacao
////////////////////////////////////////////////////////////////////////////////
procedure TfrmPrincipal.ApuraVotacao();
var
  I:Integer;
  J:Integer;
  MaisVotos:Integer;
begin
  MaisVotos:=0;
  try
    for I := 1 to TotTipRef do
      for J := 1 to TotTipEst do
        if (Self.recRefeicao[I].Locais[J].NroVotos>0)and(Self.recRefeicao[I].Locais[J].Bloqueado=False)then
          begin
            if Self.recRefeicao[I].Locais[J].NroVotos>MaisVotos then
              begin
                MaisVotos:=Self.recRefeicao[I].Locais[J].NroVotos;
                LstVencedores:=nil;
                SetLength(LstVencedores,1);
                LstVencedores[0].Votos:=MaisVotos;
                LstVencedores[0].iTipo:=I;
                LstVencedores[0].iLocal:=J;
              end
            else
              if Self.recRefeicao[I].Locais[J].NroVotos=MaisVotos then
                begin
                  SetLength(LstVencedores,Length(LstVencedores)+1);
                  LstVencedores[Length(LstVencedores)-1].Votos:=MaisVotos;
                  LstVencedores[Length(LstVencedores)-1].iTipo:=I;
                  LstVencedores[Length(LstVencedores)-1].iLocal:=J;
                end;
          end;
  except
  end;
end;


////////////////////////////////////////////////////////////////////////////////
// InicializaDados
////////////////////////////////////////////////////////////////////////////////
procedure TfrmPrincipal.InicializaGrid();
var
  Lin:Integer;
  Col:Integer;
begin
  for Lin := 1 to Self.sgLocEleitos.RowCount-1 do
    for Col := 1 to Self.sgLocEleitos.RowCount-1 do
      Self.sgLocEleitos.Cells[Col,Lin]:='';
end;


////////////////////////////////////////////////////////////////////////////////
// InicializaDados
//    LiberBloq: libera ou n�o o restaurante para vota��o
//    ZeraVotos: zera ou n�o os votos do restaurante
////////////////////////////////////////////////////////////////////////////////
procedure TfrmPrincipal.InicializaDados(LiberBloq:Boolean;ZeraVotos:Boolean);
var
  I:Integer;
  J:Integer;
begin
  for I := 1 to TotTipRef do
    for J := 1 to TotTipEst do
      begin
        if LiberBloq=True then
          recRefeicao[I].Locais[J].Bloqueado:=False;
        if ZeraVotos=True then
          recRefeicao[I].Locais[J].NroVotos:=0;
      end;
  for I := 1 to TotUsuarios do
    Self.LstUsuarios[I].Votou:=False;
end;


////////////////////////////////////////////////////////////////////////////////
// VerLiberSistema
////////////////////////////////////////////////////////////////////////////////
function TfrmPrincipal.VerLiberVotacao():Boolean;
var
  TempoAtual:TDateTime;
begin
  Result:=False;
  Application.ProcessMessages;
  sbTempo.Panels[2].Text:='Vota��o Encerrada!';
  TempoAtual:=StrToTime(Sessao.HoraAtual);
  if(TempoAtual>=StrToTime(IntervIniVot))and(TempoAtual<=StrToTime(IntervFimVot)) then
    begin
      sbTempo.Panels[2].Text:='Vota��o Aberta!';
      if pos('Encerrada',Self.labTitMsg.Caption)>0 then
        Self.labTitMsg.Caption:=sbTempo.Panels[2].Text;
      Result:=True;
    end
  else
    Self.labTitMsg.Caption:=sbTempo.Panels[2].Text;
end;


////////////////////////////////////////////////////////////////////////////////
// VerPermisUsuario
//    Login:  Login de autentica��o
//    Senha:  Senha de autentica��o
////////////////////////////////////////////////////////////////////////////////
function TfrmPrincipal.VerPermisUsuario(Login:String;Senha:String):tpCodAutent;
var
  I:Integer;
  Achou:Boolean;
begin
  Result:=UsuNaoEx;   // Usu�rio n�o est� cadastrado
  I:=1;
  Achou:=False;
  while(I<=TotUsuarios)and(Achou=False) do
    begin
      if (Trim(Self.LstUsuarios[I].Login)=Trim(Login))and
         (Trim(Self.LstUsuarios[I].Senha)=Trim(Senha))then
         begin
           Result:=UsuOK;     // Usu�rio OK
           if Self.LstUsuarios[I].Votou=True then
             Result:=UsuVotou;   // Usu�rio J� Votou
           Self.Sessao.NomeUsu:=Self.LstUsuarios[I].Nome;
           Achou:=True;
         end
      else
        if (Trim(Self.LstUsuarios[I].Login)=Trim(Login))and
           (Trim(Self.LstUsuarios[I].Senha)<>Trim(Senha))then
           begin
             Result:=SenNaoOK;     // Senha Inv�lida
             Achou:=True;
           end;
      Inc(I);
    end;
end;


////////////////////////////////////////////////////////////////////////////////
//  BloqueioInterface
//    nArea:  regi�o da interface que ser� bloqueada ou liberada
//            1: tela de login
//            2: tela de escolha do restaurante
//            3: tela de visualiza��o do restaurante vencedor
//    Ativa: libera��o ou bloqueio da tela
//            false: bloqueia componente
//            true: libera componente
////////////////////////////////////////////////////////////////////////////////
procedure TfrmPrincipal.BloqueioInterface(nArea:Integer;Ativa:Boolean);
begin
  case nArea of
    1:  begin
          edLogin.Enabled:=Ativa;
          edSenha.Enabled:=Ativa;
          btnAutentic.Enabled:=Ativa;
          if Ativa=False then
            begin
              edLogin.Clear;
              edSenha.Clear;
              if Trim(Self.labTitMsg.Caption)='' then
                Self.labTitMsg.Caption:='Profissional Faminto';
            end;
          ImgPrincip.Visible:=Ativa;
        end;
    2:  begin
          Self.lbTipRefeicao.Enabled:=Ativa;
          Self.cBoxTipRefeic.Enabled:=Ativa;
          Self.rgListEstabelec.Enabled:=Ativa;
          Self.btnVotar.Visible:=Ativa;
          Self.lbTipRefeicao.Visible:=Ativa;
          Self.cBoxTipRefeic.Visible:=Ativa;
          Self.rgListEstabelec.Visible:=Ativa;
          Self.btnVotar.Enabled:=Ativa;
          //Self.sbnVotar.Enabled:=Ativa;
        end;
    3:  begin
          lblVenc.Visible:=Ativa;
          ImgLogoVenc.Visible:=Ativa;
          panel4.Visible:=Ativa;
          Self.sgLocEleitos.Visible:=Ativa;
        end;
  end;
end;


////////////////////////////////////////////////////////////////////////////////
//  BloqueiaUsuario
//    Login: login do usu�rio que ser� bloqueado
////////////////////////////////////////////////////////////////////////////////
procedure TfrmPrincipal.BloqueiaUsuario(Login:String);
var
  I:Integer;
  Achou:Boolean;
begin
  I:=1;
  Achou:=False;
  while(I<=TotUsuarios)and(Achou=False) do
    begin
      if Trim(Self.LstUsuarios[I].Login)=Trim(Login) then
        begin
          Achou:=False;
          Self.LstUsuarios[I].Votou:=True;
        end;
      Inc(I);
    end;
end;


////////////////////////////////////////////////////////////////////////////////
// btnVotarClick
////////////////////////////////////////////////////////////////////////////////
procedure TfrmPrincipal.btnVotarClick(Sender: TObject);
var
  I:Integer;
  J:Integer;
begin
  for I := 1 to TotTipRef do
    if cBoxTipRefeic.Items[cBoxTipRefeic.ItemIndex]=Self.recRefeicao[I].Tipo then
      begin
        for J := 1 to TotTipEst do
          if pos(Self.recRefeicao[I].Locais[J].Nome,rgListEstabelec.Items[rgListEstabelec.ItemIndex])>0 then
            begin
              inc(Self.recRefeicao[I].Locais[J].NroVotos);
              Self.BloqueioInterface(2,False);
              Self.sbTempo.Panels[2].Text:='Usu�rio Votou!!!';
              Self.BloqueiaUsuario(Self.Sessao.LoginUsu);
              Self.BloqueioInterface(1,True);
              Self.labTitMsg.Caption:='Entre com o Login e a Senha!';
              Self.edLogin.SetFocus;
            end;
      end;
end;


////////////////////////////////////////////////////////////////////////////////
// cBoxTipRefeicSelect
////////////////////////////////////////////////////////////////////////////////
procedure TfrmPrincipal.cBoxTipRefeicChange(Sender: TObject);
var
  I:Integer;
  J:Integer;
begin
  rgListEstabelec.Items.Clear();
  for I := 1 to TotTipRef do
    if cBoxTipRefeic.Items[cBoxTipRefeic.ItemIndex]=recRefeicao[I].Tipo then
      for J := 1 to TotTipEst do
        if recRefeicao[I].Locais[J].Bloqueado=False then
          rgListEstabelec.Items.Add(recRefeicao[I].Locais[J].Nome+' - '+recRefeicao[I].Locais[J].Ender);
  rgListEstabelec.ItemIndex:=0;
end;


////////////////////////////////////////////////////////////////////////////////
// CarregaTipoRefeicao
////////////////////////////////////////////////////////////////////////////////
procedure TfrmPrincipal.CarregaTipoRefeicao();
var
  I:Integer;
begin
  cBoxTipRefeic.Items.Clear();
  for I := 1 to TotTipRef do
    cBoxTipRefeic.Items.Add(Trim(recRefeicao[I].Tipo));
  cBoxTipRefeic.ItemIndex:=0;
end;


////////////////////////////////////////////////////////////////////////////////
// btnAutenticClick
////////////////////////////////////////////////////////////////////////////////
procedure TfrmPrincipal.btnAutenticClick(Sender: TObject);
var
  CodAut:tpCodAutent;
  Msg:String;
begin

  Msg:='';

  CodAut:=VerPermisUsuario(Self.edLogin.Text,Self.edSenha.Text);

  if CodAut=UsuNaoEx then Msg:='Usu�rio n�o est� cadastrado no Sistema!';
  if CodAut=SenNaoOK then Msg:='A senha do Usu�rio n�o confere!';
  if CodAut=UsuVotou then Msg:='Esse Usu�rio j� votou!';

  if Msg<>'' then
    begin
      Self.labTitMsg.Caption:=Msg;
      if Self.edLogin.CanFocus=True then
        begin
          Self.edLogin.Clear;
          Self.edSenha.Clear;
          Self.edLogin.SetFocus;
        end;
    end
  else
    begin
      Self.Sessao.PodeVotar:=True;
      Self.Sessao.LoginUsu:=Self.edLogin.Text;
      Self.BloqueioInterface(1,False);
      Self.BloqueioInterface(2,True);
      Self.BloqueioInterface(3,False);
      Self.CarregaTipoRefeicao();
      Self.cBoxTipRefeicChange(Sender);
      Self.cBoxTipRefeic.SetFocus;
      Self.labTitMsg.Caption:='Ol� '+Trim(LeftStr(Self.Sessao.NomeUsu,pos(' ',Self.Sessao.NomeUsu)))+', escolha o restaurante e vote!!';
    end;

end;


////////////////////////////////////////////////////////////////////////////////
// edSenhaKeyPress
////////////////////////////////////////////////////////////////////////////////
procedure TfrmPrincipal.edSenhaKeyPress(Sender: TObject; var Key: Char);
begin
  if(key=#13)or(Key=#9)then
    Self.btnAutenticClick(Sender);
end;


////////////////////////////////////////////////////////////////////////////////
// edLoginKeyPress
////////////////////////////////////////////////////////////////////////////////
procedure TfrmPrincipal.edLoginKeyPress(Sender: TObject; var Key: Char);
begin
  if(key=#13)or(Key=#9)then
    self.edSenha.SetFocus;
end;


////////////////////////////////////////////////////////////////////////////////
// CarregaDados
////////////////////////////////////////////////////////////////////////////////
procedure TfrmPrincipal.CarregaDados();
begin

  recRefeicao[1].Tipo:='Massas';
  recRefeicao[1].Locais[1].Nome:='Usina das Massas';
  recRefeicao[1].Locais[1].Ender:='Dr. Eduardo Chartier, 969 Higien�polis';
  recRefeicao[1].Locais[2].Nome:='Atelier de Massas';
  recRefeicao[1].Locais[2].Ender:='Riachuelo, 1482 - Centro Hist�rico';
  recRefeicao[1].Locais[3].Nome:='Puppi Baggio';
  recRefeicao[1].Locais[3].Ender:='Dinarte Ribeiro, 155 � Moinhos de Vento';
  recRefeicao[1].Locais[4].Nome:='Casa DiPaolo';
  recRefeicao[1].Locais[4].Ender:='Rua Eduardo Chaves, esq. Avenida dos Estados (Boulevard La�ador) - S�o Jo�o';
  recRefeicao[1].Locais[5].Nome:='Cozy Gastronomia';
  recRefeicao[1].Locais[5].Ender:='Comendador Rheingantz, 705 � Auxiliadora';

  recRefeicao[2].Tipo:='Churrascarias';
  recRefeicao[2].Locais[1].Nome:='Porto Alegrense';
  recRefeicao[2].Locais[1].Ender:='Av. Par�, 913 - S�o Geraldo';
  recRefeicao[2].Locais[2].Nome:='Barranco';
  recRefeicao[2].Locais[2].Ender:='Av. Prot�sio Alves, 1578 - Alto Petr�polis';
  recRefeicao[2].Locais[3].Nome:='El Fuego';
  recRefeicao[2].Locais[3].Ender:='R. Ol�vo Barreto Viana, 36 - Loja 336 - Moinhos de Vento';
  recRefeicao[2].Locais[4].Nome:='Freio de Ouro';
  recRefeicao[2].Locais[4].Ender:='Jos� de Alencar, 460 - Menino Deus';
  recRefeicao[2].Locais[5].Nome:='Schneider';
  recRefeicao[2].Locais[5].Ender:='Av. Bahia, 29 - Navegantes';

  recRefeicao[3].Tipo:='Comida Japonesa';
  recRefeicao[3].Locais[1].Nome:='Samb� Sushi';
  recRefeicao[3].Locais[1].Ender:='Fernandes Vieira, 502 - Bom Fim';
  recRefeicao[3].Locais[2].Nome:='Tak�do';
  recRefeicao[3].Locais[2].Ender:='Carvalho Monteiro, 397 - Bela Vista';
  recRefeicao[3].Locais[3].Nome:='Sushi Maru';
  recRefeicao[3].Locais[3].Ender:='Av. Cear�, 1942 - S�o Geraldo';
  recRefeicao[3].Locais[4].Nome:='Tch�maki';
  recRefeicao[3].Locais[4].Ender:='Av. Wenceslau Escobar, 2835 - Tristeza';
  recRefeicao[3].Locais[5].Nome:='SushiSeninha';
  recRefeicao[3].Locais[5].Ender:='Largo Jornalista Gl�nio P�res, 47 & 45 - Centro Hist�rico';

  recRefeicao[4].Tipo:='Comida �rabe';
  recRefeicao[4].Locais[1].Nome:='Baalbek';
  recRefeicao[4].Locais[1].Ender:='Dr. Tim�teo, 272 - Floresta';
  recRefeicao[4].Locais[2].Nome:='Lubnnan';
  recRefeicao[4].Locais[2].Ender:='Av. Crist�v�o Colombo, 727 - Independ�ncia';
  recRefeicao[4].Locais[3].Nome:='Al Nur';
  recRefeicao[4].Locais[3].Ender:='Av. Prot�sio Alves, 616 - Santa Cecilia';
  recRefeicao[4].Locais[4].Nome:='Damask';
  recRefeicao[4].Locais[4].Ender:='R. Sofia Veloso, 61 - Cidade Baixa';
  recRefeicao[4].Locais[5].Nome:='Zaituna';
  recRefeicao[4].Locais[5].Ender:='Rua Felicissimo de Azevedo 950';

  recRefeicao[5].Tipo:='Comida Italiana';
  recRefeicao[5].Locais[1].Nome:='Peppo Cucina';
  recRefeicao[5].Locais[1].Ender:='Rua Dona Laura, 161 - Rio Branco';
  recRefeicao[5].Locais[2].Nome:='Puppi Baggio';
  recRefeicao[5].Locais[2].Ender:='Dinarte Ribeiro, 155 - Moinhos de Vento';
  recRefeicao[5].Locais[3].Nome:='Copacabana';
  recRefeicao[5].Locais[3].Ender:='Pra�a Garibaldi, 2 - Cidade Baixa';
  recRefeicao[5].Locais[4].Nome:='Via Imperatore';
  recRefeicao[5].Locais[4].Ender:='R. da Rep�blica, 509 - Cidade Baixa';
  recRefeicao[5].Locais[5].Nome:='Casa do Marqu�s';
  recRefeicao[5].Locais[5].Ender:='R. Marqu�s do Pombal, 1814 - Higien�polis';

  recRefeicao[6].Tipo:='Pizzarias';
  recRefeicao[6].Locais[1].Nome:='Cia das Pizzas';
  recRefeicao[6].Locais[1].Ender:='Av. Pl�nio Brasil Milano, 2356 - Passo d Areia';
  recRefeicao[6].Locais[2].Nome:='O Bar�o';
  recRefeicao[6].Locais[2].Ender:='Av. Prot�sio Alves, 6629 � Jardim Itu-Sabar�';
  recRefeicao[6].Locais[3].Nome:='Chat� Pizzaria';
  recRefeicao[6].Locais[3].Ender:='Rua Jary, 704 - Passo d Areia';
  recRefeicao[6].Locais[4].Nome:='Taglio Pizza Romana';
  recRefeicao[6].Locais[4].Ender:='Marqu�s do Herval, 82 - Moinhos de Vento';
  recRefeicao[6].Locais[5].Nome:='La Pizza Mia';
  recRefeicao[6].Locais[5].Ender:='R. Carlos Trein Filho, 91 - Auxiliadora';

  recRefeicao[7].Tipo:='Comida Vegetariana';
  recRefeicao[7].Locais[1].Nome:='Nataraj';
  recRefeicao[7].Locais[1].Ender:=' R. Iete, 454 - Tristeza';
  recRefeicao[7].Locais[2].Nome:='V� Emp�rio e Restaurante Vegano';
  recRefeicao[7].Locais[2].Ender:='Av. Lageado, 1265 - Petr�polis';
  recRefeicao[7].Locais[3].Nome:='Prato Verde';
  recRefeicao[7].Locais[3].Ender:='Rua Santa Terezinha, 42 - Bom Fim';
  recRefeicao[7].Locais[4].Nome:='Mantra Gastronomia e Arte';
  recRefeicao[7].Locais[4].Ender:='Castro Alves, 465 - Independ�ncia';
  recRefeicao[7].Locais[5].Nome:='Raw Porto Alegre';
  recRefeicao[7].Locais[5].Ender:='Tomaz Flores, 144 - Independ�ncia';

  recRefeicao[8].Tipo:='Lanches';
  recRefeicao[8].Locais[1].Nome:='McDonalds';
  recRefeicao[8].Locais[1].Ender:='Av. Ipiranga, 6681 - Partenon';
  recRefeicao[8].Locais[2].Nome:='Cachorro-quente do Ros�rio';
  recRefeicao[8].Locais[2].Ender:='Pra�a Dom Sebasti�o, 02 - Independ�ncia';
  recRefeicao[8].Locais[3].Nome:='Speed Lanches';
  recRefeicao[8].Locais[3].Ender:=' Gen. Lima e Silva, 427 - Cidade Baixa';
  recRefeicao[8].Locais[4].Nome:='Moita Lanches';
  recRefeicao[8].Locais[4].Ender:='Av. Ipiranga, 2800 - Rio Branco';
  recRefeicao[8].Locais[5].Nome:='Cavanhas';
  recRefeicao[8].Locais[5].Ender:='Gen. Lima e Silva, 274 - Cidade Baixa';

  Self.InicializaDados(True,True);

end;


////////////////////////////////////////////////////////////////////////////////
// CarregaArqIni
////////////////////////////////////////////////////////////////////////////////
procedure TfrmPrincipal.CarregaArqIni();
var
  I:Integer;
  ArqIni:TiniFile;
begin

  ArqIni:=TIniFile.Create(ExtractFilePath(Application.ExeName)+'Config.ini');

  try
    for I := 1 to TotUsuarios do
      begin
        Self.LstUsuarios[I].Login:=ArqIni.ReadString('Usuarios','LOGIN'+i.ToString(),'');
        Self.LstUsuarios[I].Senha:=ArqIni.ReadString('Usuarios','SENHA'+i.ToString(),'');
        Self.LstUsuarios[I].Nome:=ArqIni.ReadString('Usuarios','NOME'+i.ToString(),'');
        Self.LstUsuarios[I].Votou:=False;
      end;

    Self.Dia:=ArqIni.ReadInteger('Propriedades','DIAINICIAL',1);
    Self.IntervTempo:=ArqIni.ReadString('Propriedades','SALTOTEMPO','00:05:00');
    Self.IntervAdDia:=FormatDateTime('hh:nn:ss',StrToTime('23:59:59')-StrToTime(Self.IntervTempo)+StrToTime('00:00:01'));
    Self.IntervIniVot:=ArqIni.ReadString('Propriedades','TEMPVOTINI','00:00:01');
    Self.IntervFimVot:=ArqIni.ReadString('Propriedades','TEMPVOTFIN','11:00:00');
                       FormatDateTime('hh:nn:ss',StrToTime('23:59:59')-StrToDateTime(Self.IntervTempo))
  finally
    ArqIni.Destroy;
  end;

end;


////////////////////////////////////////////////////////////////////////////////
// TimerContadorTimer
////////////////////////////////////////////////////////////////////////////////
procedure TfrmPrincipal.TimerContadorTimer(Sender: TObject);
var
  LiberaVotacao:Boolean;
begin
  if TimerContador.Enabled then
    begin

      Sessao.HoraAtual:=TimeToStr(StrToTime(sbTempo.Panels[1].Text)+StrToTime(IntervTempo));
      sbTempo.Panels[1].Text:=Sessao.HoraAtual;

      // Avan�o do dia
      if StrToTime(Sessao.HoraAtual)>=StrToTime(IntervAdDia) then
        begin
          Inc(Dia);
          // Avan�o da semana
          if Dia>7 then
            begin
              Dia:=1;
              Self.InicializaDados(True,True);
              Self.InicializaGrid();
            end;
        end;
       Sessao.DiaSAtual:=ObtDiaSemana(Dia);
       sbTempo.Panels[0].Text:=Sessao.DiaSAtual;

       LiberaVotacao:=VerLiberVotacao();

       if LiberaVotacao=True then
         begin
           if Self.Sessao.PodeVotar=False then
             begin
               Self.InicializaDados(False,True);
               Self.Sessao.PodeVotar:=True;
               Self.BloqueioInterface(1,LiberaVotacao);
               Self.BloqueioInterface(3,False);
             end;
         end
       else
         begin
            if Self.Sessao.PodeVotar=True then
              begin
                Self.ApuraVotacao();
                Self.ExibeResultado();
                Self.BloqueioInterface(1,LiberaVotacao);
                Self.BloqueioInterface(2,LiberaVotacao);
                Self.Sessao.PodeVotar:=False;
              end;
          end

    end;
end;


////////////////////////////////////////////////////////////////////////////////
// FormShow
////////////////////////////////////////////////////////////////////////////////
procedure TfrmPrincipal.FormShow(Sender: TObject);
begin

  Self.sgLocEleitos.Cells[1,0]:='Local';
  Self.sgLocEleitos.Cells[2,0]:='Endere�o';
  Self.sgLocEleitos.Cells[3,0]:='N�Votos';

  Self.sgLocEleitos.ColWidths[0]:=150;
  Self.sgLocEleitos.ColWidths[1]:=210;
  Self.sgLocEleitos.ColWidths[2]:=340;
  Self.sgLocEleitos.ColWidths[3]:=60;

  Self.sgLocEleitos.Cells[0,1]:='Domingo';
  Self.sgLocEleitos.Cells[0,2]:='Segunda-Feira';
  Self.sgLocEleitos.Cells[0,3]:='Ter�a-Feira';
  Self.sgLocEleitos.Cells[0,4]:='Quarta-Feira';
  Self.sgLocEleitos.Cells[0,5]:='Quinta-Feira';
  Self.sgLocEleitos.Cells[0,6]:='Sexta-Feira';
  Self.sgLocEleitos.Cells[0,7]:='S�bado';

  Self.BloqueioInterface(2,False);
  TimerContador.Enabled:=True;
  Self.CarregaArqIni();
  Self.CarregaDados();
end;


////////////////////////////////////////////////////////////////////////////////
// FormCreate
////////////////////////////////////////////////////////////////////////////////
procedure TfrmPrincipal.FormCreate(Sender: TObject);
begin
  Dia:=3;
  Self.Sessao.PodeVotar:=False;
end;


end.
