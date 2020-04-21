# shellcheck shell=bash

GDK_CHECKOUT_PATH="$(pwd)/gitlab-development-kit"

init() {
  # shellcheck disable=SC1090
  source "${HOME}"/.bash_profile
  gem install -N bundler:1.17.3
  cd gem || exit
  gem build gitlab-development-kit.gemspec
  gem install gitlab-development-kit-*.gem
  gdk init "${GDK_CHECKOUT_PATH}"
}

checkout() {
  cd "${GDK_CHECKOUT_PATH}" || exit
  git remote set-url origin "${CI_REPOSITORY_URL}"
  git fetch
  git checkout "${1}"
}

install() {
  cd "${GDK_CHECKOUT_PATH}" || exit
  netstat -lpt
  echo "> Installing GDK.."
  gdk install shallow_clone=true
  support/set-gitlab-upstream
}

update() {
  cd "${GDK_CHECKOUT_PATH}" || exit
  netstat -lpt
  echo "> Updating GDK.."
  # we use `make update` instead of `gdk update` to ensure the working directory
  # is not reset to master.
  make update
  support/set-gitlab-upstream
  restart
}

start() {
  cd "${GDK_CHECKOUT_PATH}" || exit
  killall node || true
  echo "> Starting up GDK.."
  gdk start
}

restart() {
  cd "${GDK_CHECKOUT_PATH}" || exit
  gdk stop || true
  gdk start
}

wait_for_boot() {
  echo "> Waiting 90 secs to give GDK a chance to boot up.."
  sleep 90
}
