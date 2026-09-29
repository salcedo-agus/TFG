subroutine sub_systems_calculation(Rocket)
    use typical_data
    use rocket_types
    use constants
    implicit none
    type(Rocket_t), intent(inout) :: Rocket
    real(8), parameter :: t_start_up = 1.d0         !t_start_up fijo en 1 segundo
    real(8), parameter :: f_residual = 0.0125d0     !f_residual fijo en 1.25%
    real(8) E 
    integer i 

    call fuel_oxi_divider(Rocket)

    if (Rocket%rm_L < 1000.d0) then
        Rocket%rm_avionics = 75.d0
    else 
        Rocket%rm_avionics = 350.d0
    end if 

    do i=1, Rocket%number_of_stages
        Rocket%stage(i)%m_p_start_up = rocket%stage(i)%m_dot * t_start_up
        Rocket%stage(i)%m_p_aditional = (rocket%stage(i)%m_p + rocket%stage(i)%m_p_start_up) * f_residual   !tengo en cuenta para la m_p_aditional tanto la masa de propulsion como la de startup
        
        Rocket%stage(i)%m_p_total = Rocket%stage(i)%m_p_aditional + Rocket%stage(i)%m_p_start_up&
            + Rocket%stage(i)%m_p
        
        Rocket%stage(i)%tank(1)%m_liq = Rocket%stage(i)%f_fuel_oxi/(1.d0 + Rocket%stage(i)%f_fuel_oxi)&
            *Rocket%stage(i)%m_p_total 
        Rocket%stage(i)%tank(2)%m_liq = 1.d0/(1.d0 + Rocket%stage(i)%f_fuel_oxi)&
            *Rocket%stage(i)%m_p_total

        Rocket%stage(i)%tank(1)%v_liq = Rocket%stage(i)%tank(1)%m_liq / Rocket%stage(i)%tank(1)%rho_liq
        Rocket%stage(i)%tank(2)%v_liq = Rocket%stage(i)%tank(2)%m_liq / Rocket%stage(i)%tank(2)%rho_liq

       Rocket%stage(i)%tank(1)%v_ullage = 0.d0
       Rocket%stage(i)%tank(2)%v_ullage = 0.d0
       Rocket%stage(i)%tank(1)%v_contraction = 0.d0 
       Rocket%stage(i)%tank(2)%v_contraction = 0.d0

       Rocket%stage(i)%tank(1)%v_total = Rocket%stage(i)%tank(1)%v_liq + Rocket%stage(i)%tank(1)%v_ullage&
            + Rocket%stage(i)%tank(1)%v_contraction
       Rocket%stage(i)%tank(2)%v_total = Rocket%stage(i)%tank(2)%v_liq + Rocket%stage(i)%tank(2)%v_ullage&
            + Rocket%stage(i)%tank(2)%v_contraction 
       
       if (Rocket%stage(i)%tank(1)%v_total < pi*Rocket%stage(i)%Diameter**3 &
            /(6.d0*Rocket%stage(i)%tank(1)%dome_AR)) then
          ! Spherical Tank 
            Rocket%stage(i)%tank(1)%h_cyl = 0.d0  
            E = sqrt(1.d0 - 1.d0/Rocket%stage(i)%tank(1)%dome_AR**2)
            Rocket%stage(i)%tank(1)%Surface = pi/4.d0*Rocket%stage(i)%Diameter**2*&
                (1.d0+1.d0/(2*E*Rocket%stage(i)%tank(1)%dome_AR**2)*log(1.d0+E/(1.d0-E)))
       else
          ! Cylindrical Tank
            Rocket%stage(i)%tank(1)%h_cyl = 4.d0/(pi*Rocket%stage(i)%Diameter**2)*&
                (Rocket%stage(i)%tank(1)%v_total - pi*Rocket%stage(i)%Diameter**3/(6.d0*Rocket%stage(i)%tank(1)%dome_AR))
            Rocket%stage(i)%tank(1)%Surface = pi*Rocket%stage(i)%Diameter*Rocket%stage(i)%tank(1)%h_cyl  
       end if
       Rocket%stage(i)%tank(1)%m_unpr_str = 13.3d0 * Rocket%stage(i)%tank(1)%Surface
       Rocket%stage(i)%tank(2)%m_unpr_str = 13.3d0 * Rocket%stage(i)%tank(2)%Surface
       
       if (i == Rocket%number_of_stages) then 
        Rocket%stage(i)%m_avionics = 0.8d0 * Rocket%rm_avionics
       else 
        Rocket%stage(i)%m_avionics = 0.2d0 * Rocket%rm_avionics / (Rocket%number_of_stages - 1.d0)
       end if

       Rocket%stage(i)%m_wiring = 1.43d0 * Rocket%stage(i)%Length
        !AGREGAR MERS
    end do

end subroutine sub_systems_calculation

