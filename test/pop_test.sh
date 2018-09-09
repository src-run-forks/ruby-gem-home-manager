
[[ -z "${TEST_PATH}" ]] \
    && TEST_PATH="`cd $(dirname ${BASH_SOURCE[0]}) && pwd`"

source "${TEST_PATH}/.test_setup.sh"
source "${TEST_PATH}/../share/gem_home/gem_home.sh"

function test_gem_home_pop()
{
    skip_unsupported_environments

	gem_home_push "${HOME}/project1"
	gem_home_pop

 	${_ASSERT_SAME_} '"did not remove bin/ from $PATH"' \
        "'${original_env_path}'" \
        "'${PATH}'"

	${_ASSERT_SAME_} '"did not remove gem dir from $GEM_PATH"' \
        "'${original_gem_path}'" \
        "'${GEM_PATH}'"

	${_ASSERT_SAME_} '"did not reset $GEM_HOME"' \
        "'${original_gem_home}'" \
        "'${GEM_HOME}'"
}

function test_gem_home_pop_twice()
{
    skip_unsupported_environments

	gem_home_push "${HOME}/project1"
	gem_home_push "${HOME}/project2"
	gem_home_pop
	gem_home_pop

	${_ASSERT_SAME_} '"did not remove bin/ from $PATH"' \
        "'${original_env_path}'" \
        "'${PATH}'"

	${_ASSERT_SAME_} '"did not remove gem dir from $GEM_PATH"' \
        "'${original_gem_path}'" \
        "'${GEM_PATH}'"

	${_ASSERT_SAME_} '"did not reset $GEM_HOME"' \
        "'${original_gem_home}'" \
        "'${GEM_HOME}'"
}

SHUNIT_PARENT=${0} . ${SHUNIT2}
