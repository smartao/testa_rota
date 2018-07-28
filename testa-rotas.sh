#!/bin/bash
# Autor: Sergei Armando Martao
# Data: 11/10/2017
# Descricao:
#
# Regras para criar o arquivo lista
# Primeiro campo = Rede /30 do ultimos saltos, considerando que o ulitmo salto sera a rede +1, deve contar o /
# Segundo campo = Rota que essa rede possuí, deve conter o /, sera somando +1 para fazer o roteamento caso não sera /32
#
# Exemplo do arquivo lista
# 172.31.4.28/30 10.2.0.0/21
# 172.31.4.248/30 10.2.96.0/21
# 172.31.4.32/30 10.2.72.0/21
# 172.31.4.72/30 10.2.56.0/21
# 172.31.4.36/30 10.2.40.0/21
#
# Gerando o arquivo
# Caso tenha as informacoes em um excel faca da seguinte forma
# Copie todos os range de WAN em um arquivo texto, nesse caso rangewan
# Copie todas as rotas de desino para um arquivo texto, nesse caso com o nome rotas
# Use o comando paste para gerar o arquivo de list Ex:
# paste -d " " rangewan rotas > lista 
#
# Exemplo do traceroute para a rede 10.2.96.1:
#traceroute -nI 10.2.96.1
# 1  10.2.1.200  1.668 ms  1.619 ms  1.564 ms
# 2  10.2.164.254  3.030 ms  3.392 ms  3.831 ms
# 3  172.31.4.29  2.609 ms  2.632 ms  2.713 ms
# 4  * * *
# 5  * * *
# 6  172.31.4.249  10.035 ms  9.494 ms  9.560 ms # <<< ULTIMO SALTO QUE ESTAMOS PROCURANDO
# 7  172.31.4.250  9.366 ms  9.218 ms  9.756 ms
# 8  10.2.196.253  9.894 ms  10.316 ms  10.017 ms
# 9  10.2.96.1  12.251 ms  20.464 ms  19.425 ms
# 
#traceroute to 10.2.56.1 (10.2.56.1), 30 hops max, 60 byte packets
# 1  10.2.172.254  1.766 ms  1.792 ms  1.794 ms
# 2  172.31.4.34  2.340 ms  2.355 ms  2.355 ms
# 3  * * *
# 4  170.84.35.14  9.258 ms  9.268 ms  9.273 ms
# 5  * * *
# 6  * * *
# 7  168.197.20.214  8.337 ms  8.864 ms  8.850 ms
# 8  172.31.4.73  8.838 ms  8.930 ms  9.921 ms # <<< ULTIMO SALTO QUE ESTAMO PROCURADO!
# 9  * * *
#10  * * *
# Ambos os traceroute foram executados com sucesso nesse exemplo o script retornara OK
# 

function MAIN(){

CONFIG # Funcao com configuracoes inicias do script
MENUINICAL # Menu principal do script

for((s=1;s<=$NUMREDES;s++)); # For contendo o numero de rotas para testar
do
	IPTEMP=`cat $ARQLISTA | awk '{print $1}' | head -n $s |  tail -n 1` # Capturando o ultimo salto para a rede destino
	SOMAOCTETO # Somando o ultimo octeto para assim identificar o IP do roteador de ultimo salto
	DESTORI=$IPMOD; # Armazenando a rede do ultimo salto, para fazer comparacao mais abaixo
	DEST=$IPCORRTEMP # DEST recebe a rede modificada, para assim identificar os ultimos saltos do traceroute

	IPTEMP=`cat $ARQLISTA | awk '{print $2}' | head -n $s | tail -n 1` # Capturando o IP de destino
	SOMAOCTETO # Somando o ultimo octeto apra assim fazer o tracert
	IP=$IPCORRTEMP # IP recebe a rede modificado somando +1 para usar no traceroute

	if [ $ORI != $DESTORI ];then # Se ORI (Rede de origem) = a Rede de Destino Traceroute sera ignorado
		traceroute -nI -w 1 -m $NSALTO $IP > $ARQLOGTEMP # Executando o traceroute e armazenando no arquivo de log temporario
		RESULTADO=`cat /tmp/log | tail -n 7 | grep -i $DEST`; # Tratando o log do traceroute, filtrando se o log contem o IP do roteador de destino
		if [ $? = 1 ];then # Verificando o resultado do comando a cima, se nos ultimos saltos não houve o IP do roteador
		 	echo -e "FALHA\t\t DESTINO: $IP" | tee -a $ARQLOG # Mostrara mensagem de falha
		else # Se nao quer dizer que foi executado com sucesso
			echo -e "OK\t\t DESTINO: $IP" | tee -a $ARQLOG # Mensagem de OK
		fi 
	else # Caso a Rede de origem e destino NAO seja diferentes
		echo -e "IGNORADO\t DESTINO: $IP" | tee -a $ARQLOG # Rota sera ignorada 
	fi
done
}

