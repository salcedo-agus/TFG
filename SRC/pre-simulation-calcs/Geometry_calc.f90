subroutine rocket_geometry_calculation(Rocket)
    use typical_data
    use rocket_types
    use constants
    implicit none
    type(Rocket_t) Rocket
    real(8), dimension(3) :: Longitud_vector !These vectors always store the values of V, L and D
    real(8), dimension(3) :: Diameter_vector
    real(8), dimension(3) :: Volume_vector 
    real(8), dimension(3) :: Mass_vector 
    integer i 
    real(8) check_diameter

    Mass_vector(:) = 0.d0
    do i=1, rocket%number_of_stages
        Mass_vector(i) = rocket%stage(i)%m_i / 1000.d0 ! Mass_vector in metric tons [t]
    end do 

    select case (first_stage_propellant_and_oxidizer)
    case(1) ! 1 - LIQUID HIDROGEN / LIQUID OXIGEN (LH2/LOX)    
        Diameter_vector(1) = 1.8548d0 * log(Mass_vector(1)) - 4.5511d0
        Volume_vector(1) = -0.0018d0 * Mass_vector(1)**2.d0 + 5.3556 * Mass_vector(1) - 201.43d0
    case(2) ! 2 - LIQUID KEROSENE / LIQUID OXIGEN (RP1/LOX)
        Diameter_vector(1) = 3e-5 * Mass_vector(1)**2.d0 - 0.0034d0 * Mass_vector(1) + 2.5802d0
        Volume_vector(1) = 0.0076d0 * Mass_vector(1)**2.d0 - 1.7119d0 * Mass_vector(1) + 230.43d0
    case(3) ! 3 - LIQUID METHANE  / LIQUID OXIGNE (CH4/LOX)
        print*, "WARNING: without statistical data on the geometry"
    case(4) ! 4 - UDMH/LOX
        print*, "WARNING: without statistical data on the geometry"
    case(5) ! 5 - UDMH/AK271
        print*, "WARNING: without statistical data on the geometry"
    case(6) ! 6 - UDMH/N2O4
        Diameter_vector(1) = -2e-5 * Mass_vector(1)**2.d0 + 0.0132d0 * Mass_vector(1) + 1.5097d0
        Volume_vector(1) = -0.0032 * Mass_vector(1)**2.d0 + 2.2922d0 * Mass_vector(1) - 101.3d0
    case(7) ! 7 - AEROZINE50/N2O4
        Diameter_vector(1) = 3.05d0
        Volume_vector(1) = 0.8946d0 * Mass_vector(1) + 47.955d0
    case(8) ! 8 - MH/NITRIC ACID(WFNA)
        print*, "WARNING: without statistical data on the geometry"
    case default
        print*, "WARNING: unknown first stage propellant and oxidizer"
    end select

    select case (Second_stage_propellant_and_oxidizer)
    case(1) ! 1 - LIQUID HIDROGEN / LIQUID OXIGEN (LH2/LOX)  
        Volume_vector(2) = 0.012d0 * Mass_vector(2)**2 + 4.6267d0 * Mass_vector(2) - 6.6395d0
        Diameter_vector(2) = -0.0002d0 * Mass_vector(2)**2 + 0.0587d0 * Mass_vector(2) + 2.4729d0 
    case(2) ! 2 - LIQUID KEROSENE / LIQUID OXIGEN (RP1/LOX)
        Volume_vector(2) = 0.8135d0*Mass_vector(2)**2 - 51.16d0*Mass_vector(2) + 818.2d0
        Diameter_vector(2) = 0.0654d0*Mass_vector(2) + 0.9993d0
    case(3) ! 3 - LIQUID METHANE  / LIQUID OXIGNE (CH4/LOX)
        !COMPLETAR
    case(4) ! 4 - UDMH/LOX
        print*, "WARNING: without statistical data on the geometry"
    case(5) ! 5 - UDMH/AK271
        print*, "WARNING: without statistical data on the geometry"
    case(6) ! 6 - UDMH/N2O4
        Volume_vector(2) = -0.0019d0*Mass_vector(2)**2 + 1.7462d0*Mass_vector(2) - 7.4837d0
        Diameter_vector(2) = -0.0001d0*Mass_vector(2)**2 + 0.0297d0*Mass_vector(2) + 2.0639d0
    case(7) ! 7 - AEROZINE50/N2O4
        Volume_vector(2) = 0.0511d0*Mass_vector(2)**2 - 1.2408d0*Mass_vector(2) + 34.109d0
        Diameter_vector(2) = -0.0008d0*Mass_vector(2)**2 + 0.0579d0*Mass_vector(2) + 2.0779d0
    case(8) ! 8 - MH/NITRIC ACID(WFNA)
        print*, "WARNING: without statistical data on the geometry"
    case default
        print*, "WARNING: unknown Second stage propellant and oxidizer"
    end select

    select case (Third_stage_propellant_and_oxidizer)
    case(1) ! 1 - LIQUID HIDROGEN / LIQUID OXIGEN (LH2/LOX) 
        Diameter_vector(3) = 0.0139d0 * Mass_vector(3)**2.d0 - 0.3527d0 * Mass_vector(3) + 4.8378d0
        Volume_vector(3) = 0.263d0 * Mass_vector(3)**2.d0 - 2.4828d0 * Mass_vector(3) + 47.045d0
    case(2) ! 2 - LIQUID KEROSENE / LIQUID OXIGEN (RP1/LOX)
        print*, "WARNING: without statistical data on the geometry"
    case(3) ! 3 - LIQUID METHANE  / LIQUID OXIGNE (CH4/LOX)
        print*, "WARNING: without statistical data on the geometry"
    case(4) ! 4 - UDMH/LOX
        print*, "WARNING: without statistical data on the geometry"
    case(5) ! 5 - UDMH/AK271
        print*, "WARNING: without statistical data on the geometry"
    case(6) ! 6 - UDMH/N2O4
        Diameter_vector(3) = 0.7393d0 * log(Mass_vector(3)) + 1.2459d0
        Volume_vector(3) = -0.0089 * Mass_vector(3)**2.d0 + 1.4289 * Mass_vector(3) + 6.1252d0
    case(7) ! 7 - AEROZINE50/N2O4
        print*, "WARNING: without statistical data on the geometry"
    case(8) ! 8 - MH/NITRIC ACID(WFNA)
        print*, "WARNING: without statistical data on the geometry"
    case default
        print*, "WARNING: unknown Third stage propellant and oxidizer"
    end select 

    select case (Diameter_setup)
    case(1) ! 1 - Statistically determined
        if (number_of_stages > 1) then
            do i=1,number_of_stages-1
                check_diameter = Diameter_vector(i+1) - Diameter_vector(i)
                if (check_diameter > 0.d0) Diameter_vector(i) = Diameter_vector(i+1)
            end do
        end if
    case(2) ! 2 - Constant 
        Diameter_vector = maxval(Diameter_vector)
    case(3) ! 3 - Fairing requirement   
        Diameter_vector = User_defined_diameter
    end select
    Longitud_vector = Volume_vector * 4.d0 / (pi * Diameter_vector**2.d0)
end subroutine rocket_geometry_calculation