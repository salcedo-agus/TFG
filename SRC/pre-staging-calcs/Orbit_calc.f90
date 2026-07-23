subroutine orbit_speed_calculator
    !IN:  Orbit height 
    !OUT: Delta_v necessary
    use typical_data
    use constants
    implicit none
    real(8) r  ! Circular orbit radius

    r = Radius + orbit_height
    V_circ = sqrt(g_0*Radius**2 / r)
end subroutine orbit_speed_calculator