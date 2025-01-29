
% Feasibility Analysis of a wind pumped hydroelectric storage system on the Island of Brava

% 15/12/2017

clear
%clc
load VentoCurvaPotencia.txt;  % carrega o ficheiro que tem dados de velocidade de vento
% na 1a coluna, e potencia eolica: NT150 na 2a, NTK300 na 3a, e ACSA225 na 4�.
%load Pd2022a2031.txt; % carrega os ficheiros que tem os dados de demanda horaria da rede de 2022 a 2031                       
Dados = xlsread('Brava_consumo','Carga2010-2037'); % Atenção: este comando funciona para o excel.xlsx
Pd= Dados(3:8762,9:28); % leio dados da linha 3-8762 43 da coluna 9 a 28        

%-------------------- Entrada de dados do sistema ----------------



% Brava possui 4 Grupos: (G1:Caterpillar - 320 kVA (256 KW), G2:Perkins I -500 kVA, G3:Perkins II – 500 kVA, e G4:Cummins - 400 kVA) 

% 7 CENÁRIOS PARA A SIMULAÇÃO - define-se o tipo de aerogerador a usar, a
% potência, a quantidade, potencia da turbina hidraulica e volume do
% reservatório: 
Cen = zeros(7,4); % inicializacao da matriz de cenarios
Cen(1,:) =  [150, 2, 2, 1500];
Cen(2,:) =  [300, 1, 3, 1500];

Cen(3,:) =  [150, 3, 2, 2250];
Cen(4,:) =  [225, 2, 4, 2250];

Cen(5,:) =  [225, 3, 4, 3400];
Cen(6,:) =  [300, 2, 3, 3000];
Cen(7,:) =  [300, 3, 3, 4500];

% 1a-potencia do aerogerador;
% 2a-quantidade de aerogeradores; 
% 3a-especifica a coluna onde vai pegar a potencia do aerogerador correspondente; 2(150kW), 3(225kW) e 4(300kW)
% 4a-volume do reservatório em m3

Res = zeros( size(Cen,1), 14); %inicializacao da matriz dos resultados dos n cenários 
Res2 = zeros( size(Cen,1), 8); %inicializacao da matriz dos resultados dos n cenários 


