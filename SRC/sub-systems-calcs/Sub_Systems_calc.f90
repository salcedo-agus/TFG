subroutine sub_systems_calculation(Rocket)
    use typical_data
    use rocket_types
    use constants
    implicit none
    type(Rocket_t), intent(inout) :: Rocket
    real(8), parameter :: t_start_up  = 1.d0      ! t_start_up fijo en 1 segundo
    real(8), parameter :: f_residual  = 0.0125d0  ! f_residual fijo en 1.25%
    real(8), parameter :: f_ullage    = 0.07d0    ! f_ullage fijo en 7%    
    real(8) E, dome_height, ds_Surface, section_radius
    integer i, tank_index

    call fuel_oxi_divider(Rocket)

    if (Rocket%rm_L < 1000.d0) then
        Rocket%rm_avionics = 75.d0
    else 
        Rocket%rm_avionics = 350.d0
    end if 

    do i=1, Rocket%number_of_stages !HARD-CODED DOME AR 
        Rocket%stage(i)%tank(1)%dome_AR = sqrt(2.d0)
        Rocket%stage(i)%tank(2)%dome_AR = sqrt(2.d0)
    end do

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

       Rocket%stage(i)%tank(1)%v_ullage = f_ullage * Rocket%stage(i)%tank(1)%v_liq
       Rocket%stage(i)%tank(2)%v_ullage = f_ullage * Rocket%stage(i)%tank(2)%v_liq
       Rocket%stage(i)%tank(1)%v_contraction = Rocket%stage(i)%tank(1)%k_contraction * Rocket%stage(i)%tank(1)%v_liq
       Rocket%stage(i)%tank(2)%v_contraction = Rocket%stage(i)%tank(2)%k_contraction * Rocket%stage(i)%tank(2)%v_liq

       Rocket%stage(i)%tank(1)%v_total = Rocket%stage(i)%tank(1)%v_liq + Rocket%stage(i)%tank(1)%v_ullage&
            + Rocket%stage(i)%tank(1)%v_contraction
       Rocket%stage(i)%tank(2)%v_total = Rocket%stage(i)%tank(2)%v_liq + Rocket%stage(i)%tank(2)%v_ullage&
            + Rocket%stage(i)%tank(2)%v_contraction 
    end do

    call calculate_toroidal_section_radii(Rocket)

    do i=1, Rocket%number_of_stages
       do tank_index = 1, 2
          if (Rocket%stage(i)%tank(tank_index)%v_total <= &
              Rocket%stage(i)%tank(tank_index)%Max_Toroidal_Volume) then
            print*, 'tanque toroidal'
              section_radius = Rocket%stage(i)%tank(tank_index)%Circular_section_radius
              Rocket%stage(i)%tank(tank_index)%spherical = .false.
              Rocket%stage(i)%tank(tank_index)%h_cyl = 2.d0 * section_radius
              Rocket%stage(i)%tank(tank_index)%Surface = 2.d0*pi**2.d0 * &
                  (Rocket%stage(i)%Diameter - 2.d0*section_radius)*section_radius
                Rocket%stage(i)%tank(tank_index)%Tank_Volume =  Rocket%stage(i)%tank(tank_index)%v_total
          else if (Rocket%stage(i)%tank(tank_index)%v_total < pi*Rocket%stage(i)%Diameter**3 &
              /(6.d0*Rocket%stage(i)%tank(tank_index)%dome_AR)) then
                print*, 'tanque esferico'
              ! Spherical Tank
              Rocket%stage(i)%tank(tank_index)%spherical = .true.
              Rocket%stage(i)%tank(tank_index)%h_cyl = 0.d0
              E = sqrt(1.d0 - 1.d0/Rocket%stage(i)%tank(tank_index)%dome_AR**2)
              ds_Surface = pi/4.d0*Rocket%stage(i)%Diameter**2*&
                  (1.d0+1.d0/(2*E*Rocket%stage(i)%tank(tank_index)%dome_AR**2)*log(1.d0+E/(1.d0-E)))
              Rocket%stage(i)%tank(tank_index)%Surface = ds_Surface
              Rocket%stage(i)%tank(tank_index)%Tank_Volume = pi*Rocket%stage(i)%Diameter**3.d0/6.d0
          else
              ! Cylindrical Tank
            print*, 'tanque cilindrico'
              Rocket%stage(i)%tank(tank_index)%spherical = .false.
              Rocket%stage(i)%tank(tank_index)%h_cyl = 4.d0/(pi*Rocket%stage(i)%Diameter**2)*&
                  (Rocket%stage(i)%tank(tank_index)%v_total - &
                  pi*Rocket%stage(i)%Diameter**3/(6.d0*Rocket%stage(i)%tank(tank_index)%dome_AR))
              E = sqrt(1.d0 - 1.d0/Rocket%stage(i)%tank(tank_index)%dome_AR**2)
              ds_Surface = pi/4.d0*Rocket%stage(i)%Diameter**2*&
                  (1.d0+1.d0/(2*E*Rocket%stage(i)%tank(tank_index)%dome_AR**2)*log(1.d0+E/(1.d0-E)))
              Rocket%stage(i)%tank(tank_index)%Surface = &
                  pi*Rocket%stage(i)%Diameter*Rocket%stage(i)%tank(tank_index)%h_cyl + ds_Surface
                Rocket%stage(i)%tank(tank_index)%Tank_Volume =  Rocket%stage(i)%tank(tank_index)%v_total
          end if
       end do

       if (i == Rocket%number_of_stages) then 
        Rocket%stage(i)%m_avionics = 0.8d0 * Rocket%rm_avionics
       else 
        Rocket%stage(i)%m_avionics = 0.2d0 * Rocket%rm_avionics / (Rocket%number_of_stages - 1.d0)
       end if

       Rocket%stage(i)%m_wiring = 1.43d0 * Rocket%stage(i)%Length
       
       !=========== unpr. structure mass ============
       dome_height = Rocket%stage(i)%Diameter /(2.d0 * Rocket%stage(i)%tank(1)%dome_AR)
       Rocket%stage(i)%Length=Rocket%stage(i)%tank(1)%h_cyl + Rocket%stage(i)%tank(2)%h_cyl + 4.d0*dome_height    
       Rocket%stage(i)%A_unpr_str = pi*Rocket%stage(i)%Diameter*Rocket%stage(i)%Length
       Rocket%stage(i)%m_unpr_str = 13.3d0 * Rocket%stage(i)%A_unpr_str
       !=============================================

       !======== tank shell mass ====================
       Rocket%stage(i)%tank(1)%m_shell = Rocket%stage(i)%tank(1)%k_shell*Rocket%stage(i)%tank(1)%Tank_Volume
       Rocket%stage(i)%tank(2)%m_shell = Rocket%stage(i)%tank(2)%k_shell*Rocket%stage(i)%tank(2)%Tank_Volume
       !=============================================

       !======== tank insulation mass ===============
       Rocket%stage(i)%tank(1)%m_insulation = Rocket%stage(i)%tank(1)%k_insulation * Rocket%stage(i)%tank(1)%Surface
       Rocket%stage(i)%tank(2)%m_insulation = Rocket%stage(i)%tank(2)%k_insulation * Rocket%stage(i)%tank(2)%Surface
       !=============================================

       Rocket%stage(i)%m_engines = 0.d0
       Rocket%stage(i)%m_thrust_structure = 0.d0
    end do

