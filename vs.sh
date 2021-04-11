#!/bin/bash

# primeiro parametro é função q o programa irá exercer
# as funções sao: 
# - alugar, entregar, cadastrar, deletar e listar (CRUD)

# cadastrar: inserir o nome do filme (ela checa se já existe um filme para nao remover os dados dele e nem duplicá-lo)
# alugar: Exibi a lista de filmes disponíveis e aluga com base na entrada do teclado, ao alugar seta o filme como alugado na lista
# deletar: Remove da lista de filmes
# entregar: Atualiza o filme, o colocando como disponivel
# lista - Exibi uma análise dos dados, quais os mais alugados

# ! uso de funcoes
# ! redirecionamento
# ! Parametros e variaveis (variaveis de ambiente)


# ! atribuicao de valores default a variaveis
logFile="${2:-'log.file'}" 

log()
{
  echo "$USER $1" >> "${logFile}"
}

# ! estrutura condicional
if [ ! -f "data" ]; then
  touch data
  log "create films database"
fi

# ! processamento de texto
# ! busca com awk
search()
{
  FILM=$( awk "/^$1/ { print; exit; }" data )
  echo "$FILM"
}

list()
{
  sort -r -t ":" -n -k 3 data | \
  sed -e '1 i\nome:alugado:popularidade' | \
  awk -F ":" '{ printf "\n %-20s %8s %12s" , $1, $2, $3 }' | \
  sed -e '1 i\Lista de filmes' | \
  less
}

delete()
{
  read -p "Qual filme deseja deletar? " FILM
  sed -i "/${FILM}/d" data
  echo "Filme deletado com sucesso"
  log "${FILM} deletado"
}

# ! uso de regex
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

# ! uso de regex
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

# ! redirecionamento
# ! regex
# ! uso de pipes
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

# ! leitura da entrada padrão
# ! estruturas de repetição
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

# ! expansao de comandos via $()
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

# ! estrutura condicional
# ! leitura dos parametros posicionais
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

  random)
    random
  ;;

  listar)
    list
  ;;
  
  *)
		showHelp
  ;;
esac