subroutine fuel_oxi_divider(Rocket)
    use typical_data
    use rocket_types
    use constants
    implicit none
    type(Rocket_t), intent(inout) :: Rocket
    integer i
    integer, dimension(3) :: propellant_and_oxidizer_vector 
    real(8), dimension(3) :: f_vector                ! fuel/oxidizer mixture ratio
    ! In the following variables : tank_mass_ratio(1,*) = for fuel tank | tank_mass_ratio(2,*) = for oxidizer tank
    !                              The second index indicates stage
    real(8), dimension(2,3) :: tank_mass_ratio       ![kg/kg] Tank mass per propelant mass
    real(8), dimension(2,3) :: insulation_mass_ratio ![kg/m^2] Insulation mass per tank surface area
    real(8), dimension(2,3) :: liquid_density        ![kg/m^3]

    do i=1, 3
        select case(propellant_and_oxidizer_vector(i))
            case(1) ! 1 - LIQUID HIDROGEN / LIQUID OXIGEN (LH2/LOX)
                f_vector(i) = 4.96d0
                tank_mass_ratio(1,i) = 0.128d0
                tank_mass_ratio(2,i) = 0.0107d0
                insulation_mass_ratio(1,i) = 2.88d0
                insulation_mass_ratio(2,i) = 1.123d0
                liquid_density(1,i) = 71.d0
                liquid_density(2,i) = 1140.d0
            case(2) ! 2 - LIQUID KEROSENE / LIQUID OXIGEN (RP1/LOX)
                f_vector(i) = 2.82d0
                tank_mass_ratio(1,i) = 0.0148d0
                tank_mass_ratio(2,i) = 0.0107d0
                insulation_mass_ratio(1,i) = 0.d0
                insulation_mass_ratio(2,i) = 0.123d0
                liquid_density(1,i) = 820.d0
                liquid_density(2,i) = 1140.d0
            case(3) ! 3 - LIQUID METHANE  / LIQUID OXIGEN (CH4/LOX)
                f_vector(i) = 0.d0
                tank_mass_ratio(1,i) = 0.d0
                tank_mass_ratio(2,i) = 0.d0
                insulation_mass_ratio(1,i) = 0.d0
                insulation_mass_ratio(2,i) = 0.d0
                liquid_density(1,i) = 0.d0
                liquid_density(2,i) = 0.d0
            case(4) ! 4 - UDMH/LOX
                f_vector(i) = 0.d0
                tank_mass_ratio(1,i) = 0.d0
                tank_mass_ratio(2,i) = 0.d0
                insulation_mass_ratio(1,i) = 0.d0
                insulation_mass_ratio(2,i) = 0.d0
                liquid_density(1,i) = 0.d0
                liquid_density(2,i) = 0.d0
            case(5) ! 5 - UDMH/AK271 
                f_vector(i) = 0.d0
                tank_mass_ratio(1,i) = 0.d0
                tank_mass_ratio(2,i) = 0.d0
                insulation_mass_ratio(1,i) = 0.d0
                insulation_mass_ratio(2,i) = 0.d0
                liquid_density(1,i) = 0.d0
                liquid_density(2,i) = 0.d0
            case(6) ! 6 - UDMH/N2O4
                f_vector(i) = 0.d0
                tank_mass_ratio(1,i) = 0.d0
                tank_mass_ratio(2,i) = 0.d0
                insulation_mass_ratio(1,i) = 0.d0
                insulation_mass_ratio(2,i) = 0.d0
                liquid_density(1,i) = 0.d0
                liquid_density(2,i) = 0.d0
            case(7) ! 7 - AEROZINE50/N2O4 
                f_vector(i) = 0.d0
                tank_mass_ratio(1,i) = 0.d0
                tank_mass_ratio(2,i) = 0.d0
                insulation_mass_ratio(1,i) = 0.d0
                insulation_mass_ratio(2,i) = 0.d0
                liquid_density(1,i) = 0.d0
                liquid_density(2,i) = 0.d0
            case(8) ! 8 - MH/NITRIC ACID(WFNA)
                f_vector(i) = 0.d0
                tank_mass_ratio(1,i) = 0.d0
                tank_mass_ratio(2,i) = 0.d0
                insulation_mass_ratio(1,i) = 0.d0
                insulation_mass_ratio(2,i) = 0.d0
                liquid_density(1,i) = 0.d0
                liquid_density(2,i) = 0.d0
        end select 
    end do

    do i=1, Rocket%number_of_stages
        Rocket%stage(i)%f_fuel_oxi = f_vector(i)
        Rocket%stage(i)%tank(1)%k_shell = tank_mass_ratio(1,i)
        Rocket%stage(i)%tank(2)%k_shell = tank_mass_ratio(2,i)
        Rocket%stage(i)%tank(1)%k_insulation = insulation_mass_ratio(1,i)
        Rocket%stage(i)%tank(2)%k_insulation = insulation_mass_ratio(2,i)
        Rocket%stage(i)%tank(1)%rho_liq = liquid_density(1,i) 
        Rocket%stage(i)%tank(2)%rho_liq = liquid_density(2,i) 
    end do
end subroutine fuel_oxi_divider