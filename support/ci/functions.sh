GDK_CHECKOUT_PATH="$(pwd)/gitlab-development-kit"

init() {
  source ${HOME}/.bash_profile
  gem install -N bundler:1.17.3
  cd gem
  gem build gitlab-development-kit.gemspec
  gem install gitlab-development-kit-*.gem
  gdk init ${GDK_CHECKOUT_PATH}
}

checkout() {
  cd ${GDK_CHECKOUT_PATH}
  git remote set-url origin ${CI_REPOSITORY_URL}
  git fetch
  git checkout ${1}
}

install() {
  cd ${GDK_CHECKOUT_PATH}
  netstat -lpt
  echo "> Installing GDK.."
  gdk install shallow_clone=true
  support/set-gitlab-upstream
}

update() {
  cd ${GDK_CHECKOUT_PATH}
  netstat -lpt
  echo "> Updating GDK.."
  # we use `make update` instead of `gdk update` to ensure the working directory
  # is not reset to master.
  make update
  support/set-gitlab-upstream
  restart
}

start() {
  cd ${GDK_CHECKOUT_PATH}
  killall node || true
  echo "> Starting up GDK.."
  gdk start
}

restart() {
  cd ${GDK_CHECKOUT_PATH}
  gdk stop || true
  gdk start
}
