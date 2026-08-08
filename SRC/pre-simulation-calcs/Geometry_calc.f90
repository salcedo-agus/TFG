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
        Diameter_vector(1) = 1.8548d0 * log(Rocket%stage(1)%m_i) - 4.5511d0
        Volume_vector(1) = -0.0018d0 * Rocket%stage(1)%m_i**2.d0 + 5.3556 * Rocket%stage(1)%m_i - 201.43d0
    case(2) ! 2 - LIQUID KEROSENE / LIQUID OXIGEN (RP1/LOX)
        Diameter_vector(1) = 3e-5 * Rocket%stage(1)%m_i**2.d0 - 0.0034d0 * Rocket%stage(1)%m_i + 2.5802d0
        Volume_vector(1) = 0.0076d0 * Rocket%stage(1)%m_i**2.d0 - 1.7119d0 * Rocket%stage(1)%m_i + 230.43d0
    case(3) ! 3 - LIQUID METHANE  / LIQUID OXIGNE (CH4/LOX)
        print*, "WARNING: without statistical data on the geometry"
    case(4) ! 4 - UDMH/LOX
        print*, "WARNING: without statistical data on the geometry"
    case(5) ! 5 - UDMH/AK271
        print*, "WARNING: without statistical data on the geometry"
    case(6) ! 6 - UDMH/N2O4
        Diameter_vector(1) = -2e-5 * Rocket%stage(1)%m_i**2.d0 + 0.0132d0 * Rocket%stage(1)%m_i + 1.5097d0
        Volume_vector(1) = -0.0032 * Rocket%stage(1)%m_i**2.d0 + 2.2922d0 * Rocket%stage(1)%m_i - 101.3d0
    case(7) ! 7 - AEROZINE50/N2O4
        Diameter_vector(1) = 3.05d0
        Volume_vector(1) = 0.8946d0 * Rocket%stage(1)%m_i + 47.955d0
    case(8) ! 8 - MH/NITRIC ACID(WFNA)
        print*, "WARNING: without statistical data on the geometry"
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
        Diameter_vector(3) = 0.0139d0 * Rocket%stage(3)%m_i**2.d0 - 0.3527d0 * Rocket%stage(3)%m_i + 4.8378d0
        Volume_vector(3) = 0.263d0 * Rocket%stage(3)%m_i**2.d0 - 2.4828d0 * Rocket%stage(3)%m_i + 47.045d0
    case(2) ! 2 - LIQUID KEROSENE / LIQUID OXIGEN (RP1/LOX)
        print*, "WARNING: without statistical data on the geometry"
    case(3) ! 3 - LIQUID METHANE  / LIQUID OXIGNE (CH4/LOX)
        print*, "WARNING: without statistical data on the geometry"
    case(4) ! 4 - UDMH/LOX
        print*, "WARNING: without statistical data on the geometry"
    case(5) ! 5 - UDMH/AK271
        print*, "WARNING: without statistical data on the geometry"
    case(6) ! 6 - UDMH/N2O4
        Diameter_vector(3) = 0.7393d0 * log(Rocket%stage(3)%m_i) + 1.2459d0
        Volume_vector(3) = -0.0089 * Rocket%stage(3)%m_i**2.d0 + 1.4289 * Rocket%stage(3)%m_i + 6.1252d0
    case(7) ! 7 - AEROZINE50/N2O4
        print*, "WARNING: without statistical data on the geometry"
    case(8) ! 8 - MH/NITRIC ACID(WFNA)
        print*, "WARNING: without statistical data on the geometry"
    case default
        print*, "WARNING: unknown Third stage propellant and oxidizer"
    end select 

    Longitud_vector = Volume_vector * 4.d0 / (pi * Diameter_vector**2.d0)

end subroutine rocket_geometry_calculation