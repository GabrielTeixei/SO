#!/bin/bash
# Taxas de Leitura/Escrita de processos em bash
#
# Gabriel Texeira Nª:107876  -> 50%
# Marta Inácio Nª:107826     -> 50%



segundos=${@: -1}  	     #Variavél que contém o argumento passado na linha de comandos correspondente ao número de segundos  
num='^[0-9]+([.][0-9]+)?$'   #Variavél que contém a expressão regex para verificar se o argumento passado é um número inteiro
nProc=0                      #Variavél correspondente ao número de processos a mostrar no terminal 
r=0                          #Variavél utilizada para definir ordem de ordenação da Tabela no terminal

declare -A procs=()   #Array associativo onde está guardada a informação de cada processo, para aceder á informação de cada processo usamos o PID
declare -A args=()    #Array associativo onde está guardada a informação das opções passadas como argumentos
declare -A read=()    #Array associativo onde está guardada a informação do valor de leitura de bytes de cada processo
declare -A write=()   #Array associativo onde está guardada a informação do valor de escrita de bytes de cada processo


function menu() {	#Função que lista todas as opções de utilização válidas
    echo "" 
    echo "                                  Menu                                                "
    echo "Opções de seleção de processos:"
    echo ""
    echo "    -c     -> Seleção por uma expressão regular"
    echo "    -u     -> Seleção pelo nome do utilizador"
    echo "    -s     -> Seleção por um periodo temporal(data mínima)"
    echo "    -e     -> Seleção por um periodo temporal(data máxima)"
    echo "    -m     -> Seleção por gama de PID(Pid minimo)"
    echo "    -M     -> Seleção de processos da tabela por gama de PID- Pid máximo"
    echo "    -p     -> Seleção de número de processos a visualizar"
    echo ""
    echo "Opção de ordenação da tabela:"
    echo ""
    echo "    -w     -> Ordenação da tabela por valores do write(ratew)"
    echo "    -r     -> Ordenação reversa"
}


while getopts "c:u:s:e:m:M:p:wr" option; do   #Análise da informação passada por cada argumento de entrada

    #Guarda as opções passadas ao correr a script, guardando "nada" nas opções que não são passadas
    if [[ -z "$OPTARG" ]]; then
        args[$option]="nada"
    else
        args[$option]=${OPTARG}
    fi

    case $option in
    
    #Verificação que o argumento passado com a opção -c é válido para a seleção de processos por uma expressão regex
    c)  padrao=${args['c']}
        if [[ $padrao == 'nada' || ${padrao:0:1} == "-" || $padrao =~ $num ]]; then
            echo "Argumento de '-c' não foi preenchido, foi introduzido argumento inválido ou chamou sem '-' atrás da opção passada." >&2
            menu
            exit 1
        fi
        ;;
        
    #Verificação que o argumento passado com a opção -u é válido para a seleção de processos pelo nome do utilizador
    u)  util=${args['u']}
        if [[ $util == 'nada' || ${util:0:1} == "-" || $util =~ $num ]]; then
            echo "Argumento de '-u' não foi preenchido, foi introduzido argumento inválido ou chamou sem '-' atrás da opção passada." >&2
            menu
            exit 1
        fi
        ;;
        
    #Verificação que o argumento passado com a opção -s é válido para a seleção de processos por um periodo temporal, neste caso data mínima
    s)  dateMin=${args['s']}
        regData='^((Jan(uary)?|Feb(ruary)?|Mar(ch)?|Apr(il)?|May|Jun(e)?|Jul(y)?|Aug(ust)?|Sep(tember)?|Oct(ober)?|Nov(ember)?|Dec(ember)?)) +[0-9]{1,2} +[0-9]{1,2}:[0-9]{1,2}'
        if [[ $dateMin == 'nada' || ${dateMin:0:1} == "-" || $dateMin =~ $num || ! "$dateMin" =~ $regData ]]; then
            echo "Argumento de '-s' não foi preenchido, foi introduzido argumento inválido ou chamou sem '-' atrás da opção passada." >&2
            menu
            exit 1
        fi
        ;;
        
    #Verificação que o argumento passado com a opção -e é válido para a seleção de processos por um período temporal, neste caso data máxima
    e)  dateMax=${args['e']}
        regData='^((Jan(uary)?|Feb(ruary)?|Mar(ch)?|Apr(il)?|May|Jun(e)?|Jul(y)?|Aug(ust)?|Sep(tember)?|Oct(ober)?|Nov(ember)?|Dec(ember)?)) +[0-9]{1,2} +[0-9]{1,2}:[0-9]{1,2}'
        if [[ $dateMax == 'nada' || ${dateMax:0:1} == "-" || $dateMax =~ $num || ! "$dateMax" =~ $regData ]]; then
            echo "Argumento de '-e' não foi preenchido, foi introduzido argumento inválido ou chamou sem '-' atrás da opção passada." >&2
            menu
            exit 1
        fi
        ;;
        
    #Verificação que o argumento passado com a opção -m é válido para a seleção de processos por uma gama de PID, neste caso PID mínimo
    m)  pidMin=${args['m']}
        if ! [[ $pidMin =~ $num ]]; then
            echo "Argumento de '-m' tem de ser um número ou chamou sem '-' atrás da opção passada." >&2
            menu
            exit 1
        fi
        ;;
        
    #Verificação que o argumento passado com a opção -M é válido para a seleção de processos por uma gama de PID, neste caso PID máximo
    M)  pidMax=${args['M']}
        if ! [[ $pidMax =~ $num ]]; then
            echo "Argumento de '-M' tem de ser um número ou chamou sem '-' atrás da opção passada." >&2
            menu
            exit 1
        fi
        ;;
       
    #Verificação que o argumento passado com a opção -p é válido para a seleção do número de processos a apresentar no terminal        
    p) 	nProc=${args['p']} 
        if ! [[ ${nProc} =~ $num ]]; then  
            echo "Argumento de '-p' tem de ser um número inteiro superior a 0" >&2
            menu
            exit 1
        fi
        ;;
        
    w) #Não há verificação, pois a opção não aceita argumento 

        ;;
        
    #Argumento para a ordenação da tabala a imprimir no terminal por ordem inversa
    r) 	r=1
        ;;

    #Apresenta o menu e termina com a passagem de argumentos inválidos
    *)  menu
        exit 1
        ;;
    esac