end subroutine sub_systems_calculation

subroutine calculate_toroidal_section_radii(Rocket)
    use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
    use rocket_types
    use constants, only: pi
    use Root_Finding_Methods, only: Newton_Raphson
    implicit none
    type(Rocket_t), intent(inout) :: Rocket
    real(8), parameter :: relative_tolerance = 1.d-10
    real(8) diameter, volume, max_volume, section_radius, tolerance, residual
    integer i, tank_index, iterations

    do i = 1, Rocket%number_of_stages
        diameter = Rocket%stage(i)%Diameter
        if (.not. ieee_is_finite(diameter) .or. diameter <= 0.d0) then
            error stop "Toroidal tank: stage diameter must be finite and positive"
        end if

        ! A ring torus requires r <= D/4, where its volume is maximal.
        max_volume = pi**2.d0 * diameter**3.d0 / 32.d0
        do tank_index = 1, 2
            volume = Rocket%stage(i)%tank(tank_index)%v_total
            if (.not. ieee_is_finite(volume) .or. volume < 0.d0) then
                error stop "Toroidal tank: volume must be finite and nonnegative"
            end if

            Rocket%stage(i)%tank(tank_index)%Max_Toroidal_Volume = max_volume
            if (volume == 0.d0) then
                Rocket%stage(i)%tank(tank_index)%Circular_section_radius = 0.d0
                cycle
            end if
            if (volume > max_volume) then
                Rocket%stage(i)%tank(tank_index)%Circular_section_radius = 0.d0
                cycle
            end if

            tolerance = relative_tolerance * max(1.d0, diameter)
            call Newton_Raphson(toroidal_volume_residual, Rocket, section_radius, iterations, tolerance, &
                0.d0, diameter/4.d0)
            residual = abs(toroidal_volume_residual(section_radius, Rocket))
            if (residual > relative_tolerance * max(1.d0, volume)) then
                error stop "Toroidal tank: secant method did not satisfy the volume equation"
            end if
            Rocket%stage(i)%tank(tank_index)%Circular_section_radius = section_radius
        end do
    end do
