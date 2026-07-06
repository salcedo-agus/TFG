subroutine Payload_Mass_calculator(Rocket)
    !IN:   Necesary satelite mass 
    !OUT:  Effective payload mass of the rocket (including fairing, connectors) 
    use typical_data
    use rocket_types
    use constants
    implicit none
    type(Rocket_t) Rocket
    real(8) m_adapter    ! Mass of the PAF

    !===== PAF mass is aproximated using eq. 11 ==========================
        m_adapter = 0.0755d0 * payload_mass + 50
    !=====================================================================

    !===== Fairing considerations ========================================
        
    !=====================================================================
end subroutine