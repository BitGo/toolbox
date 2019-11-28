load test_helper

@test "Can not login to admin account with user key" {
	enable_key "user1"
    run ssh_command "admin"
    [ "$status" -eq 255 ]
}

@test "Can not run interactive commands on admin account" {
	enable_key "admin1"
    run ssh_command "admin" ls
    echo "${output}" | grep "not a terminal"
}

@test "Can resolve fingerprint for valid user key" {
	enable_key "user1"
    run ssh_command "user" login_fingerprint
    echo "${output}" | grep "D16AC0FA2C80E18BDF786C2F41C54D8491451FB1"
}

@test "Can resolve email for valid user key" {
	enable_key "user2"
    run ssh_command "user" login_email
    echo "${output}" | grep "user2@localhost"
}

@test "Can resolve username for valid admin key" {
	enable_key "admin2"
    run ssh_command "user" login_name
    echo "${output}" | grep "admin2"
}