CONFIG(){

ARQLISTA=lista # Lista que contera IP do ultimo (destino) salto e Rede

ARQLOG=/tmp/teste-rota.log # Arquivo de execucao 
ARQLOGTEMP=/tmp/log # Arquivo de log temporario usado para o calculo

NSALTO=9 # Numero de saltos do traceroute
NUMREDES=`wc -l $ARQLISTA | cut -d" " -f 1` # Contando quatas linhas tem o arquivo de rede

> $ARQLOG # Criando e limpando o arquivo de log de execucao
> $ARQLOGTEMP # Criando e limpado o arquivo de log temporario

}

MENUINICAL(){
m1=0 # Definindo valor inicial de m1
while [ $m1 -ne 1 ] # enquanto diferente de 1
do
	clear # Limpando a tela
	echo "#------------------ Script teste roteamento ------------------#" 
	echo "#-------------------------------------------------------------#" 
	echo "# Qual site sera executado o script? " 
	echo "# 1 - Boa Vista" 
	echo "# 2 - Teofilo" 
	echo "# 3 - Marechal"
	echo "# 4 - Alphaville"
	echo "# 5 - Panamerica"
	echo "# 6 - Sair" 
	read -p "# R: " M1 # Lenda o que o usuário digitar
        echo "" # Pulando linha
	case $M1 in # Primeiro case
	[1-6]) # Validando se o numero esta entre 0 a 6
		case $M1 in # Definindo a acao conforme o numero digitado
			1) ORI=172.31.4.28;; #BV
			2) ORI=172.31.4.248;; #TEO
			3) ORI=172.31.4.72;; #CWB
			4) ORI=172.31.4.36;; #ALPHA
			5) ORI=172.31.4.32;; #PP
			6) exit ;; # Saindo do script
		esac # Saindo do segundo case
		m1=1 # Caso seja qualquer uma das opcoes sai do while
		;;
	*) # Caso seja diferente de a a 6	
		echo "Numero invalido, digite um valor de 0 a 6!"; sleep 2 # Mensagem avisando o usuario
		m1=0 # setando o valor de 0 e voltando para o menu principal
		;;
	esac # Saindod o primeiro case
done # Saindo do while principal

}

SOMAOCTETO(){

IPMOD=`echo $IPTEMP | cut -d\/ -f 1` # Removendo o / da rede do destino
if [ $(echo $IPTEMP | cut -d\/ -f 2) -ne 32 ];then # Se mascara não for /32
	FOC=`echo $IPMOD | cut -d. -f4` # Separando o 4 octeto 
	let FOC=$FOC+1 # Somando 4 octeto com 1
	IPTEMP2=`echo $IPMOD | cut -d. -f1-3` # pegando os 3 primeiros octeto
	IPCORRTEMP="$IPTEMP2.$FOC" # Gerando o IP com o 4 octeto somado +1
else # Caso seja /32 nao sera somando nenhum numero
	IPCORRTEMP=$IPMOD
fi	

}
MAIN; # Funcao principal do script
exit; # Saindo do script
