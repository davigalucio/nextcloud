# Instalação do NextCloud no linux Debian 12

apt install -y git

git clone https://github.com/davigalucio/nextcloud.git

sh nextcloud/INSTALL.SH

# Após instalar, configure seu nextcloud e execute o arquivo FIX.SH para correção das dependências:

sh nextcloud/FIX.SH

# Atenção

Ao criar o primeiro usuário admin, crie uma senha acima de 10 caracteres.
