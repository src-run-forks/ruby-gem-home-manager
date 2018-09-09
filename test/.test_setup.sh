
[[ -z "${TEST_PATH}" ]] \
    && TEST_PATH="`cd $(dirname ${BASH_SOURCE[0]}) && pwd`"

export PREFIX="${PWD}/test"
export HOME="${TEST_PATH}/home"
export PATH="${PWD}/bin:${PATH}"

source "${TEST_PATH}/.test_funcs.sh"

[[ -n "${ZSH_VERSION}" ]] \
    && setopt shwordsplit

[[ -z "${SHUNIT2}"     ]] \
    && SHUNIT2="$(locate_command_shunit)"

[[ -z "${SHUNIT2}"     ]] \
    && write_fail 'Failed to locate shunit2 binary within your path!' \
    && exit 255

eval "$(ruby - <<EOF
puts "test_ruby_engine=#{defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby'};"
puts "test_ruby_version=#{RUBY_VERSION};"
puts "test_ruby_patchlevel=#{RUBY_PATCHLEVEL};"
EOF
)"

function setUp()
{
    original_env_path="${PATH}"
    original_gem_home="${GEM_HOME}"
    original_gem_path="${GEM_PATH}"

    cd "${HOME}"
}

function tearDown()
{
    GEM_HOME="${original_gem_home}"
    GEM_PATH="${original_gem_path}"
    PATH="${original_env_path}"
}

function assertPathStartsWith() {
    local srch="${1}"
    local path="${2}"
    local only="${3:-1}"


}

function assertPattern() {
  msg=''
  if [ $# -eq 3 ]; then
    msg=$1
    shift
  fi
  pattern=$1
  expected=$2

  appender_setPattern ${APP_NAME} "${pattern}"
  appender_activateOptions ${APP_NAME}
  actual=`logger_info 'dummy'`
  msg=`eval "echo \"${msg}\""`
  assertEquals "${msg}" "${expected}" "${actual}"
}


#testCategoryPattern() {
#  pattern='%c'
#  expected='shell'
#  msg="category '%c' pattern failed: '\${expected}' != '\${actual}'"
#  assertPattern "${msg}" "${expected}" "${pattern}"
#}
