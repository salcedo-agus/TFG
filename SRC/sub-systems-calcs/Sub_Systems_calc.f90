<<<<<<< HEAD
subroutine sub_systems_calculation(Rocket)
    use typical_data
    use rocket_types
    use constants
    implicit none
    type(Rocket_t), intent(inout) :: Rocket
    real(8), parameter :: t_start_up = 1.d0     !t_start_up fijo en 1 segundo
    real(8), parameter :: f_residual = 0.0125d0     !f_residual fijo en 1.25%
    integer i 

    call fuel_oxi_divider(Rocket)

    do i=1, Rocket%number_of_stages
        Rocket%stage(i)%m_p_start_up = rocket%stage(i)%m_dot * t_start_up
        Rocket%stage(i)%m_p_aditional = (rocket%stage(i)%m_p + rocket%stage(i)%m_p_start_up) * f_residual   !tengo en cuenta para la m_p_aditional tanto la masa de propulsion como la de startup
        
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
=======
subroutine m_p_total_calc(Rocket)
    use rocket_types
    use typical_data
    implicit none
    type(Rocket_t), intent(inout) :: Rocket
    real(8), parameter :: t_start_up = 1.d0     !t_start_up fijo en 1 segundo
    real(8), parameter :: f_residual = 0.0125d0     !f_residual fijo en 1.25%
    integer i

!==================== m_p_total calculation according to section 4 ===============================    
    do i=1, number_of_stages
        rocket%stage(i)%m_p_start_up = rocket%stage(i)%m_dot * t_start_up
        rocket%stage(i)%m_p_aditional = (rocket%stage(i)%m_p + rocket%stage(i)%m_p_start_up) * f_residual   !tengo en cuenta para la m_p_aditional tanto la masa de propulsion como la de startup
        rocket%stage(i)%m_p_total = rocket%stage(i)%m_p_start_up + rocket%stage(i)%m_p_aditional
    end do

end subroutine m_p_total_calc



!subroutine MERS_Calc
 !   use rocket_types
  !  use typical_data
   ! implicit none
    !type(Rocket_t), intent(inout) :: Rocket

!    rocket%stage(i)%m_unpr_str =

 !   do i=1, number_of_stages
         
  !  end do
!end subroutine MERS_Calc
>>>>>>> dca9d91ba87c3352c1a7554087842ad28364f070
