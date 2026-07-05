subroutine stage_Thrust_calculator(Rocket)
    !IN:   initial mass of each stage (m_0i)
    !OUT:  Thrust (T_i) and burn time (t_burn i) of each stage 
    use typical_data
    use rocket_types
    use constants
    type(Rocket_t) Rocket
    ! This vectors are deffined as to not have inconsistencies due to diferent 
    real(8), dimension(3) :: stage_initial_mass !Vector containing the initial mass of each stage
    real(8), dimension(3) :: stage_thrust       !Vector containing the thrust of each stage


    do i=1, rocket%number_of_stages
        stage_initial_mass(i) = rocket%stage(i)%m_0
    end do

    stage_thrust(1) = 1.459d0*stage_initial_mass(1)*g_0 - 486.6d0
    stage_thrust(2) = 0.835d0*stage_initial_mass(2)*g_0 - 50.88d0
    stage_thrust(3) = 0.576d0*stage_initial_mass(3)*g_0 + 14.45d0

    do i=1, rocket%number_of_stages
        rocket%stage(i)%T = stage_thrust(i)  
        rocket%stage(i)%m_dot = rocket%stage(i)%T/(rocket%stage(i)%ISP*g_0)
        rocket%stage(i)%t_burn = rocket%stage(i)%m_p/rocket%stage(i)%m_dot
    end do

end subroutine stage_Thrust_calculator