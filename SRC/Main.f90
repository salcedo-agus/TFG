program TFG
    use rocket_types
    use typical_data
    implicit none
    type(Rocket_t) Rocket
    integer i 

    call data_entry(Rocket)

    !#### PRE-STAGING ###########################
    call Payload_Mass_calculator(Rocket)
    call orbit_speed_calculator 

    call STAGING_LOOP(Rocket) 
    
    !#### PRE-SIMULATION ########################
    call rocket_geometry_calculation(Rocket)
    call sub_systems_calculation(Rocket) 

    do i=1, Rocket%number_of_stages
        print*, "==========================================="
        print*, "Stage N", i 
        print*, "ISP:               ", Rocket%stage(i)%ISP
        print*, "Exhaust velocity:  ", Rocket%stage(i)%nu_e
        print*, "Initial stage mass:", Rocket%stage(i)%m_i
        print*, "Propellant mass:   ", Rocket%stage(i)%m_p
        print*, "Structure mass:    ", Rocket%stage(i)%m_s
        print*, "Mass ratio:        ", Rocket%stage(i)%k_m
        print*, "Structure Ratio:   ", Rocket%stage(i)%k_s
        print*, "Diameter:          ", Rocket%stage(i)%Diameter
        print*, "Length:            ", Rocket%stage(i)%Length
    end do

    do i=1, Rocket%number_of_stages
        print*, "=========SUB-SYSTEMS======================="
        print*, "Stage N", i 
        print*, "Unpr. str. mass:              ", Rocket%stage(i)%m_unpr_str
        print*, "Start-up propellant mass:     ", Rocket%stage(i)%m_p_start_up
        print*, "Aditional propellant mass:    ", Rocket%stage(i)%m_p_aditional
        print*, "Wiring mass:                  ", Rocket%stage(i)%m_wiring
        print*, "Avionics mass:                ", Rocket%stage(i)%m_avionics
        print*, "Engine mass:                  ", "~"
        print*, "Fuel tank mass:               ", Rocket%stage(i)%tank(1)%m_shell
        print*, "Fuel tank insulation mass:    ", Rocket%stage(i)%tank(1)%m_insulation
        print*, "Oxidizer tank mass:           ", Rocket%stage(i)%tank(2)%m_shell
        print*, "Oxidizer tank insulation mass:", Rocket%stage(i)%tank(2)%m_insulation
    end do 
end program