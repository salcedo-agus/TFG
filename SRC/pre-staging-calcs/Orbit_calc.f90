subroutine orbit_speed_calculator
    !IN:  Orbit height 
    !OUT: Delta_v necessary
    use typical_data
    use constants
    implicit none
    real(8) r  ! Circular orbit radius

    r = Radius + orbit_height
    V_circ = sqrt(g_0*Radius**2.d0 / (r * 1000.d0))
end subroutine orbit_speed_calculator