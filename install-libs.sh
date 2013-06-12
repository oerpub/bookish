# Downloads a single file (like jQuery) from a remote URL
function singleFile () {
  URL=$1
  DESTINATION_NAME=$2

  echo "---- Downloading ${URL} into ${DESTINATION_NAME}"
  curl --location -o ${DESTINATION_NAME} ${URL}
}

# Downloads and unzips a snapshot of a github repo into DESTINATION_NAME
function fromGithub () {
  PROJECT_ROOT_URL=$1
  PROJECT_TAG=$2
  PROJECT_VERSION=$3
  DESTINATION_NAME=$4

  PROJECT_NAME=${PROJECT_ROOT_URL##*/}

  [ -z ${PROJECT_TAG} ] && PROJECT_TAG="master"
  [ -z ${PROJECT_VERSION} ] && PROJECT_VERSION=${PROJECT_TAG}
  [ -z ${DESTINATION_NAME} ] && DESTINATION_NAME=${PROJECT_NAME}

  echo "---- Downloading a copy of ${DESTINATION_NAME} from ${PROJECT_ROOT_URL}#${PROJECT_TAG}"
  curl --location "${PROJECT_ROOT_URL}/archive/${PROJECT_TAG}.tar.gz" | tar -xzf -
  mv "${PROJECT_NAME}-${PROJECT_VERSION}" ${DESTINATION_NAME}
}

if [ -s "scripts/libs" ]; then
  rm -R "scripts/libs"
fi
mkdir -p "scripts/libs" && cd "scripts/libs"

mkdir -p "require" && cd "require"
singleFile "http://requirejs.org/docs/release/2.1.6/comments/require.js" "require.js"
mkdir -p "plugins" && cd "plugins"
fromGithub "https://github.com/requirejs/text" "2.0.7"
fromGithub "https://github.com/jrburke/require-cs" "0.4.4"
fromGithub "https://github.com/guybedford/require-css" "0.0.6"
fromGithub "https://github.com/guybedford/require-less" "0.0.6"
fromGithub "https://github.com/SlexAxton/require-handlebars-plugin" "master"
fromGithub "https://github.com/millermedeiros/requirejs-plugins" "v1.0.2" "1.0.2"
cd "../../"

fromGithub "https://github.com/FortAwesome/Font-Awesome" "v3.1.1" "3.1.1" "font-awesome"

fromGithub "https://github.com/ivaynberg/select2" "3.4.0"
fromGithub "https://github.com/pivotal/jasmine" "v1.3.1" "1.3.1"
fromGithub "https://github.com/appendto/jquery-mockjax" "v1.5.2" "1.5.2"

singleFile "http://code.jquery.com/jquery-1.8.3.js" "jquery.js"
singleFile "https://raw.github.com/bestiejs/lodash/v1.3.0/dist/lodash.js" "lodash.js"

mkdir -p "backbone" && cd "backbone"
singleFile "https://raw.github.com/documentcloud/backbone/1.0.0/backbone.js" "backbone.js"
singleFile "https://raw.github.com/marionettejs/backbone.marionette/v1.0.3/lib/backbone.marionette.js" "backbone.marionette.js"
cd "../"

fromGithub "https://github.com/wysiwhat/Aloha-Editor" "release-oerpub-2013-04-09" "" "aloha-editor"
fromGithub "https://github.com/twitter/bootstrap" "v2.3.2" "2.3.2"
