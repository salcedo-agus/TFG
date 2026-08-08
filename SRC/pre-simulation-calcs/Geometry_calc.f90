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

    Mass_vector(:) = 0.d0
    do i=1, rocket%number_of_stages
        Mass_vector(i) = rocket%stage(i)%m_i
    end do 

    select case (first_stage_propellant_and_oxidizer)
    case(1) ! 1 - LIQUID HIDROGEN / LIQUID OXIGEN (LH2/LOX)    
       ! Volume_vector(1) = -0.0018d0 * 
    case(2) ! 2 - LIQUID KEROSENE / LIQUID OXIGEN (RP1/LOX)
    case(3) ! 3 - LIQUID METHANE  / LIQUID OXIGNE (CH4/LOX)
    case(4) ! 4 - UDMH/LOX
    case(5) ! 5 - UDMH/AK271
    case(6) ! 6 - UDMH/N2O4
    case(7) ! 7 - AEROZINE50/N2O4
    case(8) ! 8 - MH/NITRIC ACID(WFNA)
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
        print*, "WARNING este no es valido"
    case(5) ! 5 - UDMH/AK271
        print*, "WARNING este no es valido"
    case(6) ! 6 - UDMH/N2O4
        Volume_vector(2) = -0.0019d0*Mass_vector(2)**2 + 1.7462d0*Mass_vector(2) - 7.4837d0
        Diameter_vector(2) = -0.0001d0*Mass_vector(2)**2 + 0.0297d0*Mass_vector(2) + 2.0639d0
    case(7) ! 7 - AEROZINE50/N2O4
        Volume_vector(2) = 0.0511d0*Mass_vector(2)**2 - 1.2408d0*Mass_vector(2) + 34.109d0
        Diameter_vector(2) = -0.0008d0*Mass_vector(2)**2 + 0.0579d0*Mass_vector(2) + 2.0779d0
    case(8) ! 8 - MH/NITRIC ACID(WFNA)
        print*, "WARNING este no es valido"
    case default
        print*, "WARNING: unknown Second stage propellant and oxidizer"
    end select

    select case (Third_stage_propellant_and_oxidizer)
    case(1) ! 1 - LIQUID HIDROGEN / LIQUID OXIGEN (LH2/LOX)    
    case(2) ! 2 - LIQUID KEROSENE / LIQUID OXIGEN (RP1/LOX)
    case(3) ! 3 - LIQUID METHANE  / LIQUID OXIGNE (CH4/LOX)
    case(4) ! 4 - UDMH/LOX
    case(5) ! 5 - UDMH/AK271
    case(6) ! 6 - UDMH/N2O4
    case(7) ! 7 - AEROZINE50/N2O4
    case(8) ! 8 - MH/NITRIC ACID(WFNA)
    case default
        print*, "WARNING: unknown Third stage propellant and oxidizer"
    end select 

end subroutine rocket_geometry_calculation