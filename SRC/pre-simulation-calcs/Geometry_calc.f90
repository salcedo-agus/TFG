subroutine rocket_geometry_calculation(Rocket)
    use typical_data
    use rocket_types
    use constants
    implicit none
    type(Rocket_t) Rocket
    real(8), dimension(3) :: Longitud_vector !These vectors always store the values of V, L and D
    real(8), dimension(3) :: Diameter_vector
    real(8), dimension(3) :: Volume_vector 
    
    select case (first_stage_propellant_and_oxidizer)
    case(1) ! 1 - LIQUID HIDROGEN / LIQUID OXIGEN (LH2/LOX)    
        Volume_vector(1) = -0.0018d0 * 
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
    case(2) ! 2 - LIQUID KEROSENE / LIQUID OXIGEN (RP1/LOX)
    case(3) ! 3 - LIQUID METHANE  / LIQUID OXIGNE (CH4/LOX)
    case(4) ! 4 - UDMH/LOX
    case(5) ! 5 - UDMH/AK271
    case(6) ! 6 - UDMH/N2O4
    case(7) ! 7 - AEROZINE50/N2O4
    case(8) ! 8 - MH/NITRIC ACID(WFNA)
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