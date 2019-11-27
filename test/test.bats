load test_helper

@test "Admin user does not allow non interactive commands" {
    run ssh_command "admin" ls
    echo "${output}" | grep "not a terminal"
}