for k=1:size(Cen,1) 
    
    ano = 20; % anos do projecto
    RS= Cen(k,4); %capacidade do reservatorio em m3  ++++++++++++++++++
    ERmax= RS/3600*9.8*110; %capacidade do reservatorio em kWh 
    h=8760;%quantidade de horas de simulacao
    Er=zeros(h,ano);%inicializacao do vector-energia do reservatorio
    Erj=ERmax/2; % energia inicial no reservatorio
    Pt=zeros(h,ano);
    Pb=zeros(h,ano);
    Erej=zeros(h,ano);
    Pge=zeros(h,ano);
    Pwr=zeros(h,ano);
    nb=0.86; %eficiencia media das bombas
    nt=0.86; %eficiencia media das turbinas hidraulicas
    nw=0.97; %eficiencia electrica da conversao da potencia eolica
    Te=Cen(k,1); %potencia unitaria do aerogerador           ++++++++++++++
    ne=Cen(k,2);%numero de aerogeradores                     +++++++++++++++
    PDmin= 256*0.5; % o grupo eletrogéneo não pode funcionar abaixo de 50% da carga. 256 é a potencia em kW do grupo menor

    Pwt= ne*nw*VentoCurvaPotencia(1:h,Cen(k,3));
    % pega os 8760 horarios dos dados de potencia 
    % aerogeradores na 2, 3 ou 4a coluna e os coloc num unico vector;


    % a 2 coluna tem a potencia do Aerogerador 150 NTK, 
    %a 3a coluna sao as potencias horarias do NTK 300 e 
    % a 4a as potencias do aerogerador ACSA 27/225 
    Ptmax= mean(Pwt) % potencia nominal da turbina hidraulica
    

        % -----------------------------------------------------------------------

        for i=1:ano  % para cada ano, de 2018(1) a 2037 (20)
            

        for j=1:h %para cada hora no ano
            
            % --------------  PRODUCAO EOLICA E BOMBEAMENTO  ----------------------
            % Pwt é a potência que a turbina vai gerar
            % ou seja, total_wind_turbine_power
            % Pd é a demanda da ilha
            % consumption
            
            if Pwt(j)> Pd(j,i)*0.35    %se o parque produzir mais que o limite suportado pela rede,
                
                Pwr(j,i)= Pd(j,i)*0.35;  %injecta-se eolica no valor maximo Eir na rede e...
                
                % aproveita-se o excedente eolico para bombear para o reservatorio... 
                
                %tudo... 
                if (Pwt(j)-Pwr(j,i))*nb<(ERmax-Erj) 
                    % ...verifica se o reservatorio tem capacidade 
                    % para absorver o bombeamento de agua e potencia máxima nao é excedida 
                    Pb(j,i)=Pwt(j)-Pwr(j,i); 
                    %regista a energia gasta no bombeamento, contando com o rendimento da bomba
                    Erj = Erj + (Pwt(j)-Pwr(j,i))*nb; % energia inicial do reservatório
                    % bombea toda a energia para o reservatorio
                    
                else % ... ou bombeia parte do excedente e rejeita
                    % ainda o que o reservatorio nao consegue absorver
                    Pb(j,i)=(ERmax-Erj)/nb; %energia gasta no bombeamento
                    Erj = ERmax; % enche o reservatório
                    Erej(j,i)=(Pwt(j)-Pwr(j,i)) - (ERmax-Erj)/nb; % energia eh dissipada ou rejeitada, na quantidade que reservatorio nao pode receber
                end

            else % se o parque produzir abaixo do limite suportado pela rede, a potencia eolica eh toda injectada na rede
                %    sem passar pelo sistema hidraulico
                Pwr(j,i) = Pwt(j);
                %Er(j,i)=Erj;%reservatorio mantem o seu nivel
            end
            
            
            %--------------- energia de compensacao: hidraulica ou diesel --------
                    
            
            if (Pd(j,i)-Pwr(j,i)) <= Erj*nt %%%%verifica se reservatorio tem energia hidrica suficiente para complementar a energia eolica
                
                if (Pd(j,i)-Pwr(j,i)) <= Ptmax  % e se a hidroturbina  tem potencia suficiente.
                        Pt(j,i)= Pd(j,i)-Pwr(j,i);%turbina hidraulica  injecta o restante de electricidade na rede, e o gerador diesel nao precisa funcionar.
                        Erj = Erj - Pt(j,i)/nt; % nivel do reservatorio diminui
                
                elseif (Pd(j,i)-Pwr(j,i)) > Ptmax && (Pd(j,i)-Pwr(j,i)) <= ( Ptmax + PDmin) % 
                    Pge(j,i) = PDmin; %garante o mínimo do gerador diesel 
                    Pt(j,i)= (Pd(j,i)-Pwr(j,i))- Pge(j,i) ; %turbina hidraulica complementa tudo
                    Erj= Erj - Pt(j,i)/nt; % nivel do reservatorio diminui!!!! 

                elseif  (Pd(j,i)-Pwr(j,i)) > ( Ptmax + PDmin) % verifica se diesel e hidraulica podem funcionar juntos. O minimo que o diesel trabalha é 120 kW (30% de 400kW nominal do grupo)
                    Pt(j,i)= Ptmax; % potencia da turbina no máximo 
                    Pge(j,i)= Pd(j,i)-Pwr(j,i) - Pt(j,i); % o gerador diesel complementa o resto
                    Erj = Erj  - Ptmax/nt; % nivel do reservatorio diminui  
                end
                
            
            elseif (Pd(j,i)-Pwr(j,i)) > Erj*nt %%%%%verifica se reservatorio tem energia hidrica suficiente para complementar a energia eolica. A turbina tb nao pode atender tudo
                    
                if Erj*nt > Ptmax  && Erj*nt < ( Ptmax + PDmin) 
                    if Ptmax >= PDmin && (Pd(j,i)-Pwr(j,i))<= Ptmax % garante que Turbina fica abaixo da sua potencia
                        Pge(j,i) = PDmin; %garante o mínimo do gerador diesel 
                        Pt(j,i)= (Pd(j,i)-Pwr(j,i))- PDmin; %turbina hidraulica complementa tudo
                        Erj= Erj - Pt(j,i)/nt; % nivel do reservatorio diminui!!!! 
                    else
                        Pge(j,i) = Pd(j,i)-Pwr(j,i); % gerador diesel produz tudo pq nao pode produzir abaixo de 120
                    end
        
                elseif  Erj*nt > ( Ptmax + PDmin) % verifica se diesel e hidraulica podem funcionar juntos. O minimo que o diesel trabalha é 120 kW (30% de 400kW nominal do grupo)
                    Pt(j,i)= Ptmax; % potencia da turbina no máximo 
                    Pge(j,i)= Pd(j,i)-Pwr(j,i) - Pt(j,i); % o gerador diesel complementa o resto
                    Erj= Erj - Ptmax/nt; % nivel do reservatorio diminui  
                else
                    Pge(j,i)= Pd(j,i)-Pwr(j,i); % só diesel garante o consumo menor que 120 kW
                end
                        
                
            end
            
            
            Er(j,i)=Erj;%armazena o valor actual da energia do reservatorio temporariamente na variavel Erj

        end %for(j)- horas

        end %for (i)- anos

            
        % --------------------------    Resultados    --------------------------------

            plot(Er,'c');% faz o grafico dos niveis do reservatorio
            %print('-f1', '-r600', '-djpeg', 'Reservatorio')% exporta o grafico para um ficheiro Resevatorio em formato JPEG
            plot(Pge,'ro');hold on
            plot(Pt,'b');hold on
            pW = sum(Pwr)/sum(Pd)*100; % pervcentual de eólica na rede
            fprintf('Percentual de Energia eolica na rede = %3.2f \n',pW)
            pH = sum(Pt)/sum(Pd)*100; % percentual de energia hídrica na rede elétrica 
            fprintf('Percentual de Energia hidrica na rede = %3.2f \n',pH)
            pER =(sum(Pwr(:)+Pt(:)) ) /sum(Pd(:))*100; % percentual de penetracao total de Renováveis (eólica+hidro)
            fprintf('Total de RE = %3.2f \n', pER)
            ERt = sum(Pwr+Pt);  % energia renovável aproveitada (eolica injetada diretamente e hidraulica), kWh
            
            pDG = sum(Pge)/sum(Pd)*100;
            fprintf('Percentual de Energia fossil na rede = %3.2f \n', pDG)
        %       sum(Pwr)/sum(Pd)*100+sum(Pt)/sum(Pd)*100+sum(Pge)/sum(Pd)*100
            % poupanca de combustivel em metric tonnes
        %       fprintf('Toneladas metricas de gasoleo poupados: %5.2f \n',(sum(Pwr(:))+ sum(Pt(:)))*.212/0.84/1000 )
        %       fprintf('mESC poupados em gasoleo: %10.2f \n',(sum(Pwr(:))+ sum(Pt(:)))*.212/0.84*0.1122 )% poupanca de combustivel em 1000 Escudos

            fprintf('Energia eolica aproveitada : %10.2f \n',(sum(Pwr(:))+ sum(Pt(:)))/(sum(Pwt)*ano)*100)
            
            pdiss= sum(Erej(:))/(sum(Pwt(:))*ano)*100;
            fprintf('Percentual de  Energia dissipada devido a reservatorio cheio: %3.2f \n', pdiss)
            
            
            
            
            
            %--------------------Analise Economica e financeira  -----------------------
            %Custos: 
            EeC = 56554.48; % estudos e concursos 
            CTe = 2114.14*Te*ne; % custo dos aerogeradores de 1798.5 euros/kW instalado
            CTh = 1469.38*max(Pt(:)); % custo das turbinas hidraulicas de 1250 euros/kW instalado
            CBb = 1057.95*max(Pb(:)); % custo das bombas de 900 euros/kW instalado ->mm kW instalado dos aerogeradores
            CRes = 57.4*RS; % custo de reservatorio de 50 euros/m3 de volume
            CTub = 88.25*1.3*2*250; % custo de condutas de 50 euros/m. Sao duas condutas
            Ctot= (EeC+CTe+CTh+CBb+CRes+CTub)*1.15  % 15% para custos diversos 
            
            %Matriz de avaliacao financeira - AF 
            %1a linha - economia de combustivel
            %2a linha - custos de manutencao e operacao
            %3a linha - amortizacao do investimento em capital fixo
            %4a linha - reembolso ao banco em capital e juros 
            %5a linha - resultado antes dos impostos 
            %6a linha - resultado liquido do exercicio
            %7a linha - cash flow do projecto
            %8a linha - cash flow actualizado
            %9a linha - cash flow do projecto actualizado acumulado 
            
            %dados
            Pdiesel = 1.17; % preco do litro do gasoleo
            %Pdiesel = 112.2; % preco do litro do gasoleo
            CP=-0.3*Ctot; % emprestimo de 70% do valor do investimento
            CPa=-0.3*Ctot; % inicializa o cash flow actualizado acumulado. E será usado como variável auxiliar de registo. 
            r = 0.04; % juros de 4,0%/ano. 
            Tax = 0.14; % taxa de actualizacao
            t=15; % anos de emprestimo bancario 
            
            AF=zeros(9,ano); % matriz de avaliacao financeira inicializada
            
            for i=1:ano 
                    AF(1,i) = (sum(Pwr(:,i))+ sum(Pt(:,i)))*.212/.84 *Pdiesel; % poupanca de gasoleo em escudos, pela producao da eolica e hidrica e considerando que cada kWh gasta 250 gramas de gasoleo e a densidadedo gasoleo � 0.84 litros/kg
                    AF(2,i) = sum(Pwt)*0.024 + sum(Pb(:,1))*0.082; % custo de manutencao e operacao de 0.024 $/kwh eolico e $0.084/kwh de bomba
                                                % o custo por kWh/ano (referencia ano 1) da bomba abrange todos os custos do sistema hidrico
                    
                    % amortizacao do capital investido em 15 anos                         
                    if i <=15
                        AF(3,i) = Ctot/15; 
                    else AF(3,i)=0;
                    end
                    
                    %reembolso ao banco de capital e juros
                    %anos de emprestimo
                    if i<=t
                    AF(4,i) = 0.7*Ctot/t + 0.7*(Ctot-Ctot/t*(i-1))*r; % prestacoes anuais ao banco
                    else AF(4,i)=0;
                    end
                    
                    AF(5,i)= AF(1,i)- AF(2,i)- AF(3,i)- AF(4,i); %resultados antes dos impostos
                    
                    %resultados liquidos - depois dos impostos
                    if AF(5,i)>0 % so cobra imposto de 25% se resultado for positivo
                        AF(6,i)=AF(5,i)*.75; %resultadosliquido -  extraidos os impostos
                    else AF(6,i)=AF(5,i);% resultados antes e depois de imposto sao iguais pois nao ha imposto
                    end
                    
                    % cash flow do projecto
                    AF(7,i)=AF(6,i)+ AF(3,i); %soma-se resultado liquido e amortizacao
                    
                    % cash flow actualizado 
                    AF(8,i)= AF(7,i)/(1+Tax)^i;
                    
                    % cash flow actualizado acumulado 
                    AF(9,i)= CPa + AF(8,i);
                
                    CPa =  AF(9,i);%guarda o valor para ser usado na proproxima iteraccao
            
            end % for(i)
            
            
            %PAY-BACK ----------------------------------
            pback = nan; % inicializa pback com 'nan'
            for i=1:(ano-1)  
                if AF(9,i)*AF(9,i+1)<=0
                    % disp(sprintf('Pay-back = %d', i+1)) % este payback eh arredondado. O proximo eh mais preciso. 
                    pback= (-AF(9,i)*(i+1)+ i*AF(9,i+1))/(AF(9,i+1) -AF(9,i));
                    disp(sprintf('Pay-back = %2.1f', pback )) 
                else
                    % fprintf('Nao tem periodo de pay-back,\n')
                end
            end  %for  
            
            % NPV 
            NPV  = AF(9,ano);
            disp(sprintf('Net Present Value = %9.2f Esc', NPV)) ;
            %
            %IRR ou Taxa Interna de Retorno (TIR)
            TIR = irr([CP AF(7,1:ano)]); % calculo em cima do vetor formado por custo de emprestimo e os cash flow
            fprintf('TIR (ou IRR) = %9.3f \n', TIR) ;
                
            %Levelized Cost of Energy - LCOE 
            LCOE = sum( (AF(2,:)+AF(4,:))./((1+t).^(1:20))) / ( sum (ERt./((1+t).^(1:20))) ) ;
            fprintf('LCOE = %9.3f \n', LCOE) ;
            
            
            %print("reducao nos custos de producao de eletricidade ") 
            %tariff_red = 1 - (sum(Pge(:))*Ckwh_d+ sum(Pwr(:)+Pt(:))*LCOE)/sum(Pd(:))/(Ckwh_d)
            
            %# Tabelas de resultados 
            Res(k,:) = [Te*ne, max(Pb(:)), max(Pt(:)), RS, pDG, pH, pW, pER, pdiss, Ctot, NPV, pback, TIR, LCOE];
            dataset({Res 'Wind', 'Pump', 'Hydro', 'm3', 'pDG', 'pHydro', 'pWind',  'pER',  'pdiss', 'Ctot', 'NPV', 'pback', 'IRR', 'LCOE'})

            
end % for (s) - cenarios 

     
     
     
     