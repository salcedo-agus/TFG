program TFG
    use rocket_types
    use typical_data
    implicit none
    type(Rocket_t) Rocket
    integer i 

    call data_entry(Rocket)

    call orbit_speed_calculator 

    call STAGING(Rocket) 
    call stage_Thrust_calculator(Rocket)

    do i=1, Rocket%number_of_stages
        print*, "==========================================="
        print*, "Stage N", i 
        print*, "ISP:               ", Rocket%stage(i)%ISP
        print*, "Exhaust velocity:  ", Rocket%stage(i)%nu_e
        print*, "Initial stage mass:", Rocket%stage(i)%m_0
        print*, "Propellant mass:   ", Rocket%stage(i)%m_p
        print*, "Structure mass:    ", Rocket%stage(i)%m_s
        print*, "Mass ratio:        ", Rocket%stage(i)%k_m
        print*, "Structure Ratio:   ", Rocket%stage(i)%k_s
    end do
end program