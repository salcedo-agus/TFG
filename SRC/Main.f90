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

    open(12, file="Subsystems.txt")
    do i=1, Rocket%number_of_stages
        write(12,*) "=========SUB-SYSTEMS======================="
        write(12,*) "Stage N", i 
        write(12,*) "Diameter:                     ", Rocket%stage(i)%Diameter
        write(12,*) "Length:                       ", Rocket%stage(i)%Length
        write(12,*) "Initial stage mass:           ", Rocket%stage(i)%m_i
        write(12,*) "Propellant mass:              ", Rocket%stage(i)%m_p
        write(12,*) "Structure mass:               ", Rocket%stage(i)%m_s
        write(12,*) "Unpr. str. mass:              ", Rocket%stage(i)%m_unpr_str
        write(12,*) "Start-up propellant mass:     ", Rocket%stage(i)%m_p_start_up
        write(12,*) "Aditional propellant mass:    ", Rocket%stage(i)%m_p_aditional
        write(12,*) "Wiring mass:                  ", Rocket%stage(i)%m_wiring
        write(12,*) "Avionics mass:                ", Rocket%stage(i)%m_avionics
        write(12,*) "Engine mass:                  ", "~"
        write(12,*) "Fuel tank spherical?:         ", Rocket%stage(i)%tank(1)%Spherical
        write(12,*) "Fuel tank volume:             ", Rocket%stage(i)%tank(1)%v_total
        write(12,*) "Fuel tank surface:            ", Rocket%stage(i)%tank(1)%Surface
        write(12,*) "Fuel tank mass:               ", Rocket%stage(i)%tank(1)%m_shell
        write(12,*) "Fuel tank insulation mass:    ", Rocket%stage(i)%tank(1)%m_insulation
        write(12,*) "Oxidizer tank spherical?:     ", Rocket%stage(i)%tank(2)%Spherical
        write(12,*) "Oxidizer tank volume:         ", Rocket%stage(i)%tank(2)%v_total
        write(12,*) "Oxidizer tank surface:        ", Rocket%stage(i)%tank(2)%Surface
        write(12,*) "Oxidizer tank mass:           ", Rocket%stage(i)%tank(2)%m_shell
        write(12,*) "Oxidizer tank insulation mass:", Rocket%stage(i)%tank(2)%m_insulation
    end do 
end program