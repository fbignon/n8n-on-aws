#!/bin/sh

set -e

# Assumindo que os arquivos .tf estão montados via volume
cd terraform

# Mostra a versão
terraform --version

# Executa o comando fornecido (init, plan, apply, etc)
exec terraform "$@"