contains
    function toroidal_volume_residual(r, Rocket_context) result(value)
        use rocket_types, only: Rocket_t
        implicit none
        real(8), intent(in) :: r
        type(Rocket_t), intent(in) :: Rocket_context
        real(8) value

        value = pi**2.d0 * r**2.d0 * (Rocket_context%stage(i)%Diameter - 2.d0*r) &
            - Rocket_context%stage(i)%tank(tank_index)%v_total
    end function toroidal_volume_residual
end subroutine calculate_toroidal_section_radii

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
    real(8), dimension(2,3) :: tank_mass_ratio        ![kg/kg]   Tank mass per propelant mass
    real(8), dimension(2,3) :: insulation_mass_ratio  ![kg/m^2]  Insulation mass per tank surface area
    real(8), dimension(2,3) :: liquid_density         ![kg/m^3]
    real(8), dimension(2,3) :: tank_contraction_ratio ![m^3/m^3] Contraction produced due to low temperature 

    propellant_and_oxidizer_vector(1) = first_stage_propellant_and_oxidizer
    propellant_and_oxidizer_vector(2) = second_stage_propellant_and_oxidizer
    propellant_and_oxidizer_vector(3) = third_stage_propellant_and_oxidizer

    do i=1, 3
        select case(propellant_and_oxidizer_vector(i))
            case(1) ! 1 - LIQUID HIDROGEN / LIQUID OXIGEN (LH2/LOX)
                f_vector(i) = 4.96d0
                tank_mass_ratio(1,i) = 9.09d0
                tank_mass_ratio(2,i) = 12.16d0
                insulation_mass_ratio(1,i) = 2.88d0
                insulation_mass_ratio(2,i) = 1.123d0
                liquid_density(1,i) = 71.d0
                liquid_density(2,i) = 1140.d0
                tank_contraction_ratio(1,i) = 0.0192d0
                tank_contraction_ratio(2,i) = 0.0143d0
            case(2) ! 2 - LIQUID KEROSENE / LIQUID OXIGEN (RP1/LOX)
                f_vector(i) = 2.82d0
                tank_mass_ratio(1,i) = 12.16d0
                tank_mass_ratio(2,i) = 12.16d0
                insulation_mass_ratio(1,i) = 0.d0
                insulation_mass_ratio(2,i) = 0.123d0
                liquid_density(1,i) = 820.d0
                liquid_density(2,i) = 1140.d0
                tank_contraction_ratio(1,i) = 0.d0
                tank_contraction_ratio(2,i) = 0.0143d0
            case(3) ! 3 - LIQUID METHANE  / LIQUID OXIGEN (CH4/LOX)
                f_vector(i) = 0.d0
                tank_mass_ratio(1,i) = 0.d0
                tank_mass_ratio(2,i) = 0.d0
                insulation_mass_ratio(1,i) = 0.d0
                insulation_mass_ratio(2,i) = 0.d0
                liquid_density(1,i) = 0.d0
                liquid_density(2,i) = 0.d0
                tank_contraction_ratio(1,i) = 0.0128d0
                tank_contraction_ratio(2,i) = 0.0143d0
            case(4) ! 4 - UDMH/LOX
                f_vector(i) = 0.d0
                tank_mass_ratio(1,i) = 0.d0
                tank_mass_ratio(2,i) = 0.d0
                insulation_mass_ratio(1,i) = 0.d0
                insulation_mass_ratio(2,i) = 0.d0
                liquid_density(1,i) = 0.d0
                liquid_density(2,i) = 0.d0
                tank_contraction_ratio(1,i) = 0.d0
                tank_contraction_ratio(2,i) = 0.0143d0
            case(5) ! 5 - UDMH/AK271 
                f_vector(i) = 0.d0
                tank_mass_ratio(1,i) = 0.d0
                tank_mass_ratio(2,i) = 0.d0
                insulation_mass_ratio(1,i) = 0.d0
                insulation_mass_ratio(2,i) = 0.d0
                liquid_density(1,i) = 0.d0
                liquid_density(2,i) = 0.d0
                tank_contraction_ratio(1,i) = 0.d0
                tank_contraction_ratio(2,i) = 0.d0
            case(6) ! 6 - UDMH/N2O4
                f_vector(i) = 0.d0
                tank_mass_ratio(1,i) = 0.d0
                tank_mass_ratio(2,i) = 0.d0
                insulation_mass_ratio(1,i) = 0.d0
                insulation_mass_ratio(2,i) = 0.d0
                liquid_density(1,i) = 0.d0
                liquid_density(2,i) = 0.d0
                tank_contraction_ratio(1,i) = 0.d0
                tank_contraction_ratio(2,i) = 0.d0
            case(7) ! 7 - AEROZINE50/N2O4 
                f_vector(i) = 0.d0
                tank_mass_ratio(1,i) = 0.d0
                tank_mass_ratio(2,i) = 0.d0
                insulation_mass_ratio(1,i) = 0.d0
                insulation_mass_ratio(2,i) = 0.d0
                liquid_density(1,i) = 0.d0
                liquid_density(2,i) = 0.d0
                tank_contraction_ratio(1,i) = 0.d0
                tank_contraction_ratio(2,i) = 0.d0
            case(8) ! 8 - MH/NITRIC ACID(WFNA)
                f_vector(i) = 0.d0
                tank_mass_ratio(1,i) = 0.d0
                tank_mass_ratio(2,i) = 0.d0
                insulation_mass_ratio(1,i) = 0.d0
                insulation_mass_ratio(2,i) = 0.d0
                liquid_density(1,i) = 0.d0
                liquid_density(2,i) = 0.d0
                tank_contraction_ratio(1,i) = 0.d0
                tank_contraction_ratio(2,i) = 0.d0
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
        Rocket%stage(i)%tank(1)%k_contraction = tank_contraction_ratio(1,i)
        Rocket%stage(i)%tank(2)%k_contraction = tank_contraction_ratio(2,i)
    end do
end subroutine fuel_oxi_divider