done


#Verifica se tem tem o número minimo de argumentos
if [[ $# == 0 ]]; then
    echo "Tem de passar no mínimo um argumento (segundos).">&2
    menu
    exit 1
fi

# Verifica se o último argumento passado é um número e é diferente de zero
if ! [[ $segundos =~ $num && $segundos != 0 ]]; then                      
    echo "Último argumento correspondente aos segundos tem de ser um número inteiro positivo">&2
    menu
    exit 1
fi



    for entry in /proc/[[:digit:]]*; do
        if [[ -r $entry/status && -r $entry/io ]]; then
            PID=$(cat $entry/status | grep -w Pid | tr -dc '0-9') # Obter o PID
            rchar1=$(cat $entry/io | grep rchar | tr -dc '0-9')   # Obter o rchar inicial
            wchar1=$(cat $entry/io | grep wchar | tr -dc '0-9')   # Obter o wchar inicial

            if [[ $rchar1 == 0 && $wchar == 0 ]]; then
                continue
            else
                read[$PID]=$(printf "%12d\n" "$rchar1")
                write[$PID]=$(printf "%12d\n" "$wchar1")
            fi
        fi

    done

    sleep $segundos # tempo de espera até á leitura seguinte

    for entry in /proc/[[:digit:]]*; do

        if [[ -r $entry/status && -r $entry/io ]]; then


            PID=$(cat $entry/status | grep -w Pid | tr -dc '0-9') # Obter o PID

	    #seleção por gama de PID maximo e minimo
	    if [[ -v args[m] && -v args[M] ]]; then  
                if [[ "${pidMin}" -gt "${pidMax}" ]]; then
                    echo "O PID minimo é superior ao máximo, gama inválida">&2
    		    menu
    		    exit 1
                fi
            fi
	    
	    
	    #seleção por gama de PID minimo
	    if [[ -v args[m] ]]; then                                                   
                if [[ "$PID" -lt "${pidMin}" ]]; then					
                    continue
                fi
            fi

            #seleção por gama de PID maximo
            if [[ -v args[M] ]]; then                                                       
                if [[ "$PID" -gt "${pidMax}" ]]; then                                     
                    continue
                fi
            fi

	    user=$(ps -o user= -p $PID)         #Obter o utilizador correspomdente ao PID
	    
            comm=$(cat $entry/comm | tr " " "_") # Obter o comm,e retirar os espaços e substituir por '_' nos comm's com 2 nomes
            
            
 	    #seleção pelo utilizador
            if [[ -v args[u] && ! ${util} == $user ]]; then
                continue
            fi

            #seleção de processos a utilizar atraves de uma expressão regular
            if [[ -v args[c] && ! $comm =~ ${padrao} ]]; then
                continue
            fi

            LANG=en_us_8859_1
            startDate=$(ps -o lstart= -p $PID)                                            # data de início do processo atraves do PID
            startDate=$(date +"%h %d %H:%M" -d "$startDate") 
            dateSeg=$(date -d "$startDate" +"%h %d %H:%M"+%s | awk -F '[+]' '{print $2}') # data do processo em segundos
            
            #Seleção por data máxima e minima
            if [[ -v args[s] && -v args[e] ]]; then  
            	start=$(date -d "${dateMin}" +"%h %d %H:%M"+%s | awk -F '[+]' '{print $2}') # data mínima
            	end=$(date -d "${dateMax}" +"%h %d %H:%M"+%s | awk -F '[+]' '{print $2}')                                                     
            	
                if [[ "$start" -gt "$end" ]]; then
                    echo "As datas introduzidas são incompatíveis, a data final tem de ser uma data posterior á data inicial">&2
    		    menu
    		    exit 1
                fi
            fi
            
            #Seleção por data minima
            if [[ -v args[s] ]]; then                                                       
                start=$(date -d "${dateMin}" +"%h %d %H:%M"+%s | awk -F '[+]' '{print $2}') 

                if [[ "$dateSeg" -lt "$start" ]]; then
                    continue
                fi
            fi

	     #Seleção por data máxima
            if [[ -v args[e] ]]; then                                                     
                end=$(date -d "${dateMax}" +"%h %d %H:%M"+%s | awk -F '[+]' '{print $2}') 

                if [[ "$dateSeg" -gt "$end" ]]; then
                    continue
                fi
            fi            
            

            rchar2=$(cat $entry/io | grep rchar | tr -dc '0-9') #valor do rchar após o tempo de espera
            wchar2=$(cat $entry/io | grep wchar | tr -dc '0-9') #valor do wchar após o tempo de espera
            subr=$(($rchar2-${read[$PID]})) #valor do ReadB, que é a diferença entre a primeira e segunda leitura do valor de rchar
            subw=$(($wchar2-${write[$PID]})) # valor do WriteB, que é a diferença entre a primeira e segunda leitura do valor de wchar
            rateR=$(echo "scale=2; $subr/$segundos" | bc -l) # calculo do rateR
            rateR=${rateR/#./0.}
            rateW=$(echo "scale=2; $subw/$segundos" | bc -l) # calculo do rateW
            ratew=${ratew/#./0.}

            procs[$PID]=$(printf "%-27s %-16s %15d %12d %12d %15s %15s %16s\n" "$comm" "$user" "$PID" "$subr" "$subw" "$rateR" "$rateW" "$startDate")
        fi
    done


#Cabeçalho
printf "%-27s %-16s %15s %12s %12s %15s %15s %16s\n" "COMM" "USER" "PID" "READB" "WRITEB" "RATER" "RATEW" "DATE"

#Seleção do número de processos a imprimir no cabeçalho
if [[ ${nProc} -eq 0 ]]; then
        nProc=${#procs[@]}
    fi
    
#Ordenação da tabela 
if [[ -v args[w] && $r -eq 0 ]]; then
    printf '%s \n' "${procs[@]}" | sort -n -k7 | head -n ${nProc}
elif [[ -v args[w] && $r -eq 1 ]]; then
    printf '%s \n' "${procs[@]}" | sort  -rn -k7 | head -n ${nProc}
elif [[ $r -eq 1 ]]; then
    printf '%s \n' "${procs[@]}" | sort  -rn -k1 | head -n ${nProc}
else
    printf '%s \n' "${procs[@]}" | sort -k1 | head -n ${nProc}
fi
    

