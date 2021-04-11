#!/bin/bash

# 1! atribuicao de valores default a variaveis
logFile="${2:-file.log}" 

# 2! uso de funcoes
# 3! redirecionamento da saida padrão do echo
# 4! Parametros e variaveis (variaveis de ambiente)
log()
{
  echo "$USER $1" >> "${logFile}"
}

# 5! estrutura condicional
if [ ! -f "data" ]; then
  touch data
  log "create films database"
fi

# 6! processamento de texto com awk
search()
{
  FILM=$( awk "/^$1/ { print; exit; }" data )
  echo "$FILM"
}

list()
{
  sort -r -t ":" -n -k 3 data | \
  sed -e '1 i\NOME:ALUGADO:POPULARIDADE' | \
  awk -F ":" '{ printf "\n %-20s %8s %12s" , $1, $2, $3 }' | \
  sed -e '1 i\Lista de filmes' | \
  less
}

# 7! processamento de texto com sed
delete()
{
  read -p "Qual filme deseja deletar? " FILM
  sed -i "/${FILM}/d" data
  echo "Filme deletado com sucesso"
  log "${FILM} deletado"
}

showNotRentedFilms()
{
  header="----------- Lista de filmes disponíveis ------------"
  lines=$( wc -l data |  awk '{ print $1}')

  if [ $lines -ge 100 ]; then
    awk -F ":" '$2 ~ /0/ { print $1 }' data | \
    sed -e "1 i\ ${header}" data | \
    less
  else
    echo $header
    awk -F ":" '$2 ~ /0/ { print $1 }' data
    echo "----------------------------------------------------"
  fi
}

showRentedFilms()
{
  header="----------- Lista de filmes alugados ------------"
  lines=$( wc -l data |  awk '{ print $1}')

  if [ $lines -ge 100 ]; then
    awk -F ":" '$2 ~ /1/ { print $1 }' data | \
    sed -e "1 i\ ${header}" data | \
    less
  else
    echo $header
    awk -F ":" '$2 ~ /1/ { print $1 }' data
    echo "----------------------------------------------------"
  fi
}

# 8! uso de regex
rent()
{
  showNotRentedFilms

  while :; do
    read -p "Qual filme deseja alugar? " FILM
    result=$( search "$FILM" )
    rented=$( echo $result | awk -F ":" '{ print $2 }' )

    if [[ $rented == "0" ]]; then
      value=$( echo $result | awk -F ":" '{ print $3 }' )
      value=$(( $value + 1 ))
      sed -i "s/\(${FILM}\)\(:\)\([01]\)\(:\)\(.*$\)/\1\21\4${value}/" data
      echo "Filme alugado com sucesso!"
      log "$FILM foi alugado"
      break
    else 
      echo "O filme já está alugado, tente outro!"
    fi
    echo ""
  done
}

# 9! leitura da entrada padrão
# 10! estruturas de repetição
create()
{
  while :; do
    read -p "Insira o nome do filme: " FILM
    result=$( search "$FILM" )

    if [ -z "${result}" ]; then
      echo "${FILM}:0:0" >> data
      log "${FILM} adicionado ao database"
      echo "Filme criado com sucesso!"
      break
    else 
      echo "O filme já existe, tente outro!"
    fi
  done
}

# 11! expansao de comandos via $()
checkin()
{
  showRentedFilms

  while :; do
    read -p "Insira o nome do filme: " FILM
    result=$( search "$FILM" )

    if [ ! -z "${result}" ]; then
      sed -i "s/\(${FILM}\)\(:\)\([01]\)/\1\20/" data
      echo "Filme entregue com sucesso!"
      log "$FILM foi entregue"
      break
    else 
      echo "O filme não existe no database, tente outro!"
    fi
  done
}

showHelp()
{
  echo  "
  
  Primeiro parametro é a função que o programa irá exercer, o segundo parametro opcional é o caminho do arquivo de log.

  ./vs.sh action [log_file_path]

   - cadastrar: Inserir um filme na base (nomes são únicos)
   - alugar: Aluga um filme disponível
   - deletar: Remove da lista de filmes
   - entregar: Atualiza o filme, o colocando como disponivel (checkin)
   - listar - Exibi a lista de filme ordenaos pela popularidade
  "

}

# 12! leitura dos parametros posicionais
case $1 in
  alugar)
    rent
  ;;

  cadastrar)
    create
  ;;

  entregar)
    checkin
  ;;

  deletar)
    delete
  ;;

  listar)
    list
  ;;
  
  *)
		showHelp
  ;;
esac