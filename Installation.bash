## Préciser le nom du projet (il aura une url en "${PROJECT_NAME}".test)
PROJECT_NAME=exampleproject

## Intialiser le .env
warden env-init "${PROJECT_NAME}" magento2

## Modifier la version de php si nécessaire (7.4 par défaut)
## Signer le certificat SSL du nouveau projet
warden sign-certificate "${PROJECT_NAME}".test

## Ajouter le domaine dans le /etc/host pour le rendre accessible
sudo echo "127.0.0.1 ${PROJECT_NAME}.test" >>  /etc/hosts

## Démarrer l'environnemnet
warden env up
warden shell



## Préciser la version ici
META_PACKAGE=magento/project-community-edition META_VERSION=2.4.x

## Télécharger le Projet

composer create-project --repository-url=https://repo.magento.com/ "${META_PACKAGE}"="${META_VERSION}" /tmp/exampleproject

## Déplacer le projet dans le bon répertoire
rsync -a /tmp/exampleproject/ /var/www/html/
rm -rf /tmp/exampleproject/


# Installer Magento

bin/magento setup:install --backend-frontname=admin --amqp-host=rabbitmq --amqp-port=5672 --amqp-user=guest --amqp-password=guest --db-host=db --db-name=magento --db-user=magento --db-password=magento --search-engine=elasticsearch7 --elasticsearch-host=elasticsearch --elasticsearch-port=9200 --elasticsearch-index-prefix=magento2 --elasticsearch-enable-auth=0 --elasticsearch-timeout=15 --http-cache-hosts=varnish:80 --session-save=redis --session-save-redis-host=redis --session-save-redis-port=6379 --session-save-redis-db=2 --session-save-redis-max-concurrency=20 --cache-backend=redis --cache-backend-redis-server=redis --cache-backend-redis-db=0 --cache-backend-redis-port=6379 --page-cache=redis --page-cache-redis-server=redis --page-cache-redis-db=1 --page-cache-redis-port=6379 --admin-firstname="admin" --admin-lastname="admin" --admin-email="hello@bird.eu" --admin-user="admin" --admin-password="admin123" --language="fr_FR" --currency="EUR" –timezone="Europe/Paris"


bin/magento config:set web/unsecure/base_url "https://${TRAEFIK_DOMAIN}/" --lock-env
bin/magento config:set web/secure/base_url "https://${TRAEFIK_DOMAIN}/" --lock-env
bin/magento config:set web/secure/offloader_header X-Forwarded-Proto --lock-env
bin/magento config:set --lock-env web/secure/use_in_frontend 1
bin/magento config:set --lock-env web/secure/use_in_adminhtml 1
bin/magento config:set --lock-env web/seo/use_rewrites 1
bin/magento config:set --lock-env system/full_page_cache/caching_application 2
bin/magento config:set --lock-env system/full_page_cache/ttl 604800
bin/magento config:set --lock-env catalog/search/enable_eav_indexer 1
bin/magento config:set --lock-env dev/static/sign 0
bin/magento deploy:mode:set -s developer
bin/magento cache:disable block_html full_page
bin/magento indexer:reindex
bin/magento cache:flush
bin/magento module:disable Magento_TwoFactorAuth
php bin/magento config:set admin/security/password_lifetime 0


# Installer les sample data
php -d memory_limit=-1 bin/magento sampledata:deploy
bin/magento setup:upgrade
