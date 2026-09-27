subroutine sub_systems_calculation(Rocket)
    use typical_data
    use rocket_types
    use constants
    implicit none
    type(Rocket_t), intent(inout) :: Rocket
    integer i 

    call fuel_oxi_divider(Rocket)

    do i=1, Rocket%number_of_stages
        Rocket%stage(i)%m_p_start_up  = 1.d0 * Rocket%stage(i)%m_dot
        Rocket%stage(i)%m_p_aditional = 0.0125d0 * Rocket%stage(i)%m_p
        
        Rocket%stage(i)%m_p_total = Rocket%stage(i)%m_p_aditional + Rocket%stage(i)%m_p_start_up + Rocket%stage(i)%m_p
        
        

    end do

end subroutine sub_systems_calculation

subroutine fuel_oxi_divider(Rocket)
    use typical_data
    use rocket_types
    use constants
    implicit none
    type(Rocket_t), intent(inout) :: Rocket
    integer i
    real(8) f_first_stage
    real(8) f_second_stage
    real(8) f_third_stage
    real(8), dimension(3) :: f_vector

    select case(first_stage_propellant_and_oxidizer)
    case(1) ! 1 - LIQUID HIDROGEN / LIQUID OXIGEN (LH2/LOX)
        f_first_stage = 0.d0
    case(2) ! 2 - LIQUID KEROSENE / LIQUID OXIGEN (RP1/LOX)
        f_first_stage = 0.d0
    case(3) ! 3 - LIQUID METHANE  / LIQUID OXIGNE (CH4/LOX)
        f_first_stage = 0.d0
    case(4) ! 4 - UDMH/LOX
        f_first_stage = 0.d0
    case(5) ! 5 - UDMH/AK271 
        f_first_stage = 0.d0
    case(6) ! 6 - UDMH/N2O4
        f_first_stage = 0.d0
    case(7) ! 7 - AEROZINE50/N2O4 
        f_first_stage = 0.d0
    case(8) ! 8 - MH/NITRIC ACID(WFNA)
        f_first_stage = 0.d0
    end select 

    select case(first_stage_propellant_and_oxidizer)
    case(1) ! 1 - LIQUID HIDROGEN / LIQUID OXIGEN (LH2/LOX)
        f_second_stage = 0.d0
    case(2) ! 2 - LIQUID KEROSENE / LIQUID OXIGEN (RP1/LOX)
        f_second_stage = 0.d0
    case(3) ! 3 - LIQUID METHANE  / LIQUID OXIGNE (CH4/LOX)
        f_second_stage = 0.d0
    case(4) ! 4 - UDMH/LOX
        f_second_stage = 0.d0
    case(5) ! 5 - UDMH/AK271 
        f_second_stage = 0.d0
    case(6) ! 6 - UDMH/N2O4
        f_second_stage = 0.d0
    case(7) ! 7 - AEROZINE50/N2O4
        f_second_stage = 0.d0
    case(8) ! 8 - MH/NITRIC ACID(WFNA)
        f_second_stage = 0.d0
    end select 

    select case(first_stage_propellant_and_oxidizer)
    case(1) ! 1 - LIQUID HIDROGEN / LIQUID OXIGEN (LH2/LOX)
        f_third_stage = 0.d0
    case(2) ! 2 - LIQUID KEROSENE / LIQUID OXIGEN (RP1/LOX)
        f_third_stage = 0.d0
    case(3) ! 3 - LIQUID METHANE  / LIQUID OXIGNE (CH4/LOX)
        f_third_stage = 0.d0
    case(4) ! 4 - UDMH/LOX
        f_third_stage = 0.d0
    case(5) ! 5 - UDMH/AK271 
        f_third_stage = 0.d0
    case(6) ! 6 - UDMH/N2O4
        f_third_stage = 0.d0
    case(7) ! 7 - AEROZINE50/N2O4
        f_third_stage = 0.d0
    case(8) ! 8 - MH/NITRIC ACID(WFNA)
        f_third_stage = 0.d0
    end select 

    do i=1, Rocket%number_of_stages
        Rocket%stage(i)%f_fuel_oxi = f_vector(i)
    end do
end subroutine fuel_oxi_divider