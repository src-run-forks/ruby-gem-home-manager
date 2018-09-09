
[[ -z "${TEST_PATH}" ]] \
    && TEST_PATH="`cd $(dirname ${BASH_SOURCE[0]}) && pwd`"

. "${TEST_PATH}/.test_setup.sh"
. "${TEST_PATH}/../share/gem_home/gem_home.sh"

function test_gem_home_push()
{
    skip_unsupported_environments

	local dir="${HOME}/project1"
	local expected_gem_dir="${dir}/.gem/${test_ruby_engine}/${test_ruby_version}"

	gem_home_push "${dir}"

	${_ASSERT_SAME_} '"did not set $GEM_HOME correctly"' \
        "'${expected_gem_dir}'" \
        "'${GEM_HOME}'"

    ${_ASSERT_SAME_} '"did not push path onto beginning of $GEM_PATH"' \
        "'${expected_gem_dir}${original_gem_path:+:}${original_gem_path:-}'" \
        "'${GEM_PATH}'"

	${_ASSERT_SAME_} '"did not prepend the new gem bin/ dir to $PATH"' \
        "'${expected_gem_dir}/bin:${original_env_path}'" \
        "'${PATH}'"

	gem_home_pop
}

function test_gem_home_push_relative_path()
{
    skip_unsupported_environments

	local dir="foo/../project1"
	local expected_dir="${HOME}/project1"
	local expected_gem_dir="${expected_dir}/.gem/${test_ruby_engine}/${test_ruby_version}"

	gem_home_push "${dir}"

	${_ASSERT_SAME_} '"did not expand the relative gem dir"' \
        "'${expected_gem_dir}'" \
        "'${GEM_HOME}'"

	gem_home_pop
}

function test_gem_home_push_twice()
{
    skip_unsupported_environments

	local dir1="${HOME}/project1"
	local expected_gem_dir1="${dir1}/.gem/${test_ruby_engine}/${test_ruby_version}"

	gem_home_push "${dir1}"

	local dir2="${HOME}/project2"
	local expected_gem_dir2="${dir2}/.gem/${test_ruby_engine}/${test_ruby_version}"

	gem_home_push "${dir2}"

	${_ASSERT_SAME_} '"did not set $GEM_HOME to the second gem dir"' \
		     "'${expected_gem_dir2}'" \
		     "'${GEM_HOME}'"

	${_ASSERT_SAME_} '"did not prepend both gem dirs to $GEM_PATH"' \
		     "'${expected_gem_dir2}:${expected_gem_dir1}${original_gem_path:+:}${original_gem_path:-}'" \
		     "'${GEM_PATH}'"

	${_ASSERT_SAME_} '"did not inject the new gem bin/ into $PATH"' \
		     "'${expected_gem_dir2}/bin:${expected_gem_dir1}/bin:${original_env_path}'" \
		     "'${PATH}'"

	gem_home_pop
	gem_home_pop
}

SHUNIT_PARENT=${0} . ${SHUNIT2}
