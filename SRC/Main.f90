program TFG
    use rocket_types
    use typical_data
    implicit none
    type(Rocket_t) Rocket
    integer i 

    call data_entry(Rocket)
    call STAGING(Rocket) 
    
    do i=1, Rocket%number_of_stages
        print*, "==========================================="
        print*, "Stage N", i 
        print*, "Initial stage mass:", Rocket%stage(i)%m_0
        print*, "Propellant mass:   ", Rocket%stage(i)%m_p
        print*, "Structure mass:    ", Rocket%stage(i)%m_s
        print*, "Mass ratio:        ", Rocket%stage(i)%k_m
    end do
end program